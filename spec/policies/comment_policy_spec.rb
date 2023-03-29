require 'rails_helper'

RSpec.describe CommentPolicy do

  let(:user) { build :user }
  let(:author) { build :user }
  let(:root) { build :user, :root }
  let(:comment) { build :comment, author: author }

  subject { described_class }

  permissions :show? do
    it 'allows access to anyone' do
      expect(subject).to permit(user, comment)
    end
  end

  permissions :create? do
    it 'allows access to anyone' do
      expect(subject).to permit(user, comment)
    end
  end

  permissions :update? do
    it 'allows the author to update' do
      expect(subject).to permit(author, comment)
    end
    it 'allows the root to update' do
      expect(subject).to permit(root, comment)
    end
  end

  permissions :destroy? do
    it 'allows the author to destroy' do
      expect(subject).to permit(author, comment)
    end
    it 'allows the root to destroy' do
      expect(subject).to permit(root, comment)
    end
  end
end
