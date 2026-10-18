# frozen_string_literal: true

# What a pasted skill code would change on an avatar (see SkillSync), with
# the choices that are the player's to make, and the button to apply it.
class Views::SkillImports::Preview < Views::SkillImports::Page
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(sync:, code_text:, **)
    super(**)
    @sync = sync
    @code_text = code_text
  end

  def view_template
    import_page do
      div(class: 'max-w-screen-md') do
        character_warning
        summary
        form(action: avatar_skill_import_path(@avatar), method: 'post', data: { turbo: 'false' }) do
          input(type: 'hidden', name: 'authenticity_token', value: view_context.form_authenticity_token)
          input(type: 'hidden', name: 'code', value: @code_text)
          changes
          untrained
          above_target
          ignored_trained
          div(class: 'mt-6 flex flex-row gap-2') do
            button(type: 'submit', class: 'Button Button--primary') { 'Save these levels' }
            a(href: new_avatar_skill_import_path(@avatar), class: 'Button Button--default') { 'Paste again' }
            a(href: avatar_skills_path(@avatar, activity: 'adventuring'), class: 'Button Button--default') { 'Cancel' }
          end
        end
      end
    end
  end

  private

  def character_warning
    return if @sync.character_matches?
    notice_warning do
      plain "This code is for #{@sync.code.character}, and this avatar is #{@avatar.name}. "
      if (other = @sync.matching_avatar)
        button_to("Use it for #{other.name} instead", preview_avatar_skill_import_path(other),
                  params: { code: @code_text }, class: 'Link', form: { class: 'inline', data: { turbo: 'false' } })
      else
        plain 'Saving puts its levels on this avatar anyway.'
      end
    end
  end

  def summary
    ul(class: 'mb-4 text-sm list-disc ml-6') do
      li { "#{@sync.code.levels.size} trained skills in the game, #{@sync.unchanged_count} already right here" }
      unknown = @sync.unknown_ids.size
      li { "#{unknown} #{'skill'.pluralize(unknown)} this site doesn't know yet, left out" } if unknown.positive?
    end
  end

  def changes
    heading("Current levels to change (#{@sync.changes.size})")
    if @sync.changes.empty?
      p(class: 'text-sm') { 'None: this avatar\'s current levels already match the game.' }
    else
      change_table(@sync.changes, 'Here', 'Game')
    end
  end

  def untrained
    return if @sync.untrained.empty?
    heading("Not trained in the game (#{@sync.untrained.size})")
    option('clear_untrained', true,
           'Clear their current levels: the game only lists skills you\'ve trained.')
    change_table(@sync.untrained, 'Here', 'Game')
  end

  def above_target
    return if @sync.above_target.empty?
    heading("Past their target (#{@sync.above_target.size})")
    option('raise_targets', false, 'Raise these targets to the game\'s level.')
    change_table(@sync.above_target, 'Target', 'Game')
  end

  def ignored_trained
    return if @sync.ignored_trained.empty?
    heading("Ignored, but trained in the game (#{@sync.ignored_trained.size})")
    option('reveal_ignored', false, 'Stop ignoring these.')
    p(class: 'text-sm') { @sync.ignored_trained.map(&:name).join(', ') }
  end

  def heading(text)
    h3(class: 'mt-4 mb-1 font-bold') { text }
  end

  def option(name, checked, text)
    label(class: 'flex flex-row items-center gap-2 mb-1 text-sm') do
      input(type: 'hidden', name: name, value: '0')
      input(type: 'checkbox', name: name, value: '1', checked: checked)
      plain text
    end
  end

  # A long list is grouped by school, in the skills pages' (the game's) order;
  # a short one names each skill's school instead.
  GROUP_OVER = 15

  def change_table(rows, from_heading, to_heading)
    grouped = rows.size > GROUP_OVER
    table(class: 'table-auto text-sm') do
      thead do
        tr(class: 'border-b border-grey-400 text-left') do
          th(class: 'pr-6') { 'Skill' }
          th(class: 'pr-6') { 'School' } unless grouped
          th(class: 'pr-4 text-right') { from_heading }
          th(class: 'text-right') { to_heading }
        end
      end
      if grouped
        rows.chunk_while { _1.skill.school == _2.skill.school && _1.skill.category == _2.skill.category }
            .each { |school_rows| school_group(school_rows) }
      else
        tbody { rows.each { change_row(_1, school: true) } }
      end
    end
  end

  def school_group(rows)
    skill = rows.first.skill
    tbody do
      tr do
        th(colspan: 3, class: 'pt-3 pb-1 text-left') do
          plain skill.school.titleize
          span(class: 'ml-2 text-xs font-normal text-grey-500') { "#{skill.category.titleize} · #{rows.size}" }
        end
      end
      rows.each { change_row(_1, school: false) }
    end
  end

  def change_row(row, school:)
    tr(class: 'border-b border-grey-200 dark:border-grey-700') do
      td(class: school ? 'pr-6' : 'pr-6 pl-3') { row.skill.name }
      td(class: 'pr-6') { row.skill.school.titleize } if school
      td(class: 'pr-4 text-right') { row.from.to_s.presence || '–' }
      td(class: 'text-right') { row.to.to_s.presence || '–' }
    end
  end

end
