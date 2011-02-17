module RoleAuthorization
  module Exts
    module Session
      def self.included(base)
        base.send :include, InstanceMethods
        base.class_eval do
          helper_method :current_user_is_admin?
          helper_method :admin?
          helper_method :access_in_role?
        end
      end

      module InstanceMethods
        protected

        def add_role_authorization_session_values(user = nil)
          user ||= current_user

          if user
            roles = user.roles.where({:roleable_id => nil}).all
            session[:access_rights] = roles.collect {|role| role.name.to_sym}
          end
        end

        def current_user_is_admin?
          !session[:access_rights].nil? && session[:access_rights].include?(:all)
        end

        def admin?
          current_user_is_admin?
        end

        def access_in_role?(role)
          return true if current_user_is_admin?
          return true if session_access_rights_include?(role)
          false
        end

        def session_access_rights_include?(role)
          return false unless session[:access_rights]
          session[:access_rights].include?(role)
        end

        def reset_role_authorization_session
          [:access_rights].each do |val|
            session[val] = nil if session[val]
          end
        end
      end
    end
  end
end
