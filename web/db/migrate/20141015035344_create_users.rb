class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :username
      t.string :firstname
      t.string :lastname
      t.string :password_hash
      t.string :password_salt
      t.string :email
      t.boolean :active
      t.boolean :admin
    end
  end
end
