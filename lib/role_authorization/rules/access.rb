module RoleAuthorization
  # define our rule helper in Mapper
  class Mapper
    def access(options={}, &block)
      options.assert_valid_keys(:resource, :only, :no_send)
      rule(:access, :access, options, &block)
    end
  end

  module Rules
    class Access < Basic
      def initialize(controller, options, &block)
        @controller_klass = controller
        @options = {:no_send => false}.merge(options)
        @block = block
        @mapper = nil

        unless @block.nil?
          @mapper = RoleAuthorization::Mapper.new(@controller_klass)
          @mapper.instance_eval(&@block)
        end
        self
      end

      def to_s
        output = ["allow current_user with access role of requested #{[controller_name.singularize, @options[:check]].compact.join('.')}"]
        output << @mapper.to_s
      end

      def authorized?(controller_instance, controller, action, id)
        object = find_object(controller_instance, controller, action, id)
        unless object.nil?
          return true if controller_instance.accessible?(object.access_role)
        end

        if !@mapper.nil? && object.try(:access_role).nil?
          return true if @mapper.authorized?(controller_instance, controller, action, object)
        end
        return false
      end

      def find_object(controller_instance, controller, action, id)
        object = nil
        instance_found = false

        if id.is_a?(Integer) || id.is_a?(String)
          # id is a parameter passed in
          # we use the :resource option to find the right instance variable
          object = controller_instance.instance_variable_get('@' + @options[:resource].to_s) rescue nil
          instance_found = true unless object.nil?

          if object.nil? && controller_instance.instance_variable_get('@' + controller)
            collection = controller_instance.instance_variable_get('@' + controller)
            object = collection.detect {|item| item.andand.id == id.to_i}
          end

          if object.nil?
            model = controller.singularize.camelize.constantize
            if model.respond_to?(:to_param_column)
              finder = "find_by_#{model.to_param_column}".to_sym
            else
              finder = :find_by_id
              id = id.to_i
            end

            object = model.send(finder, id)
          end

          unless object.nil?
            if @options.has_key?(:resource) && !@options[:no_send] && !instance_found && object.respond_to?(@options[:resource])
              object = object.send(@options[:resource])
            end
          end
        elsif id.is_a?(ActiveRecord::Base) && @options.has_key?(:resource)
          # id is already a model record so this is a nested rule

          # first try to find it as an instance variable
          object = controller_instance.instance_variable_get('@' + @options[:resource].to_s) rescue nil

          # next we call id's method to find it
          object = id.send(@options[:resource]) if object.nil?
        end

        return object
      end
    end # Access
  end
end
