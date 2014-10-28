class CreateUserFiles < ActiveRecord::Migration
  def change
    create_table :user_files do |t|
      t.string :filename
      t.string :filepath
      t.string :filehash
      t.boolean :public
      t.belongs_to :user
    end
  end
end
