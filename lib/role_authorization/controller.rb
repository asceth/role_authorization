module RoleAuthorization
  module Controller
    def self.included(base)
      base.class_eval do
        helper_method :authorized?
        helper_method :accessible?

        before_filter :check_request_authorization
      end
      base.send :extend, RoleAuthorization::Ruleset::ClassMethods
      base.send :cattr_ruleset, :ruleset, :allowable_groups

      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def allow_group(*args)
        add_to_allowable_groups(self.controller_rule_name, args)
      end

      def allow(options = {}, &block)
        add_to_ruleset(self.controller_rule_name, &block)
      end

      def controller_rule_name
        @controller_rule_name ||= name.gsub('Controller', '').underscore.downcase
      end

      def controller_model
        @controller_model ||= name.gsub('Controller', '').singularize
      end
    end # ClassMethods

    module InstanceMethods
      def check_request_authorization
        params[:role_authorization_user_data] = nil
        unless authorized_action?(self, self.class.controller_rule_name, action_name.to_sym, params[:id])
          raise SecurityError, "You do not have the required clearance to access this resource."
        end
      end

      def authorized_action?(controller_klass, controller, action, id = nil)
        # by default admins see everything
        return true if current_user && current_user.admin?

        ruleset = self.class.ruleset[controller]
        groups = RoleAuthorization::AllowGroup.get(self.class.allowable_groups[controller])

        if defined?(::DEBUG_AUTHORIZATION_RULES) == 'constant'
          Rails.logger.info "#" * 30
          Rails.logger.info controller.to_s
          Rails.logger.info ruleset.to_s
          Rails.logger.info "#" * 30
        end

        # we have no ruleset for this controller or any allow groups so deny
        return false if ruleset.nil? && groups.empty?

        # first check controller ruleset
        unless ruleset.nil?
          return true if ruleset.authorized?(controller_klass, controller, :all, id)
          return true if ruleset.authorized?(controller_klass, controller, action, id)
        end

        # next check any allow groups
        unless groups.empty?
          groups.each do |group|
            return true if group.authorized?(controller_klass, controller, :all, id)
            return true if group.authorized?(controller_klass, controller, action, id)
          end
        end

        # finally deny if they haven't passed any rules
        return false
      end

      def authorized?(url, method = nil)
        return false unless url
        return true if current_user && current_user.admin?

        unless url.is_a?(Hash)
          method ||= (params[:method] || request.method)
          url_parts = URI::split(url.strip)
          path = url_parts[5]
        end

        begin
          hash = if url.is_a?(Hash)
                   url
                 else
                   Rails.application.routes.recognize_path(path, :method => method)
                 end

          if hash
            klass = (hash[:controller].camelize + "Controller").constantize.new
            klass.params = hash
            klass.instance_variable_set(:@current_user, current_user)

            return authorized_action?(klass, hash[:controller], hash[:action].to_sym, hash[:id])
          end
        rescue Exception => e
          Rails.logger.error e.inspect
          Rails.logger.error "when trying to #{method} #{path}"
          e.backtrace.each {|line| Rails.logger.error line }
          # continue on
        end

        unless url.is_a?(Hash)
          # Mailto link
          return true if url =~ /^mailto:/

          # Public file
          file = File.join(Rails.root, 'public', url)
          return true if File.exists?(file)

          # Passing in different domain
          return remote_url?(url_parts[2])
        end
      end

      def remote_url?(domain = nil)
        return false if domain.nil? || domain.strip.length == 0
        request.host.downcase != domain.downcase
      end
    end # InstanceMethods
  end
end
