# frozen_string_literal: true

class Views::Scenes::Show < Views::Scenes::Base

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
      render Components::Finds::ForScene.new(scene: @scene) if policy(:finds).show?
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
        # Set apart from the images, when there are any.
        div(class: ("mt-8 border-t-2 border-gray-200 pt-4" if have_images)) do
          upload_form
        end
      end
    end
  end

  def image_gallery
    div(class: "grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4 items-center",
        data: { controller: "lightbox", "lightbox-options-value": '{"selector": ".gallery-image"}' }) do
      @scene.images.each do |image|
        div(id: dom_id(image), class: "inline-block relative") do
          a(href: rails_blob_path(image), class: "gallery-image") do
            image_tag(image.variant(:preview), class: "h-auto max-w-full rounded-md drop-shadow-lg")
          end

          if policy(@scene).destroy?
            div(class: "absolute bottom-1 right-1 opacity-30 hover:opacity-100") do
              destroy_icon_to(scene_path(attachment_id: image.id), size: :xs)
            end
          end
        end
      end
    end
  end

  # Takes pasted screenshots as well as chosen files, previewing them before
  # they're uploaded (image_upload_controller.js).
  def upload_form
    actions = "paste@window->image-upload#paste turbo:submit-end->image-upload#uploaded turbo:morph@document->image-upload#morphed"
    sl_form_with(model: @scene, data: { controller: "image-upload", action: actions }) do |form|
      form.file_field(:images, multiple: true, direct_upload: true, accept: "image/*", label: "Upload images",
                      hint: "Choose images, or paste a screenshot.",
                      data: { image_upload_target: "input", action: "image-upload#choose" })

      div(class: "grid grid-cols-2 md:grid-cols-3 gap-4 mb-4", data: { image_upload_target: "previews" })
      template(data: { image_upload_target: "template" }) { upload_preview }
      p(class: "text-sm text-red-600 dark:text-red-400", hidden: true, data: { image_upload_target: "message" })

      form.actions do
        button(type: "button", hidden: true, **add_button_css_classes(style: "default"),
               data: { image_upload_target: "paste", action: "image-upload#pasteFromClipboard" }) { "Paste" }
        button(type: "button", hidden: true, **add_button_css_classes(style: "default"),
               data: { image_upload_target: "clear", action: "image-upload#clear" }) { "Clear" }
        form.submit("Upload", data: { image_upload_target: "submit" })
      end
    end
  end

  def upload_preview
    figure(class: "m-0") do
      img(class: "h-auto max-w-full rounded-md drop-shadow-lg")
      figcaption(class: "mt-1 flex flex-row items-start gap-x-1 text-xs") do
        span(class: "grow min-w-0 truncate", data: { name: true })
        span(class: "shrink-0 text-grey-500", data: { size: true })
        button(type: "button", aria: { label: "Remove this image" }, title: "Remove", **add_button_css_classes(style: "dangerOutline", size: :xs),
               data: { action: "image-upload#remove" }) { render_icon(:trash, size: :xs) }
      end
    end
  end

  def comments_section
    tile_with_heading("Comments", class: "col-span-6 md:col-span-3") do
      render Components::Comments::Subject.new(subject: @scene)
    end
  end

end
