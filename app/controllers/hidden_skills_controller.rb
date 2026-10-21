# frozen_string_literal: true

# Choosing the skills an avatar hides, so the skills pages leave them out.
# The page lists every skill with a checkbox, and each change is saved as
# it's made (hidden_skills_controller.js); a school's buttons hide or reveal
# all its skills at once. Avatars are the player's own, like the skills
# pages.
class HiddenSkillsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_avatar
  skip_after_action :verify_authorized

  # Part of the skills pages in the site nav, rather than My Avatars, which
  # their paths start with.
  before_action { @portal_nav_active_link = skills_path }

  def index
    activity = params[:activity].presence_in(%w[ adventuring crafting ]) or raise ActiveRecord::RecordNotFound
    render Views::HiddenSkills::Index.new(
      activity: activity.inquiry,
      skills: activity == 'adventuring' ? Skill::ADVENTURING : Skill::CRAFTING,
      avatar: @avatar,
    )
  end

  def hide
    @avatar.ignore_skills!([ find_skill ])
    saved
  end

  def reveal
    @avatar.reveal_skills!([ find_skill ])
    saved
  end

  def hide_school
    @avatar.ignore_skills!(find_school_skills)
    saved
  end

  def reveal_school
    @avatar.reveal_skills!(find_school_skills)
    saved
  end

  private

  def find_avatar
    @avatar = Current.user.avatars.find(params[:avatar_id])
    session[:current_avatar_id] = @avatar.id
  end

  def find_skill
    Skill.find(params[:id]) or raise ActiveRecord::RecordNotFound
  end

  def find_school_skills
    Skill.in_school(params[:id]) or raise ActiveRecord::RecordNotFound
  end

  # The page saves with fetch, which only needs to know it worked. Without
  # JavaScript, a school's buttons are forms that come back to the page.
  def saved
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_back fallback_location: avatar_hidden_skills_path(@avatar), status: :see_other }
    end
  end
end
