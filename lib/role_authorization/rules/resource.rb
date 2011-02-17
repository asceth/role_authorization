module RoleAuthorization
  # define our rule helper in Mapper
  class Mapper
    def resource(user_role, options={}, &block)
      options.assert_valid_keys(:resource, :only, :no_send)
      rule(user_role, :resource, options, &block)
    end
  end

  module Rules
    class Resource < Basic
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
        output = ["allow current_user with role :#{@options[:role]} of requested resource #{@options[:resource]}"]
        output << @mapper.to_s
      end

      def authorized?(controller_instance, controller, action, id)
        object = find_object(controller_instance, controller, action, id)
        return true if controller_instance.current_user.has_object_role?(@options[:role], object) unless object.nil?

        unless @mapper.nil?
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

          if controller_instance.instance_variable_defined?('@' + controller)
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

          if id.respond_to?("#{@options[:resource]}_id") && controller_instance.instance_variable_defined?('@' + @options[:resource].to_s.pluralize)
            collection = controller_instance.instance_variable_get('@' + @options[:resource].to_s.pluralize)
            object = collection.detect {|item| item.andand.id == id.send("#{@options[:resource]}_id")}
          end

          # next we call id's method to find it
          object = id.send(@options[:resource]) if object.nil?
        elsif id.nil?
          # no id means we must be using an association or parent resource for this rule

          if @options.has_key?(:resource)
            object_base = @options[:resource].to_s
            object_id = controller_instance.params["#{object_base}_id".to_sym]

            unless object_id.nil?
              object = controller_instance.instance_variable_get('@' + object_base) rescue nil
              object = nil unless object.id == object_id

              object = object_base.to_s.camelize.constantize.find_by_id(object_id.to_i) if object.nil?
            end
          end
        end

        return object
      end # find object
    end
  end
end
