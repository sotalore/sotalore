ActiveAdmin.register Comment do
  includes :subject, :actual_author

  actions :index, :show, :destroy

  index do
    selectable_column
    id_column
    column :subject
    column :author
    column :body
    column :created_at
    actions
  end

  filter :author_id

end
