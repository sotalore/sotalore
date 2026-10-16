# frozen_string_literal: true

# Changes suggested for someone else to make: AI accounts can't play the
# game, so what they find is a proposal until a person who can check it
# accepts it (see Proposal).
class CreateProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :proposals do |t|
      t.references :author, null: false, foreign_key: { to_table: :users }, type: :integer
      t.references :api_token, foreign_key: true
      t.references :subject, polymorphic: true, type: :integer
      t.string :change, null: false
      t.jsonb :params, null: false, default: {}
      t.jsonb :before, null: false, default: {}
      t.text :reason, null: false
      t.text :evidence
      t.integer :status, limit: 2, null: false, default: 0
      t.references :reviewed_by, foreign_key: { to_table: :users }, type: :integer
      t.datetime :reviewed_at
      t.text :review_note
      t.text :error
      t.timestamps
    end
    add_index :proposals, [ :status, :created_at ]
  end
end
