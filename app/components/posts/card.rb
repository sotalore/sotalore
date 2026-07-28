# frozen_string_literal: true

class Components::Posts::Card < Components::Base
  include Phlex::Rails::Helpers::TimeAgoInWords
  include Phlex::Rails::Helpers::SimpleFormat

  def initialize(post:, truncate: false)
    @post = post
    @truncate = truncate
  end

  def view_template
    editable = policy(@post).edit?
    destroyable = policy(@post).destroy?

    tile do
      div(class: "Tile-heading") do
        h3 do
          if @post.parent
            div(class: "inline-block text-lg mr-1") { "#{@post.parent}:" }
          end
          link_to(@post.title, @post)
        end

        div(class: "grow text-left") { subheading }

        if editable || destroyable
          div(class: "Tile-controls") do
            edit_icon_to(edit_post_path(@post)) if editable
            destroy_icon_to(post_path(@post)) if destroyable
          end
        end
      end

      tile_body do
        if @truncate
          simple_format(@post.truncated)
          link_to(@post) { span(class: "text-sm") { "read more" } }
        else
          raw(@post.content.to_s)
        end
      end
    end
  end

  private

  def subheading
    span(class: "text-sm text-gray-600 ml-2") do
      plain "by #{@post.author.name} "
      plain time_ago_in_words(@post.created_at)
      plain " ago"
    end
  end

end
