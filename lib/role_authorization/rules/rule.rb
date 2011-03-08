module RoleAuthorization
  module Rules
    class Rule
      attr_accessor :role, :options
      attr_accessor :returning

      # for calls to authorized?
      attr_accessor :controller_instance, :controller, :action, :id

      def initialize(*options, &block)
        @returning = block
        @options, @role = if options.is_a?(Hash)
                            [options, nil]
                          elsif options.last.is_a?(Hash)
                            [options.pop, options.first]
                          else
                            [{}, options.first]
                          end

        self
      end

      def authorized?(*args)
        @controller_instance, @controller, @action, @id = args

        instance_eval(&returning)
      end
    end
  end
end



