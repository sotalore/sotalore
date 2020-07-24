ActiveAdmin.register Planting do

  includes :user, :seed

  actions :index

  index do
    id_column
    column :user
    column :seed
    column :greenhouse
    column :location_type
    column :planted_at
    column :notes
    column :created_at
  end

end
