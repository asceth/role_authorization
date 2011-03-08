module RoleAuthorization
  module Rules
    module ClassMethods
      def define(rule_name, &block)
        RoleAuthorization::Mapper.send(:define_method, rule_name) do |*args|
          add_to_rules(rule_name, *args, &block)
        end
      end
    end
    extend ClassMethods
  end
end
