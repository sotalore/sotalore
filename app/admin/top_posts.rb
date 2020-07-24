ActiveAdmin.register TopPost do
    permit_params :key

    index do
      selectable_column
      id_column
      column :key
      column :created_at
      actions
    end

    form do |f|
      f.inputs do
        f.input :key
      end
      f.actions
    end

  end
