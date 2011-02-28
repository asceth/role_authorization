module RoleAuthorization
  module Exts
    module View
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

      def role(*user_roles, &block)
        if block_given? && !session[:access_rights].blank? && !(user_roles & session[:access_rights]).empty?
          capture_haml(&block)
        end
      end

      def permitted_to?(url, method, &block)
        capture_haml(&block) if block_given? && authorized?(url, method)
      end

      def link_to_or_show(name, options = {}, html_options = nil)
        lnk = link_to(name, options, html_options)
        lnk.length == 0 ? name : lnk
      end

      def links(*lis)
        rvalue = []
        lis.each{|link| rvalue << link if link.length > 0 }
        rvalue.join(' | ')
      end
    end # View
  end
end
