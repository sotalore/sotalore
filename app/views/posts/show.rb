# frozen_string_literal: true

class Views::Posts::Show < Views::Posts::Base

  def initialize(post:)
    @post = post
  end

  def view_template
    page_title(@post.title)

    layout_main_content do
      page_nav(@post)

      render Components::Posts::Card.new(post: @post)

      div(class: "text-right ml-4 mr-2") do
        link_to("all posts", posts_path)
      end
    end
  end

end
