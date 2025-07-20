# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do

  describe "confirmation_instructions" do
    let(:user) { create(:user) }
    let(:mail) { UserMailer.confirmation_instructions(user) }

    it "renders the mail" do
      expect(mail.subject).to eq("Confirm Your SotaLore Account!")
      expect(mail.to).to eq([user.email])
      mail.body.parts.map(&:body).each do |body|
        expect(body).to include(user_confirmation_url(token: ''))
      end
    end
  end

  describe "password_reset" do
    let(:user) { create(:user) }
    let(:mail) { UserMailer.password_reset(user) }

    it "renders the mail" do
      expect(mail.subject).to eq("Reset Your SotaLore Password")
      expect(mail.to).to eq([user.email])
      mail.body.parts.map(&:body).each do |body|
        expect(body).to include(edit_user_password_reset_url(token: ''))
      end
    end

    context 'Given a user without a password' do
      before do
        user.update_column(:encrypted_password, '')
        user.reload
      end

      it "renders the mail" do
        expect(mail.subject).to eq("Reset Your SotaLore Password")
        expect(mail.to).to eq([user.email])
        mail.body.parts.map(&:body).each do |body|
          expect(body).to include(edit_user_password_reset_url(token: ''))
        end
      end

    end
  end

end