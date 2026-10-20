class ChangeItemsWeightToFourDecimals < ActiveRecord::Migration[8.1]
  # The game plugin gives weights to 4 decimals (a stack's weight divided by
  # its size, like 0.0525), where the game's own UI shows 2. The precision
  # grows with the scale, so weights can still reach 9999.
  def up
    change_column :items, :weight, :decimal, precision: 8, scale: 4
  end

  # Rounds weights back to 2 decimals.
  def down
    change_column :items, :weight, :decimal, precision: 6, scale: 2
  end
end
