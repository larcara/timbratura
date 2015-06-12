class AddTypeToClocks < ActiveRecord::Migration
  def change
    add_column :clocks, :tipo, :string
  end
end
