# frozen_string_literal: true

# The skills pages' Import tab: a player pastes the skill code from the game's
# SotaLore Skills plugin (see SkillCode), sees what it would change on the
# avatar (SkillSync), and applies it. Avatars are the player's own, like the
# skills pages. Without a signed-in player and a chosen avatar, the tab
# explains what it's for.
class SkillImportsController < ApplicationController
  before_action :authenticate_user!, except: [ :new ]
  before_action :find_avatar
  before_action :require_avatar, except: [ :new ]
  skip_after_action :verify_authorized

  def new
    render page(Views::SkillImports::New)
  end

  def preview
    code = SkillCode.parse(params[:code])
    if code.complete?
      render page(Views::SkillImports::Preview, sync: SkillSync.new(@avatar, code), code_text: params[:code])
    else
      render page(Views::SkillImports::New, code: code, code_text: params[:code]), status: :unprocessable_content
    end
  end

  def create
    code = SkillCode.parse(params[:code])
    unless code.complete?
      redirect_to new_avatar_skill_import_path(@avatar), alert: (code.errors.first || 'Some pages are missing.')
      return
    end
    changed = SkillSync.new(@avatar, code).apply!(
      clear_untrained: params[:clear_untrained] == '1',
      raise_targets: params[:raise_targets] == '1',
      reveal_ignored: params[:reveal_ignored] == '1'
    )
    redirect_to avatar_skills_path(@avatar, activity: 'adventuring'),
                notice: "Updated #{changed} #{'skill'.pluralize(changed)} for #{@avatar.name} from the game."
  end

  private

  def page(view, **)
    view.new(avatar: @avatar, avatars: @avatars, **)
  end

  # Like the skills pages: the chosen avatar becomes the current one, and
  # "none" (or no avatar in the path) means none.
  def find_avatar
    return if Current.user.null?

    @avatars = Current.user.avatars.to_a.presence
    return if params[:avatar_id].blank? || params[:avatar_id] == 'none'

    @avatar = Current.user.avatars.find(params[:avatar_id])
    session[:current_avatar_id] = @avatar.id
  end

  def require_avatar
    redirect_to skills_import_path unless @avatar
  end
end
