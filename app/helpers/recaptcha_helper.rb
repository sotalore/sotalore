module RecaptchaHelper
  def require_recaptcha?
    current_user.nil?
  end
end