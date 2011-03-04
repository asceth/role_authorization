module RoleAuthorization
  module ActiveRecord
    def acts_as_role_manager
      RoleAuthorization::Roles.configuration.setup(self.class)
    end
  end
end
