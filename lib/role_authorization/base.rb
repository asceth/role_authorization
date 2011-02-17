module RoleAuthorization
  class << self
    # shortcut for <tt>enable_actionpack; enable_activerecord</tt>
    def enable
      enable_actionpack
      enable_activerecord

      # load rule mapper
      load 'role_authorization/mapper.rb'

      # load default rules
      Dir.chdir(File.dirname(__FILE__)) do
        Dir["role_authorization/rules/*.rb"].each do |rule_definition|
          require rule_definition
        end
      end

      # load application rules
      Dir.chdir(Rails.root) do
        Dir["lib/rules/*.rb"].each do |rule_definition|
          require rule_definition
        end
      end

      # load allow groups
      Dir.chdir(Rails.root) do
        Dir["lib/allow_groups/*.rb"].each do |allow_group|
          require allow_group
        end
      end
    end

    def enable_actionpack
      load 'role_authorization/exts/view.rb'
      unless ActionView::Base.instance_methods.include? :link_to_or_show
        ActionView::Base.class_eval { include Exts::View }
      end

      load 'role_authorization/exts/session.rb'
      load 'role_authorization/exts/controller.rb'
      unless ActionController::Base.instance_methods.include? :authorized?
        ActionController::Base.class_eval { include Exts::Session }
        ActionController::Base.class_eval { include Exts::Controller }
      end
    end

    def enable_activerecord
      load 'role_authorization/exts/model.rb'
      unless ActiveRecord::Base.instance_methods.include? :roleable
        ActiveRecord::Base.class_eval { include Exts::Model }
      end
    end

    def load_controller_classes
      @controller_classes = {}

      maybe_load_framework_controller_parent

      Dir.chdir("#{Rails.root}/app/controllers") do
        Dir["**/*.rb"].sort.each do |c|
          next if c.include?("application")
          rola_load(c)
        end
      end

#       if ENV['RAILS_ENV'] != 'production'
#         if ActiveSupport.const_defined?("Dependencies")
#           ActiveSupport::Dependencies.clear
#         else
#           Dependencies.clear
#         end
#       end
    end

    def maybe_load_framework_controller_parent
      if ::Rails::VERSION::MAJOR >= 3 || (::Rails::VERSION::MAJOR >= 2 && ::Rails::VERSION::MINOR >= 3)
        filename = "application_controller.rb"
      else
        filename = "application.rb"
      end
      require_or_load(filename)
    end

    def rola_load(filename)
      klass = class_name_from_file(filename)
      require_or_load(filename)
      @controller_classes[klass] = qualified_const_get(klass)
    end

    def require_or_load(filename)
      if ActiveSupport.const_defined?("Dependencies")
        ActiveSupport::Dependencies.require_or_load(filename)
      else
        Dependencies.require_or_load(filename)
      end
    end

    def class_name_from_file(str)
      str.split(".")[0].split("/").collect{|s| s.camelize }.join("::")
    end

    def qualified_const_get(klass)
      if klass =~ /::/
        namespace, klass = klass.split("::")
        eval(namespace).const_get(klass)
      else
        const_get(klass)
      end
    end
  end
end
