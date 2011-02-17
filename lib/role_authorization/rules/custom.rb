module RoleAuthorization
  # define our rule helper in Mapper
  class Mapper
    def custom(options={}, &block)
      options.assert_valid_keys(:only, :description)
      rule(:custom, :custom, options, &block)
    end
  end

  module Rules
    class Custom < Basic
      def initialize(controller, options, &block)
        @controller_klass = controller
        @options = options
        @block = block
        self
      end

      def to_s
        "allow when custom rule (#{@options[:description]}) returns true"
      end

      def authorized?(controller_instance, controller, action, id)
        unless @block.nil?
          result = @block.call(controller_instance)
          return true unless result == false || result.nil?
        end
        return false
      end
    end
  end
end
