module RoleAuthorization
  module User
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods

      base.class_eval do
        serialize :serialized_roles
      end

      RoleAuthorization::Roles.manager.user_klass = base
    end

    module ClassMethods
      def enroll(user_id, role_name)
        user = find_by_id(user_id.to_i)
        user.enroll(role_name) unless user.nil?
      end # enroll

      def withdraw(user_id, role_name)
        user = find_by_id(user_id.to_i)
        user.withdraw(role_name) unless user.nil?
      end # withdraw
    end # ClassMethods

    module InstanceMethods
      def scope_with(scope = nil)
        return [nil, nil] if scope.nil?

        if scope.is_a?(Symbol) || scope.is_a?(String)
          [scope, nil]
        elsif scope.is_a?(Class)
          [scope.to_s.downcase.to_sym, nil]
        else
          [scope.class.to_s.downcase.to_sym, scope.id]
        end
      end

      def scope_ids_from(*roles)
        (serialized_roles || {}).inject([]) do |array, (key, value)|
          next if key == :global
          next unless value.is_a?(Hash)

          value.each_pair do |key, value|
            array << key.to_i unless (value & roles).empty?
          end
          array
        end
      end

      def roles(scope = nil)
        scope, scope_id = scope_with(scope)

        (serialized_roles || {}).inject([]) do |array, (key, value)|
          if key == :global && scope.nil?
            array << value
          else
            if scope.nil? || (key == scope.to_sym && scope_id.nil?)
              array << value.values
            else
              array << value[scope_id]
            end
          end

          array
        end.flatten.uniq
      end

      def has_role?(role, scope = nil)
        roles(scope).include?(role)
      end

      def <<(value)
        enroll(value)
      end

      # adds a role to the user
      def enroll(role_name, scope = nil)
        return true if has_role?(role_name.to_sym, scope)

        scope, scope_id = scope_with(scope)
        self.serialized_roles ||= Hash.new

        if scope.nil?
          self.serialized_roles[:global] ||= Array.new
          self.serialized_roles[:global] << role_name.to_sym
        else
          if scope_id.nil?
            self.serialized_roles[scope] ||= Array.new
            self.serialized_roles[scope] << role_name.to_sym
          else
            self.serialized_roles[scope] ||= Hash.new
            self.serialized_roles[scope][scope_id] ||= Array.new
            self.serialized_roles[scope][scope_id] << role_name.to_sym
          end
        end

        if save(:validate => false)
          RoleAuthorization::Roles.manager.klass.find_by_name(role_name).add_user(self.id, scope)
          true
        else
          false
        end
      end

      def withdraw(role_name, scope = nil)
        return true unless has_role?(role_name.to_sym, scope)

        scope, scope_id = scope_with(scope)
        serialized_roles ||= Hash.new

        if scope.nil?
          self.serialized_roles[:global] ||= Array.new
          self.serialized_roles[:global].delete(role_name.to_sym)
        else
          if scope_id.nil?
            self.serialized_roles[scope] ||= Array.new
            self.serialized_roles[scope].delete(role_name.to_sym)
          else
            self.serialized_roles[scope] ||= Hash.new
            self.serialized_roles[scope][scope_id] ||= Array.new
            self.serialized_roles[scope][scope_id].delete(role_name.to_sym)
          end
        end

        if save(:validate => false)
          RoleAuthorization::Roles.manager.klass.find_by_name(role_name).remove_user(self.id, scope)
          true
        else
          false
        end
      end

      def admin?
        has_role?(:all, :global)
      end
    end # InstanceMethods
  end
end
