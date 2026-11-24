# frozen_string_literal: true

# Confirming a scene's deletion: what goes with it. Refused while other
# scenes are inside it (their parent), as they'd be left without one.
class Views::Adm::Scenes::Delete < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(scene:)
    @scene = scene
  end

  def view_template
    div(class: 'm-2 p-4 max-w-prose bg-white dark:bg-grey-800') do
      h1(class: 'text-2xl font-bold') { "Delete #{@scene.name}?" }
      children = @scene.children.by_name.to_a
      children.any? ? refused(children) : confirm
    end
  end

  private

  def refused(children)
    p(class: 'my-4') do
      plain "It can't be deleted while other scenes are inside it: "
      plain children.map(&:name).join(', ')
      plain '. Give them another parent first, or delete them.'
    end
    a(href: adm_scene_path(@scene), class: 'Link') { "Back to #{@scene.name}" }
  end

  def confirm
    gone = losses
    p(class: 'my-4') do
      plain 'This deletes the scene for good, and with it '
      plain gone.any? ? "#{gone.to_sentence}." : 'nothing else: it has no finds, images, notes, posts or comments.'
      plain ' A finds import that names it later shows it as a scene not on the site.'
    end
    div(class: 'flex flex-row items-center gap-4') do
      button_to('Delete scene', adm_scene_path(@scene), method: :delete, class: 'Button Button--sm Button--danger',
                form: { class: 'inline-block' })
      a(href: adm_scene_path(@scene), class: 'Link') { 'Cancel' }
    end
  end

  def losses
    {
      'found item' => @scene.scene_finds.count, 'creature' => @scene.scene_creatures.count,
      'gathering node' => @scene.scene_nodes.count, 'ignored sighting' => @scene.ignored_sightings.count,
      'image' => @scene.images.count, 'note' => @scene.notes.count,
      'post' => @scene.posts.count, 'comment' => @scene.comments.count
    }.filter_map { |noun, n| "#{n} #{noun.pluralize(n)}" if n.positive? }
  end

end
