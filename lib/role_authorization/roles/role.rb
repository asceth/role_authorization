module RoleAuthorization
  module Roles
    module Role
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
        base.class_eval do
          validates :name, :uniqueness => true
          serialize :user_ids
        end
      end

      module InstanceMethods
        def users(scope = nil)
          if user_ids.is_a?(Hash)
            User.where(:id => user_ids[scope])
          else
            User.where(:id => user_ids)
          end
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
