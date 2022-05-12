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

  def switch_layout
    if cookies[:incoming_layout]
      cookies.delete :incoming_layout
    else
      cookies[:incoming_layout] = '1'
    end
    redirect_back_or_to(root_url)
  end
end
