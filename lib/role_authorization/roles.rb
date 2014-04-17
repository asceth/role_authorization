module RoleAuthorization
  module Roles
    module ClassMethods
      # this can be called multiple times
      def configure(&block)
        (@role_manager ||= RoleAuthorization::Roles::Manager.new).instance_eval(&block)
      end

      def manager
        @role_manager || configure {}
      end
    end
    extend ClassMethods
  end
end
