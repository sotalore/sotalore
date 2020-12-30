class SkillsController < ApplicationController
  skip_after_action :verify_authorized
  def index
    @skills = Skill::ADVENTURING
  end

  def crafting
    @skills = Skill::CRAFTING
    @on_crafting = true
    render action: :index
  end
end
