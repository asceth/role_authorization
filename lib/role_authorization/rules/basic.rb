module RoleAuthorization
  module Rules
    class Basic
      def initialize(controller, options, &block)
        @controller_klass = controller
        self
      end

      def to_s
        "deny all (basic rule)"
      end

      def controller_name
        @controller_klass.to_s.gsub('Controller', '')
      end

      def authorized?(controller_instance, controller, action, id)
        return false
      end
    end
  end
end
