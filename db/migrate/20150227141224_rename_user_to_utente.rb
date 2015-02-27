class RenameUserToUtente < ActiveRecord::Migration
  def change
    remove_column :clocks, :user
    add_column :clocks, :user_id, :integer
  end
end
