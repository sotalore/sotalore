class HomeController < ApplicationController
  skip_after_action :verify_authorized

  def show
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
