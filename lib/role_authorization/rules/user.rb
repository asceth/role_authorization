module RoleAuthorization
  # define our rule helper in Mapper
  class Mapper
    def user(options={}, &block)
      options.assert_valid_keys(:check, :only, :resource, :association)
      rule(:user, :user, options, &block)
    end
  end

  module Rules
    class User < Basic
      def initialize(controller, options, &block)
        @controller_klass = controller
        @options = options
        self
      end

      def to_s
        "allow when current_user.id == #{[@options[:resource], @options[:association], @options[:check]].compact.join('.')}"
      end

      def authorized?(controller_instance, controller, action, id)
        object = find_object(controller_instance, controller, action, id)

        unless object.nil?
          [object].flatten.each do |obj|
            return true if controller_instance.current_user.owns?(obj.send(@options[:check]))
          end
        end

        return false
      end

      def find_object(controller_instance, controller, action, id)
        object = nil

        if id.nil? && !@options[:resource].nil?
          if controller_instance.instance_variable_defined?('@' + @options[:resource].to_s)
            object = controller_instance.instance_variable_get('@' + @options[:resource].to_s)
          end
          model = @options[:resource].to_s.camelize.constantize
        elsif id.is_a?(Integer) || id.is_a?(String)
          if controller_instance.instance_variable_defined?('@' + controller)
            collection = controller_instance.instance_variable_get('@' + controller)
            object = collection.detect {|item| item.andand.id == id.to_i}
          end
          model = controller.singularize.camelize.constantize
        elsif id.is_a?(ActiveRecord::Base) && @options.has_key?(:check)
          object = id
        end

        if object.nil?
          if model.respond_to?(:to_param_column)
            finder = "find_by_#{model.to_param_column}".to_sym
          else
            finder = :find_by_id
            id = id.to_i
          end
          object = model.send(finder, id)
        end

        unless object.nil? || @options[:check].nil?
          object = @options[:association].nil? ? object : object.send(@options[:association])
        end

        object
      end
    end # User
  end
end
