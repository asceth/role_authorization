RoleAuthorization::Rules.define :all do
  true
end

RoleAuthorization::Rules.define :role do
  if controller_instance.current_user.blank?
    false
  else
    scope = if options[:scope]
              if options[:scope].is_a?(Proc)
                instance_eval(&options[:scope])
              else
                options[:scope]
              end
            else
              :global
            end

    controller_instance.current_user.roles(options[:scope] || :global).include?(role)
  end
end

RoleAuthorization::Rules.define :user do
  resource = controller_instance.instance_variable_get("@#{options[:resource]}".to_sym)

  if resource.nil?
    false
  else
    controller_instance.current_user.try(:id) == resource.try(options[:check])
  end
end

RoleAuthorization::Rules.define :custom do
  unless options[:block].nil?
    true if options[:block].call(controller_instance) == true
  else
    false
  end
end
