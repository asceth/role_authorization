module RoleAuthorization
  module Exts
    module ViewSecurity
       def self.included(base)
         base.class_eval do
           alias_method :link_to_open, :link_to
           alias_method :link_to, :link_to_secured

           alias_method :button_to_open, :button_to
           alias_method :button_to, :button_to_secured

           alias_method :form_for_open, :form_for
           alias_method :form_for, :form_for_secured
         end
       end

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
    end
  end
end
