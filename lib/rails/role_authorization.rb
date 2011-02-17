module RoleAuthorization
  class Railtie < Rails::Railtie
    initializer "role_authorization.initialize" do |app|
      RoleAuthorization.enable
      RoleAuthorization.load_controller_classes
    end
  end
end
