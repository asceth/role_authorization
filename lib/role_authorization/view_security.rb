module RoleAuthorization
  module ViewSecurity
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method :link_to_open, :link_to
        alias_method :link_to, :link_to_secured

        alias_method :button_to_open, :button_to
        alias_method :button_to, :button_to_secured

        alias_method :form_for_open, :form_for
        alias_method :form_for, :form_for_secured
      end
    end

    module InstanceMethods
      def form_for_secured(record_or_name_or_array, *args, &proc)
        options = args.last.is_a?(Hash) ? args.last : {}

        url = url_for(options[:url] || record_or_name_or_array)

        method = (options[:html] && options[:html].has_key?(:method)) ? options[:html][:method] : :post

        if authorized?(url, method)
          return form_for_open(record_or_name_or_array, *args, &proc)
        else
          return ""
        end
      end

      def link_to_secured(name, options = {}, html_options = nil)
        url = url_for(options)

        method = (html_options && html_options.has_key?(:method)) ? html_options[:method] : :get

        if authorized?(url, method)
          return link_to_open(name, url, html_options)
        else
          return ""
        end
      end

      def button_to_secured(name, options = {}, html_options = nil)
        url = url_for(options)

        method = (html_options && html_options.has_key?(:method)) ? html_options[:method] : :post

        if authorized?(url, method)
          return button_to_open(name, url, html_options)
        else
          return ""
        end
      end

      def link_to_or_show(name, options = {}, html_options = nil)
        lnk = link_to(name, options, html_options)
        lnk.length == 0 ? name : lnk
      end
    end # InstanceMethods

    module ClassMethods
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
    extend ClassMethods
  end
end