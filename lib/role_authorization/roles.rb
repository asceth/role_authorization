module RoleAuthorization
  module Roles
    module ClassMethods
      def configure(&block)
        (@role_manager ||= RoleAuthorization::Roles::Manager.new).instance_eval(&block)
      end

      def manager
        @role_manager
      end
    end
    extend ClassMethods
  end
end
