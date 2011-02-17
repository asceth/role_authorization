module RoleAuthorization
  # define our rule helper in Mapper
  class Mapper
    def object_role(user_role, options={}, &block)
      options.assert_valid_keys(:only, :resource, :type)
      rule(user_role, :object_role, options, &block)
    end
  end

  module Rules
    class ObjectRole < Basic
      def initialize(controller, options, &block)
        @controller_klass = controller
        @options = options
        self
      end

      def to_s
        if @options[:resource]
          "allow when current_user has the role (#{@options[:role]}) for a specific object (#{@options[:resource]})"
        else
          "allow when current_user has the role (#{@options[:role]}) for any object of type #{@options[:type]}"
        end
      end

      def authorized?(controller_instance, controller, action, id)
        object = @options[:resource].nil? ? nil : find_object(controller_instance) if @options[:resource]

        if object
          return true if controller_instance.current_user.has_object_role?(object, @options[:role])
        elsif @options[:type].constantize.respond_to?(:enrolled)
          return true if @options[:type].constantize.enrolled(@options[:role]).include?(controller_instance.current_user)
        end

        return false
      end

      def find_object(controller_instance)
        # try to find as instance variable
        object = controller_instance.instance_variable_get("@#{@options[:resource]}".to_sym) rescue nil

        # try to find based on params
        if object.nil? && !controller_instance.params["#{@options[:resource]}_id"].blank?
          object = @options[:type].constantize.find_by_id(controller_instance.params["#{@options[:resource]}_id"])
        end

        object
      end
    end
  end
end
