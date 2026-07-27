# frozen_string_literal: true

class Views::Posts::New < Views::Posts::Base

  def initialize(post:)
    @post = post
  end

  def view_template
    layout_main_content do
      page_nav(@post)

      heading = @post.parent ? "New Post For: #{@post.parent}" : "New General Post"
      tile_with_heading(heading) do
        render Views::Posts::Form.new(post: @post)
      end
    end
  end

end
