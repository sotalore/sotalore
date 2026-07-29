# frozen_string_literal: true

class Views::Adm::Users::Index < Views::Base

  register_value_helper :request

  def initialize(users:)
    @users = users
  end

  def view_template
    div(class: "m-2 bg-white") do
      paginate @users

      table(class: "table-auto") do
        thead do
          tr(class: "border-b-2 border-grey-400") do
            th(class: "text-right") { sort_link "ID", :id }
            th { "Name" }
            th(class: "text-sm") { "Email" }
            th { "Disabled" }
            th { "Roles" }
            th(class: "text-center text-sm") { sort_link "Last Request", :last_request_at }
            th(class: "text-center text-sm") { "Created" }
            th(class: "text-center text-sm") { "Updated" }
            th(class: "text-center text-sm") { "Last Sign-In" }
            th(class: "text-center text-sm") { "Last IP" }
            th(class: "text-right") { raw safe("&nbsp;") }
          end
        end

        tbody do
          @users.each do |user|
            tr(class: "hover:bg-grey-300") do
              td(class: "text-right") { user.id }
              td { user.name }
              td(class: "text-sm") { user.email }
              td(class: "text-sm") { disabled_flair(user.disabled_at) if user.disabled_at }
              td { user.roles.join(",") }
              td(class: "text-center text-sm") { time_ago_tag user.last_request_at }
              td(class: "text-center text-sm") { time_ago_tag user.created_at }
              td(class: "text-center text-sm") { time_ago_tag user.updated_at }
              td(class: "text-center text-sm") { time_ago_tag user.last_sign_in_at }
              td(class: "text-center text-sm") { user.last_sign_in_ip }
              td(class: "text-right") { edit_icon_to(edit_adm_user_path(user)) }
            end
          end
        end
      end

      paginate @users
    end
  end

  private

  def disabled_flair(time)
    flair_danger(view_context.local_time_ago(time))
  end

  def sort_link(name, field)
    path = request.path
    asc_val = "#{field}_asc"
    desc_val = "#{field}_desc"
    current_sort = request.params[:sort]

    if current_sort == asc_val
      link_to("#{path}?sort=#{desc_val}", class: 'text-inherit underline') { sort_link_label(name, "&#8963;") }
    elsif current_sort == desc_val
      link_to("#{path}?sort=#{asc_val}", class: 'text-inherit underline') { sort_link_label(name, "&#8964;") }
    else
      link_to(name, "#{path}?sort=#{asc_val}", class: 'text-inherit underline')
    end
  end

  def sort_link_label(name, entity)
    span(class: 'bold') do
      plain(name)
      raw(safe("&nbsp;#{entity}"))
    end
  end

end
