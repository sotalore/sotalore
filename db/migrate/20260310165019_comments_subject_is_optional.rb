# frozen_string_literal: true

class CommentsSubjectIsOptional < ActiveRecord::Migration[8.1]
  def change
    up_only do
      execute <<~SQL
        update comments
        set subject_id = null, subject_type = null
        where subject_type = 'TopPost'
      SQL
    end
  end
end
