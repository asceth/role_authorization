module RoleAuthorization
  module Roles
    module Role
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
        base.class_eval do
          validates_uniqueness_of :name

          if Rails::VERSION::MAJOR >= 4
            store :user_ids, :coder => JSON
          else
            serialize :user_ids
          end
        end
      end

      module InstanceMethods
        def unserialized_user_ids
          result = if Rails::VERSION::MAJOR >= 4
                     self.user_ids.unserialized_value
                   else
                     self.user_ids
                   end

          if result.is_a?(Hash)
            result
          else
            Hash.new
          end
        end

        def scope_with(scope)
          if scope.blank? || scope.is_a?(Symbol) || scope.is_a?(String) || scope.is_a?(Integer)
            scope || :all
          else
            scope.id
          end
        end

        def users(scope = nil)
          @users ||= {}
          @users[scope] ||= if user_ids.blank?
                              []
                            else
                              if scope.nil?
                                RoleAuthorization::Roles::Manager.user_klass.where(:id => unserialized_user_ids.values.flatten.uniq).all
                              else
                                RoleAuthorization::Roles::Manager.user_klass.where(:id => unserialized_user_ids[scope_with(scope)]).all
                              end
                            end
        end

        def add_user(user_id, scope = nil)
          hash = unserialized_user_ids
          hash ||= Hash.new

          if scope.nil? || scope.is_a?(Symbol) || scope.is_a?(String) || scope.is_a?(Class)
            hash[scope_with(scope)] ||= Array.new
            hash[scope_with(scope)] << user_id
            hash[scope_with(scope)].uniq!
          else
            hash[scope_with(scope)] ||= Array.new
            hash[scope_with(scope)] << user_id
            hash[scope_with(scope)].uniq!
          end

          self.user_ids = hash

          save
        end

        def remove_user(user_id, scope = nil)
          hash = unserialized_user_ids
          hash ||= Hash.new

          if scope.nil? || scope.is_a?(Symbol) || scope.is_a?(String) || scope.is_a?(Class)
            hash[scope_with(scope)] ||= Array.new
            hash[scope_with(scope)].delete(user_id)
          else
            hash[scope_with(scope)] ||= Array.new
            hash[scope_with(scope)].delete(user_id)
          end

          self.user_ids = hash

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
