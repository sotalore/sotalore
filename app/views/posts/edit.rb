# frozen_string_literal: true

class Views::Posts::Edit < Views::Posts::Base

  def initialize(post:)
    @post = post
  end

  def view_template
    layout_main_content do
      page_nav(@post)

      tile_with_heading("Edit Post") do
        render Views::Posts::Form.new(post: @post)
      end
    end
  end

end
