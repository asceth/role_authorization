module RoleAuthorization
  module ViewSecurity
    def load_controller_classes
      @controller_classes = {}

      maybe_load_framework_controller_parent

      Dir.chdir("#{Rails.root}/app/controllers") do
        Dir["**/*.rb"].sort.each do |c|
          next if c.include?("application")
          rola_load(c)
        end
      end
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
