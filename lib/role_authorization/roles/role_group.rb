module RoleAuthorization
  module Roles
    class RoleGroup
      attr_accessor :klass, :roles

      def initialize(klass, roles)
        @klass = klass
        @roles = roles
      end

      def users(scope = nil)
        klass.find_all_by_name(roles).map {|role| role.users(scope) }
      end
    end
  end
end
