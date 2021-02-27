ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do

    columns do
      column do
        panel "Recent Users" do
          table_for User.order(id: :desc).limit(10).map do |user|
            column("Name") { |user| link_to(user.name, admin_user_path(user)) }
            column("email", :email)
            column("Created", :created_at)
          end
        end
      end

      column do
        panel "Avatar and Skills Activity" do
          para "Avatars Last Week: #{Avatar.where('created_at > ?', 1.week.ago).count}."
          para "Skills Last Week: #{EarnedSkill.where('updated_at > ?', 1.week.ago).count}."
          para "Avatars Last Month: #{Avatar.where('created_at > ?', 1.month.ago).count}."
          para "Skills Last Month: #{EarnedSkill.where('updated_at > ?', 1.month.ago).count}."
        end
      end
    end
  end

end
