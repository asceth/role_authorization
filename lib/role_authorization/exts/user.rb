module RoleAuthorization
  module Exts
    module User
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods

        base.class_eval do
          has_many :user_roles, :dependent => :delete_all
          has_many :roles, :through => :user_roles
        end
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
        # has_object_role? simply needs to return true or false whether a user has a role or not.
        # It may be a good idea to have "admin" roles return true always
        # Return false always for anonymous users
        def has_object_role?(role, object)
          return false if self.anonymous?

          @object_user_roles ||= roles.all(:conditions => ["roleable_type IS NOT NULL and roleable_id IS NOT NULL"])
          result = @object_user_roles.detect do |r|
            r.roleable_type == object.class.to_s && r.roleable_id == object.id && r.name == role.to_s
          end
          !result.nil?
        end

        # adds a role to the user
        def enroll(role_name)
          role_id = role_name.is_a?(Integer) ? role_name : Role.find_by_name(role_name.to_s).try(:id)
          user_roles.create(:role_id => role_id) if !role_id.nil? && self.user_roles.find_by_role_id(role_id).nil?
        end

        def withdraw(role_name)
          role_id = role_name.is_a?(Integer) ? role_name : Role.find_by_name(role_name.to_s).try(:id)
          UserRole.delete_all(["user_id = ? AND role_id = ?", self.id, role_id]) unless role_id.nil?
        end

        def admin?
          return true if roles.include?(Role.get(:all))
          false
        end
      end # InstanceMethods
    end
  end
end
