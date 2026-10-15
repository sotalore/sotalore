# frozen_string_literal: true

# Makes accounts through which AI uses the site (see User.create_ai_account!).
class Adm::AiAccountsController < AdmController
  def create
    authorize(User, :create?)
    account = User.create_ai_account!(name: params.require(:name).strip)
    redirect_to adm_api_tokens_path, notice: "Made the AI account #{account.name}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to adm_api_tokens_path, alert: e.record.errors.full_messages.to_sentence
  end
end
