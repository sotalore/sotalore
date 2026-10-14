# frozen_string_literal: true

class Views::Adm::RecipeImports::Items < Views::Adm::RecipeImports::Base

  def initialize(import:, names:, resolution:)
    @import = import
    @names = names
    @resolution = resolution
  end

  def view_template
    div(class: 'm-2 bg-white dark:bg-grey-800') do
      import_header(@import, :items)
      div(class: 'p-4') do
        p(class: 'mb-4 max-w-prose') do
          plain 'Items and group slots in this export that the site doesn\'t know. Recipes using them are '
          plain 'blocked until each is resolved, and resolving one records the game\'s keys for it. '
          strong { 'Rename' }
          plain ' gives an existing item the game\'s name (keeping its old name as an alias); '
          strong { 'Alias' }
          plain ' keeps the site name; '
          strong { 'Use' }
          plain ' just gives an existing item the game\'s keys, for when the site already has it under '
          plain 'another name; '
          strong { 'Create' }
          plain ' adds a new item: concrete; a group when the name stands for a complete set of items a '
          plain 'recipe will take any of ("Metal Ingot", "Pine or Maple Board"), whose members you add on its '
          plain 'page later; an archetype when which one a recipe makes depends on its ingredients ("Dagger"); '
          plain 'or a category for anything that qualifies, such as what a modification recipe acts on '
          plain '("Crafted Carpentry Equipable"). A group slot named like an existing item is created with '
          plain 'an "(any)" suffix. The likely choice is highlighted. '
          plain 'Suggestions the game also uses by name are distinct items and can\'t be chosen.'
        end

        if @names.empty?
          notice_success('Every item in this export is known.')
        else
          paginate @names
          table(class: 'table-auto w-full') do
            thead do
              tr(class: 'border-b-2 border-grey-400 text-left') do
                th { 'Game name' }
                th(class: 'text-right') { 'Recipes' }
                th { 'Similar site items' }
                th { 'Other' }
              end
            end
            tbody { @names.each { |unknown| name_row(unknown) } }
          end
          paginate @names
        end
      end
    end
  end

  private

  def name_row(unknown)
    tr(class: 'align-top border-b border-grey-200 dark:border-grey-700') do
      td do
        div(class: 'font-bold') { unknown.name }
        div(class: 'text-xs text-grey-500') do
          plain [ (group_slot_label(unknown) if unknown.group_slot?), ('tool' if unknown.as_tool),
                  ('made by a recipe' if unknown.as_result), ('modified by a recipe' if unknown.as_modified),
                  ("the site has an item named #{unknown.name}" if unknown.name_taken) ].compact.join(', ')
        end
      end
      td(class: 'text-right') do
        a(href: adm_recipe_import_path(@import, item: unknown.name), class: 'Link') { unknown.entry_count.to_s }
      end
      td { suggestions(unknown) }
      td do
        div(class: 'mb-2 flex flex-row flex-wrap gap-1') do
          if unknown.name_taken && !unknown.group_slot?
            span(class: 'text-sm') { "Rename the site's #{unknown.name} first, or use an existing item." }
          else
            unknown.kinds.each { |kind| create_button(unknown, kind) }
          end
        end
        other_item_form(unknown)
      end
    end
  end

  def suggestions(unknown)
    list = suggestions_by_name.fetch(unknown.name)
    if list.empty?
      span(class: 'text-grey-500 text-sm') { 'none' }
      return
    end
    list.each do |suggestion|
      div(class: 'flex flex-row flex-wrap items-center gap-2 mb-1') do
        a(href: item_path(suggestion.item), class: 'Link') { suggestion.item.name }
        span(class: 'text-xs text-grey-500') { suggestion.similarity.to_s }
        span(class: 'text-xs text-grey-500') { suggestion.item.kind } unless suggestion.item.concrete?
        if suggestion.usable? && !unknown.name_taken
          resolve_button('Rename', unknown, 'rename', item_id: suggestion.item.id, style: 'warning',
                         confirm: "Rename #{suggestion.item.name} to #{unknown.name}?")
          resolve_button('Alias', unknown, 'alias', item_id: suggestion.item.id)
        end
        if usable_for_keys?(unknown, suggestion.item)
          resolve_button('Use', unknown, 'use', item_id: suggestion.item.id)
        elsif !suggestion.usable?
          span(class: 'text-xs text-grey-500') { '(also in game)' }
        end
      end
    end
  end

  # Loaded for the whole page at once.
  def suggestions_by_name
    @suggestions_by_name ||= @resolution.suggestions_for_names(@names.map(&:name))
  end

  CREATE_RESOLUTIONS = Adm::RecipeImportItemResolutionsController::CREATE_KINDS.invert.freeze

  CREATE_LABELS = { 'concrete' => 'Create new item', 'group' => 'Create as group',
                    'archetype' => 'Create as archetype', 'category' => 'Create as category' }.freeze

  def group_slot_label(unknown)
    case unknown.complete
    when true  then 'group slot, all members listed'
    when false then 'group slot, some members listed'
    else 'group slot'
    end
  end

  # Use gives an item the game's keys, so it must suit them.
  def usable_for_keys?(unknown, item)
    unknown.keys.any? && unknown.keys.all? { ItemGameKey.suits?(_1, item) }
  end

  # The likely kind is the primary choice.
  def create_button(unknown, kind)
    label = CREATE_LABELS.fetch(kind)
    label = "#{label} #{unknown.new_item_name}" if unknown.new_item_name != unknown.name
    confirm = "Create #{unknown.new_item_name} as #{Item.new(kind: kind).kind_label}?" unless kind == 'concrete'
    resolve_button(label, unknown, CREATE_RESOLUTIONS.fetch(kind),
                   style: unknown.likely_kind == kind ? 'primary' : 'default', confirm: confirm)
  end

  def resolve_button(label, unknown, resolution, style: 'default', item_id: nil, confirm: nil)
    params = { name: unknown.name, resolution: resolution }
    params[:group_slot] = '1' if unknown.group_slot?
    params[:item_id] = item_id if item_id
    post_button(label, adm_recipe_import_item_resolutions_path(@import), style: style,
                params: params, confirm: confirm)
  end

  def other_item_form(unknown)
    form(action: adm_recipe_import_item_resolutions_path(@import), method: 'post',
         class: 'flex flex-row flex-wrap items-center gap-1') do
      input(type: 'hidden', name: 'authenticity_token', value: view_context.form_authenticity_token)
      input(type: 'hidden', name: 'name', value: unknown.name)
      input(type: 'hidden', name: 'group_slot', value: '1') if unknown.group_slot?
      input(type: 'text', name: 'item_name', placeholder: 'Existing item name',
            class: 'w-44 border border-grey-400 rounded px-2 py-1 text-sm dark:bg-grey-700')
      unless unknown.name_taken
        button(type: 'submit', name: 'resolution', value: 'rename', class: 'Button Button--sm Button--warning') { 'Rename' }
        button(type: 'submit', name: 'resolution', value: 'alias', class: 'Button Button--sm Button--default') { 'Alias' }
      end
      if unknown.keys.any?
        button(type: 'submit', name: 'resolution', value: 'use', class: 'Button Button--sm Button--default') { 'Use' }
      end
    end
  end
end
