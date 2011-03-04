module RoleAuthorization
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
        return true if admin?

        ruleset = self.class.ruleset[controller]
        groups = RoleAuthorization::AllowGroup.get(self.class.allowable_groups[controller])

        if defined?(DEBUG_AUTHORIZATION_RULES) == 'constant'
          Rails.logger.info "#" * 30
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
    end # InstanceMethods
  end
end
