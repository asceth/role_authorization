module RoleAuthorization
  module Rules
    class Rule
      attr_accessor :role, :options
      attr_accessor :returning

      # for calls to authorized?
      attr_accessor :controller_instance, :controller, :action, :id

      def initialize(role, options, &block)
        @returning = block
        @role = role
        @options = options

        self
      end

      def authorized?(*args)
        @controller_instance, @controller, @action, @id = args

        instance_eval(&returning)
      end
    end
  end
end



