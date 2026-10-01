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
          plain 'Item names in this export that the site doesn\'t know. Recipes using them are blocked '
          plain 'until each is resolved. '
          strong { 'Rename' }
          plain ' gives an existing item the game\'s name (keeping its old name as an alias); '
          strong { 'Alias' }
          plain ' keeps the site name; '
          strong { 'Create' }
          plain ' adds a new item. Suggestions the game also uses by name are distinct items and can\'t be chosen.'
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
          plain [ ('tool' if unknown.as_tool), ('made by a recipe' if unknown.as_result) ].compact.join(', ')
        end
      end
      td(class: 'text-right') do
        a(href: adm_recipe_import_path(@import, item: unknown.name), class: 'Link') { unknown.entry_count.to_s }
      end
      td { suggestions(unknown) }
      td do
        div(class: 'mb-2') do
          resolve_button('Create new item', unknown, 'create', style: 'primary')
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
        if suggestion.usable?
          resolve_button('Rename', unknown, 'rename', item_id: suggestion.item.id, style: 'warning',
                         confirm: "Rename #{suggestion.item.name} to #{unknown.name}?")
          resolve_button('Alias', unknown, 'alias', item_id: suggestion.item.id)
        else
          span(class: 'text-xs text-grey-500') { '(also in game)' }
        end
      end
    end
  end

  # Loaded for the whole page at once.
  def suggestions_by_name
    @suggestions_by_name ||= @resolution.suggestions_for_names(@names.map(&:name))
  end

  def resolve_button(label, unknown, resolution, style: 'default', item_id: nil, confirm: nil)
    params = { name: unknown.name, resolution: resolution }
    params[:item_id] = item_id if item_id
    post_button(label, adm_recipe_import_item_resolutions_path(@import), style: style,
                params: params, confirm: confirm)
  end

  def other_item_form(unknown)
    form(action: adm_recipe_import_item_resolutions_path(@import), method: 'post',
         class: 'flex flex-row flex-wrap items-center gap-1') do
      input(type: 'hidden', name: 'authenticity_token', value: view_context.form_authenticity_token)
      input(type: 'hidden', name: 'name', value: unknown.name)
      input(type: 'text', name: 'item_name', placeholder: 'Existing item name',
            class: 'w-44 border border-grey-400 rounded px-2 py-1 text-sm dark:bg-grey-700')
      button(type: 'submit', name: 'resolution', value: 'rename', class: 'Button Button--sm Button--warning') { 'Rename' }
      button(type: 'submit', name: 'resolution', value: 'alias', class: 'Button Button--sm Button--default') { 'Alias' }
    end
  end
end
