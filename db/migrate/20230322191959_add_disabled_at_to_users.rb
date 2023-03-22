class AddDisabledAtToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :disabled_at, :timestamp
    add_column :users, :last_request_at, :timestamp
  end
end
