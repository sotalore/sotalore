class CreateComments < ActiveRecord::Migration[5.0]
  def change
    create_table :comments do |t|
      t.references :subject, polymorphic: true, index: true
      t.references :author, index: true, foreign_key: { to_table: :users }
      t.integer    :comment_type, null: false, default: 0
      t.text       :body

      t.timestamps
    end
  end
end
