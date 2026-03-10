# frozen_string_literal: true

class DropTopPosts < ActiveRecord::Migration[8.1]
  def change
    up_only do
      drop_table :top_posts
    end
  end
end
