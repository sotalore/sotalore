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

  def ignore
    skill = Skill.find(params[:id])
    @avatar.ignore_skill!(skill)
    current_skill = @avatar.skills.find_by(skill_key: skill.key)

    respond_to do |format|
      format.html { redirect_to avatar_skills_path(@avatar) }
      format.turbo_stream do
        if params.key?(:show_all)
          render turbo_stream: turbo_stream
            .replace(skill, Views::Skills::Row.new(skill, @avatar, current_skill))
        else
          render turbo_stream: turbo_stream.remove(skill)
        end
      end
    end
  end

  def reveal
    skill = Skill.find(params[:id])
    @avatar.reveal_skill!(skill)
    current_skill = @avatar.skills.find_by(skill_key: skill.key)

    respond_to do |format|
      format.html { redirect_to avatar_skills_path(@avatar, show_all: true) }
      format.turbo_stream {
        render turbo_stream: turbo_stream
          .replace(skill, Views::Skills::Row.new(skill, @avatar, current_skill))
      }
    end
  end

  private
  def set_activity
    @activity = params[:activity].to_s.inquiry
  end

  def setup_avatar
    return if current_user.null?

    # Set @avatars for select in page heading
    @avatars = current_user.avatars
    @avatar = @avatars.find(params[:avatar_id]) unless params[:avatar_id] == 'none'
    session[:current_avatar_id] = @avatar.id if @avatar
  end

  def other_activity
    @activity.crafting? ? 'adventuring' : 'crafting'
  end
  helper_method :other_activity
end
