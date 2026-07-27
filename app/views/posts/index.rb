# frozen_string_literal: true

class Views::Posts::Index < Views::Posts::Base

  def initialize(posts:)
    @posts = posts
  end

  def view_template
    page_title("Posts")

    layout_main_content do
      div(class: "flex items-center") do
        h2(class: "m-2 grow") { "Posts" }
        div(class: "shrink") do
          new_button_to("New Site Post", new_post_path) if policy(Post).new?
        end
      end

      @posts.each do |post|
        render Components::Posts::Card.new(post: post, truncate: true)
      end
    end
  end

end
