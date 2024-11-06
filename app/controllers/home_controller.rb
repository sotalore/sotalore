class HomeController < ApplicationController
  skip_after_action :verify_authorized

  def show
    @top_post = TopPost.find_or_create_by(key: 'what-to-do-next')
  end

  def roadmap
  end

  def lunar_rifts
    render Views::Home::LunarRifts.new
  end

  def master_trainers
    render Views::Home::MasterTrainers.new
  end
end
