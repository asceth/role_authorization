module RoleAuthorization
  module Exts
    module Role
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
        base.class_eval do
          serialize :user_ids
        end
      end

      module ClassMethods
        def roles(role_array)
          @roles = role_array
        end

        def role_creation(&block)
        end

        def users
          User.where(:id => user_ids)
        end
      end
    end
  end
end
