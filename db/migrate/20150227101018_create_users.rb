class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :username
      t.string :email
      t.string :role
      t.string :area

      t.timestamps
    end
  end
end
