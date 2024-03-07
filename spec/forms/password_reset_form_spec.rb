# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PasswordResetForm, type: :model do

  let(:user) { create(:user) }
  let(:form) { PasswordResetForm.new(user) }

  describe '#save' do
    context 'when the form is valid' do
      it 'updates the user password' do
        form.save(password: 'newpassword', password_confirmation: 'newpassword')
        expect(user.authenticate('newpassword')).to eq(user)
      end
    end

    context 'when the form is invalid' do
      it 'does not update the user password' do
        form.save(password: 'newpassword', password_confirmation: 'wrongpassword')
        expect(user.authenticate('newpassword')).to be_falsey
      end
    end
  end

  describe 'validations' do
    it 'requires a password' do
      form.valid?
      expect(form.errors[:password]).to include("can't be blank")
    end

    it 'requires a minimum length' do
      form.password = 'short'
      form.valid?
      expect(form.errors[:password]).to include('is too short (minimum is 8 characters)')
    end

    it 'requires the password and password confirmation to match' do
      form.password = 'password'
      form.password_confirmation = 'wrongpassword'
      form.valid?
      expect(form.errors[:password_confirmation]).to include("doesn't match Password")
    end
  end

end