module RoleAuthorization
  module Exts
    module Controller
      def self.included(base)
        base.class_eval do
          helper_method :authorized?
          helper_method :accessible?
        end
        base.send :extend, RoleAuthorization::Ruleset::ClassMethods
        base.send :cattr_ruleset, :ruleset, :allowable_groups
        base.send :extend, ClassMethods

        base.send :include, InstanceMethods
      end

      module ClassMethods
        def allow_group(*args)
          add_to_allowable_groups(self.controller_rule_name, args)
          add_role_authorization_filter
        end

        def allow(&block)
          add_to_ruleset(self.controller_rule_name, &block)
          add_role_authorization_filter
        end

        def add_role_authorization_filter
          callbacks = _process_action_callbacks
          chain = callbacks.select {|cl| cl.klass.to_s.include?(name)}.collect(&:filter).select {|c| c.is_a?(Symbol)}
          before_filter :check_request_authorization unless chain.include?(:check_request_authorization)
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
          unless authorized_action?(self, self.class.controller_rule_name, action_name.to_sym, params[:id])
            raise SecurityError, "You do not have the required clearance to access this resource."
          end
        end

        def authorized_action?(controller_klass, controller, action, id = nil)
          # by default admins see everything
          return true if current_user_is_admin?

          ruleset = self.class.ruleset[controller]
          groups = RoleAuthorization::AllowGroup.get(self.class.allowable_groups[controller])

          if defined?(DEBUG_AUTHORIZATION_RULES) == 'constant'
            Rails.logger.info "#" * 60
            Rails.logger.info ruleset.to_s
            Rails.logger.info "#" * 60
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

        def accessible?(access_role)
          return true if current_user_is_admin?
          return false if access_role.nil?
          return true if access_role.name.to_sym == :public
          return false if session[:access_rights].nil?
          session[:access_rights].include?(access_role.name.to_sym)
        end

        def authorized?(url, method = nil)
          return false unless url
          return true if current_user_is_admin?

          method ||= (params[:method] || request.method)
          url_parts = URI::split(url.strip)
          path = url_parts[5]

          begin
            hash = Rails.application.routes.recognize_path(path, :method => method)
            return authorized_action?(self, hash[:controller], hash[:action].to_sym, hash[:id]) if hash
          rescue Exception => e
            Rails.logger.error e.inspect
            Rails.logger.error e.backtrace
            # continue on
          end

          # Mailto link
          return true if url =~ /^mailto:/

          # Public file
          file = File.join(RAILS_ROOT, 'public', url)
          return true if File.exists?(file)

          # Passing in different domain
          return remote_url?(url_parts[2])
        end

        def remote_url?(domain = nil)
          return false if domain.nil? || domain.strip.length == 0
          request.host.downcase != domain.downcase
        end
      end # InstanceMethods
    end
  end
end
