module RoleAuthorization
  class Railtie < Rails::Railtie
    initializer "role_authorization.initialize" do |app|
      RoleAuthorization.enable
    end
  end
end
