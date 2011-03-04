module RoleAuthorization
  class Railtie < Rails::Railtie
    initializer "role_authorization.initialize" do |app|
      RoleAuthorization.load_rules
      ActiveRecord::Base.send :extend, RoleAuthorization::ActiveRecord if defined?(ActiveRecord)
    end

    # runs before every request in development
    # and once in production before serving requests
    # http://www.engineyard.com/blog/2010/extending-rails-3-with-railties
    config.to_prepare do
      RoleAuthorization::Roles.manager.try(:persist!)
    end
  end
end
