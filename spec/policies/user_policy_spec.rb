require 'rails_helper'

RSpec.describe UserPolicy do

  let(:root) { create :user, :root }
  let(:user) { create :user }
  let(:other_user) { create :user }

  subject { described_class }

  permissions ".scope" do
    it 'allows root to see all users' do
      expect(subject::Scope.new(root, User).resolve).to eq User.all
    end

    it 'allows non-root to see only themselves' do
      expect(subject::Scope.new(user, User).resolve).to eq User.where(id: user.id)
    end
  end

  permissions :show? do
    it 'allows root to see all users' do
      expect(subject).to permit(root, user)
    end
    it 'allows a user to see themselves' do
      expect(subject).to permit(user, user)
    end
    it 'disallows a user to see others' do
      expect(subject).to_not permit(user, other_user)
    end
  end

  permissions :update? do
    it 'allows root to update all users' do
      expect(subject).to permit(root, user)
    end
    it 'allows a user to update themselves' do
      expect(subject).to permit(user, user)
    end
    it 'disallows a user to update others' do
      expect(subject).to_not permit(user, other_user)
    end
  end

  permissions :destroy? do
    it 'does not allows root to delete a user' do
      expect(subject).to_not permit(root, user)
    end
    it 'does not allows a user to delete a user' do
      expect(subject).to_not permit(user, user)
    end
  end
end
