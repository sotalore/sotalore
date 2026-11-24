# frozen_string_literal: true

# A scene's ADM page, where it's managed: its details (including those the
# public page doesn't show), its finds, its gallery and its private notes.
class Views::Adm::Scenes::Show < Views::Base

  SECTION_CSS = 'mt-6 mb-2 text-lg font-bold'

  def initialize(scene:)
    @scene = scene
  end

  def view_template
    div(class: 'm-2 p-4 bg-white dark:bg-grey-800') do
      header
      details
      finds
      gallery
      notes
    end
  end

  private

  def header
    div(class: 'flex flex-row flex-wrap items-baseline gap-x-4') do
      h1(class: 'text-2xl font-bold') { @scene.name }
      a(href: scene_path(@scene), target: '_blank', rel: 'noopener', class: 'Link text-sm') { 'Public page' }
      a(href: adm_scenes_path, class: 'Link text-sm') { 'All scenes' }
    end
    div(class: 'my-2 flex flex-row gap-2') do
      a(href: edit_adm_scene_path(@scene), class: 'Button Button--sm Button--primary') { 'Edit' }
      a(href: delete_adm_scene_path(@scene), class: 'Button Button--sm Button--dangerOutline') { 'Delete scene' }
    end
  end

  def details
    h2(class: SECTION_CSS) { 'Details' }
    dl(class: 'grid grid-cols-[max-content_1fr] gap-x-4 gap-y-1 text-sm') do
      detail('Game name') { @scene.game_name || em { 'not linked yet (a finds import links it)' } }
      detail('Tier') { @scene.level ? "#{@scene.level}#{'+' if @scene.level_plus}" : '–' }
      detail('Type') { @scene.scene_type || '–' }
      detail('Region') { @scene.region || '–' }
      detail('PvP') { @scene.pvp? ? 'yes' : 'no' }
      detail('Parent') { @scene.parent ? a(href: adm_scene_path(@scene.parent), class: 'Link') { @scene.parent.name } : '–' }
      detail('Inside it') { children }
      detail('Map id') { @scene.sota_map_id&.to_s || '–' }
      detail('Map point in parent') { @scene.sota_map_parent_poi_id&.to_s || '–' }
    end
  end

  def detail(term, &)
    dt(class: 'font-bold') { term }
    dd(&)
  end

  def children
    kids = @scene.children.by_name.to_a
    return plain('–') if kids.empty?
    kids.each_with_index do |kid, i|
      plain ', ' if i.positive?
      a(href: adm_scene_path(kid), class: 'Link') { kid.name }
    end
  end

  def finds
    h2(class: SECTION_CSS) { 'Finds' }
    p(class: 'text-sm') do
      if @scene.finds_imported_at
        plain 'Last imported '
        time_ago_tag @scene.finds_imported_at
        plain ': '
        plain [ counted(@scene.scene_finds.count, 'item'), counted(@scene.scene_creatures.count, 'creature'),
                counted(@scene.scene_nodes.count, 'gathering node') ].join(', ')
        plain '. The public page lists them.'
      else
        plain 'Never imported. Play the scene and upload its finds file.'
      end
    end
  end

  def counted(n, noun)
    "#{n} #{noun.pluralize(n)}"
  end

  def gallery
    images = @scene.images.includes(:blob).to_a
    h2(class: SECTION_CSS) { "Gallery (#{images.size})" }
    if images.any?
      uploaders = User.where(id: images.filter_map { custom(_1)['uploaded_by_id'] }).index_by { _1.id.to_s }
      div(class: 'grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4 items-start',
          data: { controller: 'lightbox', 'lightbox-options-value': '{"selector": ".gallery-image"}' }) do
        images.each { image_card(_1, uploaders) }
      end
    end
    div(class: ('mt-6 border-t-2 border-gray-200 pt-4' if images.any?)) { upload_form }
  end

  def image_card(image, uploaders)
    figure(id: dom_id(image), class: 'm-0') do
      a(href: rails_blob_path(image), class: 'gallery-image') do
        image_tag(image.variant(:preview), class: 'h-auto max-w-full rounded-md drop-shadow-lg')
      end
      figcaption(class: 'mt-1 flex flex-row items-start gap-x-2 text-xs text-grey-500') do
        span(class: 'grow') { image_caption(image, uploaders) }
        destroy_icon_to(adm_scene_image_path(@scene, image), size: :xs)
      end
    end
  end

  # Who added it and when it was taken, if the API recorded them.
  def image_caption(image, uploaders)
    uploader = uploaders[custom(image)['uploaded_by_id']]
    taken_at = parse_time(custom(image)['taken_at'])
    plain "Added #{l(image.created_at, format: :short)}"
    plain " by #{uploader.name}" if uploader
    plain ", taken #{l(taken_at, format: :short)}" if taken_at
  end

  def parse_time(value)
    Time.iso8601(value) if value
  rescue ArgumentError
    nil
  end

  def custom(image)
    image.blob.metadata['custom'] || {}
  end

  # Takes pasted screenshots as well as chosen files, previewing them before
  # they're uploaded (image_upload_controller.js).
  def upload_form
    actions = 'paste@window->image-upload#paste turbo:submit-end->image-upload#uploaded turbo:morph@document->image-upload#morphed'
    sl_form_with(model: @scene, url: adm_scene_images_path(@scene), method: :post,
                 data: { controller: 'image-upload', action: actions }) do |form|
      form.file_field(:images, multiple: true, direct_upload: true, accept: 'image/*', label: 'Upload images',
                      hint: 'Choose images, or paste a screenshot.',
                      data: { image_upload_target: 'input', action: 'image-upload#choose' })

      div(class: 'grid grid-cols-2 md:grid-cols-3 gap-4 mb-4', data: { image_upload_target: 'previews' })
      template(data: { image_upload_target: 'template' }) { upload_preview }
      p(class: 'text-sm text-red-600 dark:text-red-400', hidden: true, data: { image_upload_target: 'message' })

      form.actions do
        button(type: 'button', hidden: true, **add_button_css_classes(style: 'default'),
               data: { image_upload_target: 'paste', action: 'image-upload#pasteFromClipboard' }) { 'Paste' }
        button(type: 'button', hidden: true, **add_button_css_classes(style: 'default'),
               data: { image_upload_target: 'clear', action: 'image-upload#clear' }) { 'Clear' }
        form.submit('Upload', data: { image_upload_target: 'submit' })
      end
    end
  end

  def upload_preview
    figure(class: 'm-0') do
      img(class: 'h-auto max-w-full rounded-md drop-shadow-lg')
      figcaption(class: 'mt-1 flex flex-row items-start gap-x-1 text-xs') do
        span(class: 'grow min-w-0 truncate', data: { name: true })
        span(class: 'shrink-0 text-grey-500', data: { size: true })
        button(type: 'button', aria: { label: 'Remove this image' }, title: 'Remove',
               **add_button_css_classes(style: 'dangerOutline', size: :xs),
               data: { action: 'image-upload#remove' }) { render_icon(:trash, size: :xs) }
      end
    end
  end

  # Private transcripts the companion adds through the API, for the agent that
  # writes the scene's narrative. Never shown on the public page.
  def notes
    notes = @scene.notes.to_a
    h2(class: SECTION_CSS) { "Notes (#{notes.size})" }
    if notes.empty?
      p(class: 'text-sm') { 'None yet. The companion adds them as transcripts of what was said while playing here.' }
      return
    end
    notes.each do |note|
      div(id: dom_id(note), class: 'mb-4 max-w-prose border-b border-gray-200 pb-4 last:border-b-0') do
        div(class: 'mb-1 flex flex-row items-center gap-x-2 text-sm text-grey-500') do
          span(class: 'grow') { note_heading(note) }
          destroy_icon_to(adm_scene_note_path(@scene, note), size: :xs)
        end
        p(class: 'whitespace-pre-line') { note.text }
      end
    end
  end

  def note_heading(note)
    plain l(note.recorded_at, format: :long)
    plain Kernel.format(', %d:%02d long', *note.duration.divmod(60)) if note.duration
    plain " (#{note.transcriber})" if note.transcriber
  end

end
