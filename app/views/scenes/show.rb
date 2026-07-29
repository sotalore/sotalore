# frozen_string_literal: true

class Views::Scenes::Show < Views::Scenes::Base

  register_builder_yielding_helper :sl_form_with

  def initialize(scene:)
    @scene = scene
  end

  def view_template
    page_title(@scene.name)

    tile do
      tile_heading(@scene.name) do
        default_button_to("All", scenes_path)
        edit_button_to("Edit", edit_scene_path(@scene)) if policy(@scene).edit?
        new_button_to("Add Post", new_scene_post_path(@scene)) if policy(Post).create?
      end

      tile_body do
        div(class: "grid grid-cols-2 gap-4") do
          div(class: "col-span-2 md:col-span-1") { info_callout }
          div(class: "col-span-2 md:col-span-1") { map_links }
        end
      end
    end

    div(class: "grid grid-cols-6") do
      posts_section if @scene.posts.any?
      gallery_section if policy(@scene).edit? || @scene.images.any?
      comments_section
    end
  end

  private

  def info_callout
    div(class: "Callout Callout-primary") do
      if @scene.level
        strong { scene_level(@scene) }
        whitespace
      end

      if @scene.pvp?
        strong { "PVP" }
        whitespace
      end

      if @scene.scene_type
        em { @scene.scene_type }
        whitespace
      end

      if @scene.region
        plain "in"
        whitespace
        strong { @scene.region }
        whitespace
      end

      parent = @scene.parent
      if parent && !parent.overworld?
        raw(safe("&mdash; nested in:"))
        while parent && !parent.overworld?
          whitespace
          link_to(parent.name, parent)
          parent = parent.parent
        end
      end
    end
  end

  def map_links
    p do
      link_to(@scene.sota_map_url, target: "_blank", class: "inline-flex items-center gap-x-1") do
        plain "View map of "
        strong { @scene.name }
        whitespace
        render Components::Icons::ExternalLink.new
      end
    end

    parent, scene = @scene.parent, @scene
    while parent && scene.has_parent_location_info?
      p do
        link_to(scene.sota_map_in_parent_url, target: "_blank", class: "inline-flex items-center gap-x-1") do
          plain "View location of "
          strong { scene.name }
          plain " in "
          strong { parent.name }
          whitespace
          render Components::Icons::ExternalLink.new
        end
      end
      parent, scene = parent.parent, parent
    end
  end

  def posts_section
    tile_with_heading("Post", class: "col-span-6 md:col-span-3") do
      @scene.posts.first(3).each do |post|
        render Components::Posts::Card.new(post: post, truncate: true)
      end
      link_to("View all posts", scene_posts_path(@scene))
    end
  end

  def gallery_section
    have_images = @scene.images.any?
    can_upload = policy(@scene).edit?

    tile_with_heading("Gallery", class: "col-span-6 md:col-span-3") do
      if have_images
        image_gallery
      end

      if can_upload
        div(class: "mt-8 border-t-2 border-gray-200 pt-4") do
          upload_form
        end
      end
    end
  end

  def image_gallery
    div(class: "grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4 items-center",
        data: { controller: "lightbox", "lightbox-options-value": '{"selector": ".gallery-image"}' }) do
      @scene.images.each do |image|
        turbo_frame_tag(image, class: "inline-block relative") do
          a(href: rails_blob_path(image), class: "gallery-image") do
            image_tag(image.variant(:preview), class: "h-auto max-w-full rounded-md drop-shadow-lg")
          end

          if policy(@scene).destroy?
            div(class: "absolute bottom-1 right-1 opacity-30 hover:opacity-100") do
              destroy_icon_to(scene_path(attachment_id: image.id), size: :xs, data: { turbo_method: :delete, turbo_confirm: "Are you sure?" })
            end
          end
        end
      end
    end
  end

  def upload_form
    sl_form_with(model: @scene) do |form|
      form.file_field(:images, multiple: true, direct_upload: true, label: "Upload images")
      form.actions do
        form.submit("Upload")
      end
    end
  end

  def comments_section
    tile_with_heading("Comments", class: "col-span-6 md:col-span-3") do
      render Components::Comments::Subject.new(subject: @scene)
    end
  end

end
