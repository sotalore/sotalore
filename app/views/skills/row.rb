# frozen_string_literal: true

class Views::Skills::Row < Views::Base
  include Phlex::Rails::Helpers::TurboFrameTag
  include Phlex::Rails::Helpers::ButtonTo

  register_value_helper :dom_id
  register_value_helper :params

  def initialize(skill, avatar, current_skill=nil)
    @skill = skill
    @avatar = avatar
    current_skill ||= avatar.current_skills[skill.key] if avatar
    if current_skill
      @current_xp_value = current_skill.current
      @target_xp_value = current_skill.target
    end
  end

  def view_template
    row_data = {
      controller: 'skills',
      'skills-xp-factor-value' => @skill.xp_factor,
      'skills-avatar-update-url-value' => (@avatar ? avatar_skill_path(@avatar.id, @skill.key) : nil),
      'skills-rollup-target' => 'member',
      'rollup-target' => "#{@skill.category}-#{@skill.school}"
    }

    div(id: dom_id(@skill), class: 'tableRow hover:bg-grey-200', data: row_data) do
      classes = [
        'skillCell flex flex-row items-center gap-x-1',
        ('opacity-50' if @avatar&.ignoring_skill?(@skill))
      ]
      div(class: classes) do
        toggle_skill_button(@avatar, @skill)
        span { @skill.name }
        span(class: 'text-xs opacity-8 font-normal') { "(#{@skill.xp_factor.to_s.sub(/.0$/, '')})" }
      end

      div(class: 'flex items-center xpCell currentCell') do
        xp_input(value: @current_xp_value, data: {
          'skills-target': 'from', action: 'skills#calculateCurrent blur->skills#updateFrom'
        })
        span(class: 'xp', data: { 'skills-target': 'current' })
      end

      div(class: 'flex items-center xpCell targetCell') do
        xp_input(value: @target_xp_value, data: {
          'skills-target': 'to', action: 'skills#calculateTotal blur->skills#updateTo'
        })
        span(class: 'xp', data: { 'skills-target': 'total' })
      end

      div(class: 'remainingXPCell', data: { 'skills-target': 'remaining' })
    end
  end

  private

  def toggle_skill_button(avatar, skill)
    return unless avatar

    if @avatar.ignoring_skill?(skill)
      icon_name = 'eye_slash'
      path = reveal_avatar_skill_path(@avatar, skill.id)
    else
      icon_name = 'eye'
      show_all_param = params.key?(:show_all) ? { show_all: true } : {}
      path = ignore_avatar_skill_path(@avatar, skill.id, **show_all_param)
    end

    button_to(path, class: 'inline-flex items-center text-slorange-500', method: :patch, tabindex: "-1", form: { class: 'flex flex-row items-center' }) do
      render_icon(icon_name, size: :sm)
    end
  end

  def xp_input(**args)
    input(type: 'number', step: "1", min: "0", max: "200", **args)
  end

end
