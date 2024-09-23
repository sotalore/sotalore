# frozen_string_literal: true

# frozen_string_literal: true

class Views::Skills::Row < Views::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  register_output_helper :toggle_skill_button

  def initialize(skill, avatar, current_skill)
    @skill = skill
    @avatar = avatar
    @current_skill = current_skill
  end

  def view_template
    turbo_frame_tag(@skill) do
      div(class: 'tableRow hover:bg-grey-200', data: {
        controller: 'skills',
        'skills-xp-factor-value' => @skill.xp_factor,
        'skills-avatar-update-url-value' => (@avatar ? avatar_skill_path(@avatar.id, @skill.key) : nil),
        'skills-rollup-target' => 'member',
        'rollup-target' => "#{@skill.category}-#{@skill.school}"
      }) do
        classes = [
          'skillCell inline-flex items-center gap-x-1',
          ('opacity-50' if @avatar&.ignoring_skill?(@skill))
        ]
        div(class: classes) do
          toggle_skill_button(@avatar, @skill)
          span { @skill.name }
          div(class: 'text-xs opacity-80 font-normal') { "(#{@skill.xp_factor.to_s.sub(/.0$/, '')})" }
        end
        div(class: 'xpCell currentCell') do
          div(class: 'levelInput') do
            input(type: 'number', value: @current_skill.current, data: {
              'skills-target': 'from', action: 'skills#calculateCurrent blur->skills#updateFrom'
            })
          end
          span(class: 'xp', data: { 'skills-target': 'current' })
        end
        div(class: 'xpCell targetCell') do
          div(class: 'levelInput') do
            input(type: 'number', value: @current_skill.target, data: {
              'skills-target': 'to', action: 'skills#calculateTotal blur->skills#updateTo'
            })
          end
          span(class: 'xp', data: { 'skills-target': 'total' })
        end
        div(class: 'remainingXPCell') do
          span(data: { 'skills-target': 'remaining' })
        end
      end
    end
  end
end
