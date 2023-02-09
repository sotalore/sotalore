class SkillsController < ApplicationController
  include NavHelper
  skip_after_action :verify_authorized

  before_action :set_activity, only: [ :index ]
  before_action :setup_avatar, except: [ :basics ]

  before_action do
    site_nav_activate_link(skills_path)
  end

  def index
    @skills = @activity.adventuring? ? Skill::ADVENTURING : Skill::CRAFTING
  end

  def basics
  end

  def update
    earned_skill = @avatar.skills.find_or_initialize_by(skill_key: params[:id])
    if earned_skill.update(params.require(:skill).permit(:current, :target))
      head :ok
    else
      head :bad_request
    end
  end

  private
  def set_activity
    @activity = params[:activity].to_s.inquiry
  end

  def setup_avatar
    @current_skills = Hash.new(EarnedSkill.new)
    if current_user.not_null?
      @avatars = current_user.avatars
      if @avatars.present?
        @avatar = @avatars.find(params[:avatar_id]) if params[:avatar_id]
        if @avatar
          @avatar.skills.each do |earned_skill|
            @current_skills[earned_skill.skill_key] = earned_skill
          end
        end
      end
    end
  end

  def other_activity
    @activity.crafting? ? 'adventuring' : 'crafting'
  end
  helper_method :other_activity
end
