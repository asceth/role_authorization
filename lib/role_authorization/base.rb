module RoleAuthorization
  module ClassMethods
    def enable
      # load rule mapper
      require 'role_authorization/mapper.rb'
      require 'role_authorization/ruleset.rb'
      require 'role_authorization/allow_group.rb'
      require 'role_authorization/rules/basic.rb'

      # exts
      require 'role_authorization/exts/model.rb'
      require 'role_authorization/exts/user.rb'

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
      if RoleAuthorization.view_security
        require 'role_authorization/exts/view_security'
        unless ActionView::Base.instance_methods.include? :link_to_or_show
          ActionView::Base.class_eval { include Exts::ViewSecurity }
        end
      end
    end
  end
  extend ClassMethods
end
