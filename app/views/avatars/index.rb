# frozen_string_literal: true

class Views::Avatars::Index < Views::Base

  def initialize(avatars:, avatar: nil)
    @avatars = avatars
    @avatar = avatar
  end

  def view_template
    layout_main_content(size: :sm) do
      tile_with_heading('Your Avatars') do
        if current_user.not_null?
          if @avatars
            div(class: "grid sm:grid-cols-1 md:grid-cols-2 gap-1") do
              @avatars.each do |avatar|
                next unless avatar.persisted?

                div(class: 'flex items-center gap-x-2') do
                  plain avatar.name
                  flair_info('default') if avatar.is_default
                end
                div(class: "flex flex-row md:justify-end items-center gap-x-1") do
                  default_button_to('View Skills', avatar_skills_path(avatar))
                  edit_icon_to(edit_avatar_path(id: avatar), size: :md)
                  destroy_icon_to(avatar_path(id: avatar), size: :md)
                end
              end
            end
          else
            p { "You have no Avatars yet, add one below!" }
          end

          if @avatars && @avatars.none?(&:is_default)
            notice_info do
              plain "You have no default avatar. Edit an avatar, and you can make them the "
              strong { "default" }
              plain " for things like the skills calculator."
            end
          end
        else
          p do
            plain "If you sign-up for an account in SotA Lore, you can create avatars and "
            plain "track their skill levels on the skills calculator. There isn't much "
            plain "beyond that functionality, at the moment."
          end

          p do
            plain "Creating an account is simple, but it does require an email and password. "
            plain "The only emails the site sends is for resetting a lost password."
          end

          p do
            plain "You can "
            default_button_to('sign up here.', new_user_registration_path)
          end
        end
      end

      if current_user.not_null?
        tile_with_heading('Add An Avatar') do
          render Views::Avatars::Form.new(avatar: @avatar || Avatar.new)
        end
      end
    end
  end

end
