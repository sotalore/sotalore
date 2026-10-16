# frozen_string_literal: true

# AI accounts and their API tokens. An AI account is a user flagged as a bot:
# it has no password and can't sign in through the site, only use tokens an
# admin issues for it. A token is stored as a SHA-256 digest; the token
# itself is shown once, when it's made.
class CreateApiTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :bot, :boolean, null: false, default: false

    create_table :api_tokens do |t|
      t.references :user, null: false, foreign_key: true, type: :integer
      t.references :created_by, null: false, foreign_key: { to_table: :users }, type: :integer
      t.string :name, null: false
      t.string :token_digest, null: false, index: { unique: true }
      t.string :scopes, array: true, null: false, default: []
      t.datetime :expires_at
      t.datetime :last_used_at
      t.datetime :revoked_at
      t.timestamps
    end
  end
end
