module RoleAuthorization
  module AllowGroup
    include RoleAuthorization::Ruleset
    cattr_ruleset :ruleset

    class << self
      def define(name, &block)
        add_to_ruleset(name, &block)
      end

      def get(*names)
        ruleset.values_at(*names.flatten.compact).compact
      end
    end
  end
end
