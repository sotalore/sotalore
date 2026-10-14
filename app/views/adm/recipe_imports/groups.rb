# frozen_string_literal: true

# The export's groups beside the site items holding their keys, with what
# syncing members would do (see GameGroupSync).
class Views::Adm::RecipeImports::Groups < Views::Adm::RecipeImports::Base

  STATUS_LABELS = {
    'differs'  => 'Differ',
    'unmapped' => 'Not on the site',
    'in_sync'  => 'In sync',
    'all'      => 'All',
  }.freeze

  def initialize(import:, rows:, status:, counts:)
    @import = import
    @rows = rows
    @status = status
    @counts = counts
  end

  def view_template
    div(class: 'm-2 bg-white dark:bg-grey-800') do
      import_header(@import, :groups)
      div(class: 'p-4') do
        intro
        status_buttons
        if @rows.empty?
          notice_success('Nothing here.')
        else
          rows_table
        end
      end
    end
  end

  private

  def intro
    div(class: 'mb-4 max-w-prose') do
      p(class: 'mb-1') do
        plain 'The groups this export\'s recipes take any member of, beside the site items with their keys. '
        plain 'A site '
        strong { 'group' }
        plain ' can get all the members the game lists, creating the ones the site doesn\'t know (often '
        plain 'looted items); when the game lists every member, ones it doesn\'t list can be removed. A '
        strong { 'category' }
        plain ' gets the members the site knows as examples.'
      end
      p do
        plain 'Groups not on the site yet are resolved on Unknown items. The game lists at most 30 '
        plain 'members, and for big groups only what the character carries, so a partial list is never '
        plain 'used to remove anything.'
      end
    end
  end

  def status_buttons
    div(class: 'flex flex-row flex-wrap gap-2 mb-4') do
      STATUS_LABELS.each do |status, label|
        count = status == 'all' ? @counts.values.sum : @counts[status].to_i
        a(href: groups_adm_recipe_import_path(@import, status: status),
          class: "Button Button--sm Button--#{status == @status ? 'primary' : 'default'}") { "#{label} (#{count})" }
      end
    end
  end

  def rows_table
    table(class: 'table-auto w-full text-sm') do
      thead do
        tr(class: 'border-b-2 border-grey-400 text-left') do
          th { 'Game group' }
          th { 'Site item' }
          th { 'Changes' }
          th
        end
      end
      tbody { @rows.each { |row| group_row(row) } }
    end
  end

  def group_row(row)
    game = row.game_group
    tr(class: 'align-top border-b border-grey-200 dark:border-grey-700') do
      td(class: 'pr-2') do
        div(class: 'font-bold') { game.name }
        div(class: 'text-xs text-grey-500') do
          plain "#{game.key} · "
          plain game.complete? ? "all #{game.members.size} members listed" :
                                 "#{game.members.size} of #{game.choice_count} members listed"
        end
      end
      td(class: 'pr-2') do
        if row.mapped?
          a(href: item_path(row.item), class: 'Link Link--primary') { row.item.name }
          div(class: 'text-xs text-grey-500') { "#{row.item.kind}, #{row.item.members.size} #{member_noun(row, row.item.members.size)}" }
        else
          a(href: items_adm_recipe_import_path(@import), class: 'Link') { 'see Unknown items' }
        end
      end
      td(class: 'pr-2') { changes(row) }
      td(class: 'whitespace-nowrap') { actions(row) }
    end
  end

  def member_noun(row, count)
    (row.item.category? ? 'example' : 'member').pluralize(count)
  end

  def changes(row)
    return unless row.mapped?
    if row.status == 'in_sync'
      span(class: 'text-grey-500') { 'in sync' }
      return
    end

    change_line('Add', row.add.map(&:first).map(&:name))
    change_line('Create and add', row.create.map(&:first))
    change_line('Not in the game', row.remove.map(&:name))
    if row.conflicts.any?
      change_line('Can\'t add', row.conflicts.map { |name, item| "#{name} (the site has #{item.kind_label})" })
    end
  end

  def change_line(label, names)
    return if names.empty?

    div(class: 'mb-1') do
      strong { "#{label} (#{names.size}): " }
      plain names.join(', ')
    end
  end

  def actions(row)
    return unless row.mapped?

    if row.add.any? || row.create.any?
      count = row.add.size + row.create.size
      confirm = "Create #{row.create.size} new #{'item'.pluralize(row.create.size)}?" if row.create.any?
      post_button("Add #{count} #{member_noun(row, count)}", add_group_members_adm_recipe_import_path(@import),
                  style: 'primary', params: { key: row.key }, confirm: confirm)
    end
    if row.remove.any?
      whitespace
      post_button("Remove #{row.remove.size}", remove_group_members_adm_recipe_import_path(@import),
                  style: 'danger', params: { key: row.key },
                  confirm: "Remove #{row.remove.map(&:name).to_sentence} from #{row.item.name}?")
    end
  end

end
