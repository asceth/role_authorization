module RoleAuthorization
  module Roles
    class Manager
      cattr_accessor :user_klass

      attr_accessor :global_roles, :object_roles
      attr_accessor :group_definitions, :groups
      attr_accessor :nicknames, :creations
      attr_accessor :klass

      def initialize
        @global_roles = []
        @object_roles = {}
        @groups = Hash.new
        @creations = Hash.new(Array.new)
        @nicknames = Hash.new {|hash, key| key}
        @cache_user_ids = false

        self
      end

      module InstanceMethods
        def cache_user(role_name, user_id, scope)
          if @cache_user_ids
            role(role_name).add_user(user_id)
          end
        end

        def uncache_user(role_name, user_id)
          if @cache_user_ids
            role(role_name).remove_user(user_id)
          end
        end

        def role(role_name)
          @_role ||= {}
          @_role[role_name] ||= klass.find_by_name(role_name)
        end

        def setup(klass)
          @klass = klass
          klass.send(:include, RoleAuthorization::Roles::Role)

          # now that we know what class to use, create our role groups
          (@group_definitions || {}).each_pair do |group_name, roles|
            @groups[group_name.to_sym] = RoleAuthorization::Roles::RoleGroup.new(klass, roles)
          end
        end

        def cache(value)
          @cache_user_ids = value
        end

        def roles(*options)
          @global_roles, @object_roles = if options.last.is_a?(Hash)
                                           [options.pop, options].reverse
                                         else
                                           [options, {}]
                                         end
        end

        def creation_rules(rules)
          rules.each_pair do |key, allowed_roles|
            @creations[key] = allowed_roles.flatten.uniq
          end
        end

        def group(groups)
          @group_definitions = groups
        end

        def nickname(nicknames)
          @nicknames = nicknames
        end

        def any(new_scope = nil)
          case new_scope
          when nil
            [global_roles, object_roles.values].flatten
          when :global
            global_roles
          else
            object_roles[new_scope]
          end
        end

        # make sure our defined roles are in the database
        # remove any roles taken out
        def persist!
          return if klass.nil?
          return unless klass.new.respond_to?(:nickname)

          persisted_roles = klass.all.inject({}) {|hash, record| hash[record.name.to_sym] = record; hash}

          [global_roles, object_roles.values].flatten.map do |role_name|
            if persisted_roles.delete(role_name).nil?
              klass.create(:name => role_name.to_s, :nickname => nicknames[role_name].to_s)
            end
          end

          # if we have persisted roles left we delete them
          persisted_roles.values.map(&:destroy)
        end
      end
      include InstanceMethods
    end
  end
end
