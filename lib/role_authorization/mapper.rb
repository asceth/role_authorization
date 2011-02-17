module RoleAuthorization
  class Mapper
    def initialize(controller_klass)
      @controller_klass = controller_klass
      @rules = Hash.new do |h,k|
        h[k] = Hash.new do |h1,k1|
          h1[k1] = Array.new
        end
      end
      self
    end

    def to_s
      output = []
      @rules.each_pair do |action, rules|
        output << "Action :#{action}"
        output << "    allow roles #{rules[:roles].inspect}" unless rules[:roles].nil? || rules[:roles].empty?
        rules[:rules].map {|rule| output << "    #{rule.to_s}"} if rules.has_key?(:rules)
        output << ""
        output << ""
      end

      output.join("\n")
    end

    # special role rules
    def all(options={}, &block)
      options.assert_valid_keys(:only)
      rule(:all, :role, options, &block)
    end

    def role(user_role, options={}, &block)
      options.assert_valid_keys(:check, :only)
      rule(user_role, :role, options, &block)
    end

    def authorized?(controller_instance, controller, action, id = nil)
      rules = @rules[action]

      return false if rules.empty?
      return true if rules[:roles].include?(:all)
      unless controller_instance.session[:access_rights].nil?
        return true if !(rules[:roles] & controller_instance.session[:access_rights]).empty?
      end

      if rules.has_key?(:rules)
        rules[:rules].each do |rule|
          return true if rule.authorized?(controller_instance, controller, action, id)
        end
      end

      return false
    end

    private

    # rule method
    def rule(user_role, type, options={}, &block)
      actions = [options.delete(:only) || [:all]].flatten.collect {|v| v.to_sym}

      case type
      when :role
        irule = nil
        role_or_type = user_role
      else
        irule = "RoleAuthorization::Rules::#{type.to_s.camelize}".constantize.new(@controller_klass, options.merge(:role => user_role), &block)
        role_or_type = type
      end

      actions.each do |action|
        @rules[action][:roles] << role_or_type if irule.nil?
        @rules[action][:rules] << irule unless irule.nil?
      end
    end
  end
end
