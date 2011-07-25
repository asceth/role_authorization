Overview
--------

Role Authorization is a gem for Rails 3.x applications that provides role based access control.

    # config/initializers/01_roles.rb
    RoleAuthorization::Roles.configure do
      roles([
             :all,
             :developer
            ],
            :area => [
                      :area_worker
                     ])
    end

Define your roles in an initializer.  The :all role is special and grants access no matter what.  :developer is considered a "global" role in that a User may be #enroll into it (user.enroll(:developer) ).

The :area key defines a scoped role.  In this case you may have many Areas in your application and each Area may have many workers.  If you need to account for this in authorization you can do:  user.enroll(:area_worker, Area.find(1)).  The second option to enroll defines a scope.  In this case a user would have the role of area_worker but only in Area 1.



    # controllers
    allow do
      all :only => [:index]
      role :area_worker, :scope => proc {Area.find(params[:area_id])}, :only => [:edit, :update]
      role :area_worker, :scope => :area, :only => [:new, :create]
    end


Here we use a given rule, all to let anyone and everyone view the index action.  The next rule allows a user with the area_worker role in that specified area to access the edit/update actions.  Notice the use of proc which will be instance_evaled on the controller instance.  (Useful if using inherited_resources).  The next rule allows any area_worker in any area access to the new/create actions.


    # defining your own rules lib/rules/*.rb
    RoleAuthorization::Rules.define :logged_in do
      controller_instance.logged_in?
    end

Define a rule (the name you specify is the method you will use in the controller) and give it a block to execute.  The block must *not* use return but instead softly return true or false.  You have access to the controller_instance variable as well as the options variable.  options contains the options passed to the rule in a controller.  For example:


    # controller
    allow do
      logged_in :only => [:index], :resource => proc {Area.find(1)}
    end

    # rule
    RoleAuthorization::Rules.define :logged_in do
      resource = controller_instance.instance_eval(&options[:resource])
      controller_instance.logged_in?(resource)
    end


