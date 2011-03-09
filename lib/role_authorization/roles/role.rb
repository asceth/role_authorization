module RoleAuthorization
  module Roles
    module Role
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
        base.class_eval do
          validates_uniqueness_of :name
          serialize :user_ids
        end
      end

      module InstanceMethods
        def scope_with(scope)
          if scope.is_a?(Symbol) || scope.is_a?(String) || scope.is_a?(Integer)
            scope
          else
            scope.id
          end
        end

        def users(scope = nil)
          if user_ids.is_a?(Hash)
            User.where(:id => user_ids[scope_with(scope)])
          else
            User.where(:id => user_ids)
          end
        end

        def add_user(user_id, scope = nil)
          unserialized_user_ids = self.user_ids

          if scope.nil? || scope.is_a?(Symbol) || scope.is_a?(String) || scope.is_a?(Class)
            unserialized_user_ids ||= Array.new
            unserialized_user_ids << user_id
            unserialized_user_ids.uniq!
          else
            unserialized_user_ids ||= Hash.new
            unserialized_user_ids[scope.id] ||= Array.new
            unserialized_user_ids[scope.id] << user_id
            unserialized_user_ids[scope.id].uniq!
          end

          self.user_ids = unserialized_user_ids

          save
        end

        def remove_user(user_id, scope = nil)
          unserialized_user_ids = self.user_ids

          if scope.nil? || scope.is_a?(Symbol) || scope.is_a?(String) || scope.is_a?(Class)
            unserialized_user_ids ||= Array.new
            unserialized_user_ids.delete(user_id)
          else
            unserialized_user_ids ||= Hash.new
            unserialized_user_ids[scope.id] ||= Array.new
            unserialized_user_ids[scope.id].delete(user_id)
          end

          self.user_ids = unserialized_user_ids

          save
        end
      end

      module ClassMethods
        def group(group_name)
          RoleAuthorization::Roles.manager.groups[group_name.to_sym]
        end
      end
    end
  end
end
