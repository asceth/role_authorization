class UserRoles < ActiveRecord::Migration
  def self.up
    create_table :user_roles do |t|
      t.string :name
      t.string :display_name
      t.integer :priority

      t.references :roleable, :polymorphic => true
      t.timestamps
    end

    create_table :user_role_mappings do |t|
      t.belongs_to :user
      t.belongs_to :user_role
      t.timestamps
    end

    add_index :user_roles, [:roleable_id, :roleable_type]
    add_index :user_roles, [:roleable_id, :roleable_type, :name]
    add_index :user_role_mappings, [:user_id]
    add_index :user_role_mappings, [:user_role_id]

    public_access = UserRole.create(:name => "public", :display_name => "Public Access", :priority => 600)
  end

  def self.down
    drop_table :user_roles
    drop_table :user_role_mappings
  end
end
