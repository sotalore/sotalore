# frozen_string_literal: true

# Previews and records the game's keys for site items (see GameKeyRecorder).
class Views::Adm::RecipeImports::GameKeys < Views::Adm::RecipeImports::Base

  STATUS_LABELS = {
    'record'    => 'To record',
    'known'     => 'Already recorded',
    'renamed'   => 'Renamed in the game',
    'elsewhere' => 'Recorded for another item',
    'ambiguous' => 'Name used for several keys',
    'unsuited'  => 'Named like an item of the wrong kind',
    'unknown'   => 'Not a site item yet',
  }.freeze

  # Listed in full, since they need someone to look at them.
  REVIEW_STATUSES = %w[ renamed elsewhere ambiguous unsuited ].freeze

  REVIEW_HINTS = {
    'renamed'   => 'Give the site item the game\'s name (keeping the old one as an alias), or add the ' \
                   'game\'s name as an alias.',
    'ambiguous' => 'If the site doesn\'t tell these apart, record each one for the same item.',
    'unsuited'  => 'These are on Unknown items, where they can get an item of the right kind.',
  }.freeze

  def initialize(import:, recorder:)
    @import = import
    @recorder = recorder
    @counts = recorder.counts
  end

  def view_template
    div(class: 'm-2 bg-white dark:bg-grey-800') do
      import_header(@import, :game_keys)
      div(class: 'p-4') do
        intro
        if @recorder.proposals.empty?
          notice_warning('This export has no game keys; it\'s from an older version of the plugin.')
        else
          status_summary
          REVIEW_STATUSES.each { |status| review_table(status) }
          to_record
        end
      end
    end
  end

  private

  def intro
    p(class: 'mb-4 max-w-prose') do
      plain 'The game has its own id for every item, and for every recipe slot that takes any '
      plain 'member of a group. Recording them lets imports match items by id instead of by '
      plain 'name, so items the game renames still match. Keys are matched to site items by name; '
      plain 'only those that lead to exactly one item of a suitable kind are recorded.'
    end
  end

  def status_summary
    ul(class: 'mb-4 text-sm') do
      STATUS_LABELS.each do |status, label|
        li do
          strong { "#{label}:" }
          plain " #{@counts[status]}"
          plain ' (see Unknown items)' if status == 'unknown' && @counts[status].positive?
        end
      end
    end
    if @counts['record'].positive?
      div(class: 'mb-4') do
        post_button("Record #{@counts['record']} #{'key'.pluralize(@counts['record'])}",
                    record_game_keys_adm_recipe_import_path(@import), style: 'primary')
      end
    end
  end

  def review_table(status)
    proposals = @recorder.proposals.select { _1.status == status }
    return if proposals.empty?

    h2(class: 'mt-4 mb-1 text-lg font-bold') { "#{STATUS_LABELS[status]} (#{proposals.size})" }
    p(class: 'mb-1 text-sm max-w-prose') { REVIEW_HINTS[status] } if REVIEW_HINTS[status]
    proposals_table(proposals, note: true)
  end

  def to_record
    proposals = @recorder.proposals.select { _1.status == 'record' }
    return if proposals.empty?

    details(class: 'mt-4') do
      summary(class: 'cursor-pointer text-lg font-bold') { "#{STATUS_LABELS['record']} (#{proposals.size})" }
      proposals_table(proposals, note: false)
    end
  end

  def proposals_table(proposals, note:)
    table(class: 'table-auto w-full text-sm') do
      thead do
        tr(class: 'border-b-2 border-grey-400 text-left') do
          th { 'Key' }
          th { 'Game name' }
          th { 'Site item' }
          th { 'Why' } if note
          th if note
        end
      end
      tbody do
        proposals.each do |proposal|
          tr(class: 'align-top border-b border-grey-200 dark:border-grey-700') do
            td(class: 'pr-2 font-mono text-xs') { proposal.key }
            td(class: 'pr-2') { proposal.name }
            td(class: 'pr-2') do
              if proposal.item
                a(href: item_path(proposal.item), class: 'Link Link--primary') { proposal.item.name }
                span(class: 'text-xs text-grey-500') { " #{proposal.item.kind}" }
              end
            end
            td(class: 'pr-2') { proposal.note } if note
            td(class: 'whitespace-nowrap') { actions(proposal) } if note
          end
        end
      end
    end
  end

  def actions(proposal)
    case proposal.status
    when 'renamed'
      post_button('Rename', adm_recipe_import_item_resolutions_path(@import), style: 'warning',
                  params: { resolution: 'adopt_name', key: proposal.key },
                  confirm: "Rename #{proposal.item.name} to #{proposal.name}?")
      whitespace
      post_button('Alias', adm_recipe_import_item_resolutions_path(@import),
                  params: { resolution: 'adopt_alias', key: proposal.key })
    when 'ambiguous'
      post_button('Record', record_game_keys_adm_recipe_import_path(@import), params: { key: proposal.key })
    end
  end

end
