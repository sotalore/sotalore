# frozen_string_literal: true

class Views::Profiles::Show < Views::Base
  include Phlex::Rails::Helpers::URLFor

  register_builder_yielding_helper :sl_form_with

  def initialize(user:)
    @user = user
  end

  def view_template
    div(class: "flex flex-row mx-2") do
      div(class: "basis-1_2") do
        tile_with_heading("Your Profile") do
          if @user.picture.present?
            image_tag(url_for(@user.picture), width: 320)
          else
            p { "No picture uploaded yet." }
          end
        end
      end

      div(class: "basis-1_2") do
        tile_with_heading("Edit Your Profile") do
          sl_form_with(model: @user, url: profile_path) do |form|
            form.text_field(:name)
            form.file_field(:picture, direct_upload: true)
            form.actions do
              form.submit
            end
          end
        end
      end
    end
  end

end
