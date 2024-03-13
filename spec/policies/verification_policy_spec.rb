# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VerificationPolicy, type: :policy do
  let(:user) { User.new }

  subject { described_class }

  permissions :index? do
    context 'Given root' do
      let(:user) { User.new(roles: ['root']) }
      it 'grants access' do
        expect(subject).to permit(user)
      end
    end

    it 'denies access' do
      expect(subject).not_to permit(user)
    end
  end

end
