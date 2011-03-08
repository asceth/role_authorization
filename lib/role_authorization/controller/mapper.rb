module RoleAuthorization
  class Mapper
    def initialize
      @rules = Hash.new do |h,k|
        h[k] = Array.new
      end
      self
    end

    def to_s
      output = []
      @rules.each_pair do |action, rules|
        output << "Action :#{action}"
        rules.map {|rule| output << "    #{rule.to_s}"}
        output << ""
        output << ""
      end

      output.join("\n")
    end

    def add_to_rules(rule_name, *options, &block)
      rule = RoleAuthorization::Rules::Rule.new(*options, &block)

      actions = ([rule.options[:only] || [:all]]).flatten.map(&:to_sym)

      actions.map do |action|
        @rules[action] << rule
      end
    end

    def authorized?(controller_instance, controller, action, id = nil)
      rules = @rules[action]

      return false if rules.empty?

      rules.map do |rule|
        return true if rule.authorized?(controller_instance, controller, action, id)
      end

      return false
    end
  end
end
