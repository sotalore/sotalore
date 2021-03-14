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

  filter :author_id_present, as: :boolean

  batch_action :delete do |ids|
    batch_action_collection.find(ids).each do |comment|
      comment.destroy
    end
    redirect_to collection_path, alert: "The comments have been deleted."
  end

end
