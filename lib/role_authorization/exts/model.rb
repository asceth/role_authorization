module RoleAuthorization
  module Exts
    module Model
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        def roleable_options
          @roleable_options
        end

        def roleable_options=(options)
          @roleable_options = options
        end

        def roleable options = {}
          has_many :roles, :as => :roleable, :dependent => :delete_all
          after_create :create_roles

          send(:extend, SpecificClassMethods)

          options[:name] ||= :class

          options[:priority] ||= {}
          options[:creation_priority] ||= {}
          options[:roles] ||= [:default]
          options[:roles].each do |role_name|
            options[:priority][role_name] ||= 1
            options[:creation_priority][role_name] ||= 1
          end

          options[:cache] = {}
          @roleable_options = options
        end # roleable

        def enrolled(role_name)
          roles = Role.all(:conditions => {:roleable_type => self.to_s, :name => role_name.to_s})
          unless roles.empty?
            roles.collect(&:users).flatten
          else
            []
          end
        end
      end # ClassMethods

      module SpecificClassMethods
        def reset_roles
          all.map(&:reset_roles)
        end
      end

      module InstanceMethods

        def reset_roles
          options = self.class.roleable_options

          mroles = roles.all
          rejected_roles = mroles.reject {|r| options[:roles].include?(r.name.to_sym)}
          rejected_roles.map {|rejected_role| rejected_role.destroy}

          valid_roles = mroles - rejected_roles
          valid_role_names = valid_roles.collect(&:name)
          new_roles = options[:roles].select {|role| !valid_role_names.include?(role.to_sym)}
          valid_roles.each do |role|
            if roles.find_by_name(role.name.to_s).nil?
              roles.create(:name => role.name.to_s,
                           :display_name => "#{self.send(options[:name])} #{role.name.to_s}",
                           :creation_priority => options[:creation_priority][role.name.to_s],
                           :priority => options[:priority][role.name.to_s])
            end
          end
          new_roles.each do |role|
            roles.create(:name => role.to_s,
                         :display_name => "#{self.send(options[:name])} #{role.to_s}",
                         :creation_priority => options[:creation_priority][role],
                         :priority => options[:priority][role])
          end
          roles(true).all
        end

        def enroll(user, role)
          options = self.class.roleable_options
          role = role.is_a?(Integer) ? roles.find_by_id(role) : roles.find_by_name(role.to_s)
          user_id = ((user.is_a?(Integer) || user.is_a?(String)) ? user.to_i : user.id)
          unless role.nil?
            role.user_roles.create(:user_id => user_id)
          end
        end
        alias_method :assign, :enroll

        def enrolled(role)
          role = roles.find_by_name(role.to_s)
          unless role.nil?
            role.users
          else
            []
          end
        end

        def withdraw(user, role = nil)
          options = self.class.roleable_options
          role = role.is_a?(Integer) ? roles.find_by_id(role, :include => :user_roles) : roles.find_by_name(role.to_s, :include => :user_roles)
          user_id = ((user.is_a?(Integer) || user.is_a?(String)) ? user.to_i : user.id)
          unless role.nil?
            role.user_roles.first(:conditions => {:user_id => user_id}).try(:destroy)
          else
            UserRole.all(:conditions => {:user_id => user_id, :role_id => role_ids}).map(&:destroy)
          end
        end

        private
        def create_roles
          options = self.class.roleable_options
          options[:roles].each do |role|
            roles.create(:name => role.to_s,
                         :display_name => "#{self.send(options[:name])} #{role.to_s}",
                         :creation_priority => options[:creation_priority][role],
                         :priority => options[:priority][role])
          end
        end # create_user_roles
      end # InstanceMethods
    end
  end
end
