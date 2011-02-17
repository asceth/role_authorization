module RoleAuthorization
  module Ruleset
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def cattr_ruleset(*syms)
        syms.each do |sym|
          class_eval(<<-EOS, __FILE__, __LINE__ + 1)
            unless defined? @@#{sym}
              @@#{sym} = Hash.new
            end

            def self.#{sym}
              @@#{sym}
            end

            def self.#{sym}=(obj)
              @@#{sym} = obj
            end

            def self.add_to_#{sym}(name, set = nil, &block)
              ruleset = self.#{sym}
              if block_given?
                ruleset[name] = RoleAuthorization::Mapper.new(self)
                ruleset[name].instance_eval(&block)
              elsif !set.nil?
                ruleset[name] = set
              end
              self.#{sym} = ruleset
            end
          EOS
        end
      end
    end
  end
end
