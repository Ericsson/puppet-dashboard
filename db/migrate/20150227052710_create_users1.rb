class CreateUsers1 < ActiveRecord::Migration
  def up
    create_table :users do |t|
    t.string :first_name, :null => false
    t.string :last_name
    t.integer :user_type, :null => false, :default => 0
    t.string :username
    t.string :email
    t.string :crypted_password, :limit => 40
    t.string :salt, :limit => 40
    t.string :remember_token
    t.datetime :remember_token_expires_at
    t.timestamps
    t.boolean :is_login, :default => 0
    end
  end

  def down
    drop_table :users
  end
end
