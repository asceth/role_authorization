module RoleAuthorization
  # define our rule helper in Mapper
  class Mapper
    def logged_in(options={}, &block)
      options.assert_valid_keys(:only)
      rule(:logged_in, :logged_in, options, &block)
    end
  end

  module Exts
    module View
      def logged_in(&block)
        if block_given? && !current_user.anonymous?
          capture_haml(&block)
        end
      end
    end
  end

  module Rules
    class LoggedIn < Basic
      def initialize(controller, options, &block)
        @controller_klass = controller
        @options = options
        self
      end

      def to_s
        "allow when current_user is logged in (not anonymous)"
      end

      def authorized?(controller_instance, controller, action, id)
        return true unless controller_instance.current_user.anonymous?
        return false
      end
    end
  end
end
