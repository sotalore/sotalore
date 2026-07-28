class HomeController < ApplicationController
  skip_after_action :verify_authorized

  def show
    render Views::Home::Show.new
  end

  def roadmap
    render Views::Home::Roadmap.new
  end

  def lunar_rifts
    render Views::Home::LunarRifts.new
  end

  def master_trainers
    render Views::Home::MasterTrainers.new
  end
end
