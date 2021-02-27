ActiveAdmin.register Avatar do
  includes :user

  actions :index, :show

  index do
    id_column
    column :name
    column :created_at
  end


  show do
    default_main_content
    table_for avatar.skills do |skill|
      column(:school) { |skill| skill.skill.school }
      column(:skill) { |skill| skill.skill.name }
      column(:current)
      column(:target)
      column(:updated_at)
    end
  end

end
