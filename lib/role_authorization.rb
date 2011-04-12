# controller
require 'role_authorization/controller/mapper'
require 'role_authorization/controller/ruleset'
require 'role_authorization/controller/allow_group'
require 'role_authorization/controller'

# roles
require 'role_authorization/roles/manager'
require 'role_authorization/roles/role'
require 'role_authorization/roles/role_group'
require 'role_authorization/roles'

# active record
require 'role_authorization/active_record'

# rules
require 'role_authorization/rules'
require 'role_authorization/rules/rule'
require 'role_authorization/rules/defaults'

# exts
require 'role_authorization/user'

require 'rails/role_authorization' if defined?(Rails)

module RoleAuthorization
  module ClassMethods
    def load_rules
      # load default rules
      Dir.chdir(File.dirname(__FILE__)) do
        Dir["rules/*.rb"].each do |rule_definition|
          require "#{File.dirname(__FILE__)}/#{rule_definition}"
        end
      end

      # load application rules
      Dir.chdir(Rails.root) do
        Dir["lib/rules/*.rb"].each do |rule_definition|
          require "#{Rails.root}/#{rule_definition}"
        end
      end

      # load allow groups
      Dir.chdir(Rails.root) do
        Dir["lib/allow_groups/*.rb"].each do |allow_group|
          require "#{Rails.root}/#{allow_group}"
        end
      end
    end

    def enable_view_security
      require 'role_authorization/view_security'
      unless ActionView::Base.instance_methods.include? :link_to_or_show
        ActionView::Base.class_eval { include RoleAuthorization::ViewSecurity }
      end
    end
  end
  extend ClassMethods
end


