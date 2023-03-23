# frozen_string_literal: true

class AdmController < ActionController::Base
  protect_from_forgery with: :exception
  include Pundit::Authorization

  before_action :verify_root_user

  after_action :verify_authorized

  protected

  def page_title(text=:not_provided)
    unless text == :not_provided
      request.env['page_title'] = text
    end
    request.env['page_title']
  end
  helper_method :page_title

  def verify_root_user
    unless current_user && current_user.has_role?('root')
      redirect_to root_path
    end
  end

end