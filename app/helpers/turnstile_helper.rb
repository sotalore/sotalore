module TurnstileHelper
  def require_turnstile?
    current_user.null?
  end
end
