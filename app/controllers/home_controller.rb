class HomeController < ApplicationController
  skip_after_action :verify_authorized

  def show
    @top_post = TopPost.find_by(key: 'what-to-do-next')
  end

  def roadmap
  end

  def lunar_rifts
  end

  def incoming
  end

end
