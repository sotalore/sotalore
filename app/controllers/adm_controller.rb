# frozen_string_literal: true

class AdmController < ActionController::Base
  layout -> { Views::Layouts::Adm }

  helper Views::ButtonHelper

  protect_from_forgery with: :exception
  include AuthenticationSupport
  include Pundit::Authorization

  before_action :verify_root_user

  after_action :verify_authorized

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def pundit_user
    Current.user
  end

  def page_title(text=:not_provided)
    unless text == :not_provided
      request.env['page_title'] = text
    end
    request.env['page_title']
  end
  helper_method :page_title

  def user_not_authorized
    redirect_back_or_to adm_users_path, alert: 'You are not allowed to do that.'
  end

  def verify_root_user
    unless Current.user.has_role?('root')
      redirect_to root_path
    end
  end

end
