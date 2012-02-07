class AddRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.string :name
      t.string :nickname
      t.text :user_ids
      t.timestamps
    end
  end
end
