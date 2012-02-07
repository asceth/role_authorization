class Role < ActiveRecord::Base
  acts_as_role_manager

  def to_s
    nickname.to_s.humanize
  end
end
