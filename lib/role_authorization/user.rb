module RoleAuthorization
  module User
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods

      base.class_eval do
        serialize :serialized_roles
      end

      RoleAuthorization::Roles::Manager.user_klass = base
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

      def roles(scopes = nil)
        scopes = [scopes] unless scopes.is_a? Array

        scopes.map do |scope|
          scope, scope_id = scope_with(scope)

          (serialized_roles || {}).inject([]) do |array, (key, value)|
            if key == :global && scope.nil?
              array << value
            else
              if scope.nil? || (key == scope.to_sym && scope_id.nil?)
                if value.is_a?(Hash)
                  array << value.values
                else
                  array << value unless value.nil?
                end
              else
              array << value[scope_id] unless scope_id.nil?
              end
            end

            array
          end
        end.flatten.uniq
      end

      def has_role?(role, scopes = nil)
        roles(scopes).include?(role)
      end

      def <<(value)
        enroll(value)
      end

      def global_roles
        roles(:global)
      end

      # mass enroll, global only
      def global_roles=(role_names)
        # first get rid of all global roles
        removed_roles = []

        self.serialized_roles ||= Hash.new

        (self.serialized_roles[:global] || []).map do |role_name|
          RoleAuthorization::Roles.manager.role(role_name).remove_user(self.id)
        end
        self.serialized_roles[:global] = Array.new

        role_names.map {|role_name| enroll(role_name.to_s)}
      end

      # adds a role to the user
      def enroll(role_name, scope = nil)
        return true if has_role?(role_name.to_sym, scope)

        scope_key, scope_id = scope_with(scope)
        self.serialized_roles ||= Hash.new

        if scope_key.nil?
          self.serialized_roles[:global] ||= Array.new
          self.serialized_roles[:global] << role_name.to_sym
        else
          if scope_id.nil?
            self.serialized_roles[scope_key] ||= Array.new
            self.serialized_roles[scope_key] << role_name.to_sym
          else
            self.serialized_roles[scope_key] ||= Hash.new
            self.serialized_roles[scope_key][scope_id] ||= Array.new
            self.serialized_roles[scope_key][scope_id] << role_name.to_sym
          end
        end

        if save(:validate => false)
          RoleAuthorization::Roles.manager.role(role_name).add_user(self.id, scope)
          true
        else
          false
        end
      end

      def withdraw(role_name, scope = nil)
        return true unless has_role?(role_name.to_sym, scope)

        scope_key, scope_id = scope_with(scope)
        serialized_roles ||= Hash.new

        if scope_key.nil?
          self.serialized_roles[:global] ||= Array.new
          self.serialized_roles[:global].delete(role_name.to_sym)
        else
          if scope_id.nil?
            self.serialized_roles[scope_key] ||= Array.new
            self.serialized_roles[scope_key].delete(role_name.to_sym)
          else
            self.serialized_roles[scope_key] ||= Hash.new
            self.serialized_roles[scope_key][scope_id] ||= Array.new
            self.serialized_roles[scope_key][scope_id].delete(role_name.to_sym)
          end
        end

        if save(:validate => false)
          RoleAuthorization::Roles.manager.role(role_name).remove_user(self.id, scope)
          true
        else
          false
        end
      end

      def withdraw_from_scope(scope)
        scope_key, scope_id = scope_with(scope)
        return true if scope_key.nil? || self.serialized_roles[scope_key].nil?

        if scope_id.nil?
          self.serialized_roles.delete(scope_key)
        else
          self.serialized_roles[scope_key].delete(scope_id)
        end
      end

      def admin?
        has_role?(:all, :global)
      end
    end # InstanceMethods
  end
end
