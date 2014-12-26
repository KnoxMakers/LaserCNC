class AddDatetimeToUserFiles < ActiveRecord::Migration
  def change
    add_column :user_files, :created_at, :datetime
  end
end
