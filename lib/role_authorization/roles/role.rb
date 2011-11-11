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
          if scope.blank? || scope.is_a?(Symbol) || scope.is_a?(String) || scope.is_a?(Integer)
            scope || :all
          else
            scope.id
          end
        end

        def users(scope = nil)
          if user_ids.blank?
            []
          else
            if scope.nil?
              RoleAuthorization::Roles::Manager.user_klass.where(:id => user_ids.values.flatten.uniq).all
            else
              RoleAuthorization::Roles::Manager.user_klass.where(:id => user_ids[scope_with(scope)]).all
            end
          end
        end

        def add_user(user_id, scope = nil)
          unserialized_user_ids = self.user_ids
          unserialized_user_ids ||= Hash.new

          if scope.nil? || scope.is_a?(Symbol) || scope.is_a?(String) || scope.is_a?(Class)
            unserialized_user_ids[scope_with(scope)] ||= Array.new
            unserialized_user_ids[scope_with(scope)] << user_id
            unserialized_user_ids[scope_with(scope)].uniq!
          else
            unserialized_user_ids[scope_with(scope)] ||= Array.new
            unserialized_user_ids[scope_with(scope)] << user_id
            unserialized_user_ids[scope_with(scope)].uniq!
          end

          self.user_ids = unserialized_user_ids

          save
        end

        def remove_user(user_id, scope = nil)
          unserialized_user_ids = self.user_ids
          unserialized_user_ids ||= Hash.new

          if scope.nil? || scope.is_a?(Symbol) || scope.is_a?(String) || scope.is_a?(Class)
            unserialized_user_ids[scope_with(scope)] ||= Array.new
            unserialized_user_ids[scope_with(scope)].delete(user_id)
          else
            unserialized_user_ids[scope_with(scope)] ||= Array.new
            unserialized_user_ids[scope_with(scope)].delete(user_id)
          end

          self.user_ids = unserialized_user_ids

          save
        end
      end

      module ClassMethods
        def group(group_name)
          RoleAuthorization::Roles.manager.groups[group_name.to_sym]
        end

        def roles(scope = nil, creations = nil)
          scoped_roles = if scope.nil? || scope.to_sym == :global
                           RoleAuthorization::Roles.manager.global_roles
                         else
                           scope = if scope.is_a?(Class)
                                     scope.class.to_s.downcase.to_sym
                                   else
                                     scope.to_s.downcase.to_sym
                                   end

                           RoleAuthorization::Roles.manager.object_roles[scope]
                         end

          if creations.nil?
            scoped_roles.flatten.uniq
          else
            creations.map do |creation|
              scoped_roles & RoleAuthorization::Roles.creations[creation]
            end.flatten.uniq
          end
        end
      end
    end
  end
end
