class SkillsController < ApplicationController
  skip_after_action :verify_authorized

  before_action :set_activity, only: [ :index ]
  before_action :setup_avatar, except: [ :basics ]

  before_action do
    site_nav_activate_link(skills_path)
  end

  def index
    @skills = @activity.adventuring? ? Skill::ADVENTURING : Skill::CRAFTING
    render Views::Skills::Index.new(
      activity: @activity,
      skills: @skills,
      avatar: @avatar,
      avatars: @avatars,
      show_all: params.key?(:show_all),
    )
  end

  def basics
    render Views::Skills::Basics.new
  end

  def update
    earned_skill = @avatar.skills.find_or_initialize_by(skill_key: params[:id])
    if earned_skill.update(params.require(:skill).permit(:current, :target))
      head :ok
    else
      head :bad_request
    end
  end

  def clear
    return redirect_to(skills_path) unless @avatar

    @avatar.skills.delete_all
    activity = params[:activity].presence_in(%w[ adventuring crafting ]) || 'adventuring'
    redirect_to avatar_skills_path(@avatar, activity: activity), status: :see_other
  end

  # Ignoring or revealing a skill updates just its row: the page is too big
  # to re-render for it. Without Turbo, it goes back to the page it was done
  # from.
  def ignore
    skill = Skill.find(params[:id])
    @avatar.ignore_skill!(skill)

    respond_to do |format|
      format.turbo_stream do
        # The page hides ignored skills unless it's showing all of them.
        if params.key?(:show_all)
          render turbo_stream: turbo_stream.replace(skill, skill_row(skill))
        else
          render turbo_stream: turbo_stream.remove(skill)
        end
      end
      format.html { redirect_back fallback_location: avatar_skills_path(@avatar), status: :see_other }
    end
  end

  def reveal
    skill = Skill.find(params[:id])
    @avatar.reveal_skill!(skill)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(skill, skill_row(skill)) }
      format.html { redirect_back fallback_location: avatar_skills_path(@avatar, show_all: true), status: :see_other }
    end
  end

  private

  def skill_row(skill)
    Views::Skills::Row.new(skill, @avatar, @avatar.skills.find_by(skill_key: skill.key))
  end

  def set_activity
    @activity = params[:activity].to_s.inquiry
  end

  def setup_avatar
    return if Current.user.null?

    # Set @avatars for select in page heading
    @avatars = Current.user.avatars
    @avatar = @avatars.find(params[:avatar_id]) unless params[:avatar_id] == 'none'
    session[:current_avatar_id] = @avatar.id if @avatar
  end

  def other_activity
    @activity.crafting? ? 'adventuring' : 'crafting'
  end
  helper_method :other_activity

  def site_nav_activate_link(url)
    @portal_nav_active_link = url
  end
end
