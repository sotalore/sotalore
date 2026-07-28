# frozen_string_literal: true

class Views::Avatars::Edit < Views::Base

  def initialize(avatar:)
    @avatar = avatar
  end

  def view_template
    layout_main_content(size: :sm) do
      tile_with_heading('Edit Avatar') do
        render Views::Avatars::Form.new(avatar: @avatar)
      end
    end
  end

end
