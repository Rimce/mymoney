class AddCategoryToDebts < ActiveRecord::Migration
  def change
    add_reference :debts, :category, index: true, foreign_key: true, null: false
  end
end
