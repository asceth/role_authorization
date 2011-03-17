RoleAuthorization::Rules.define :all do
  true
end

RoleAuthorization::Rules.define :role do
  if controller_instance.current_user.blank?
    false
  else
    scope = if options[:scope]
              if options[:scope].is_a?(Proc)
                controller_instance.instance_eval(&options[:scope])
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
  if controller_instance.current_user.blank?
    false
  else
    if options[:resource]
      check_method = options[:check] || :id
      resource_instances = controller_instance.instance_eval(&options[:resource])
      resource_instances = [resources_instances] unless resource_instances.is_a?(Array)

      resource_instances.map do |resource_instance|
        controller_instance.current_user.id == resource_instance.try(check_method)
      end.include?(true)
    else
      false
    end
  end
end

RoleAuthorization::Rules.define :custom do
  unless options[:block].nil?
    true if controller_instance.instance_eval(&options[:block]) == true
  else
    false
  end
end
