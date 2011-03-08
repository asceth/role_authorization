module RoleAuthorization
  module ActiveRecord
    def acts_as_role_manager
      RoleAuthorization::Roles.manager.setup(self)
    end
  end
end
