# frozen_string_literal: true

class Views::Posts::Base < Views::Base

  def page_nav(post)
    div(class: "PageLinks") do
      div(class: "PageLinks-link") { link_to("all posts", posts_path) }

      if (parent = post.parent)
        div(class: "PageLinks-link") { link_to(parent, parent) }
      end
    end
  end

end
