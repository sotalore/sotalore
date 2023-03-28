require 'rails_helper'

RSpec.describe ScenePolicy do

  let(:user) { build :user }
  let(:root) { build :user, :root }

  subject { described_class }

  permissions :show? do
    it 'allows users to see a scene' do
      expect(subject).to permit(user, Scene.new)
    end
  end

  permissions :create? do
    it 'allows root to create a scene' do
      expect(subject).to permit(root, Scene.new)
    end

    it 'does not allow a user to create a scene' do
      expect(subject).to_not permit(user, Scene.new)
    end
  end

  permissions :update? do
    it 'allows root to update a scene' do
      expect(subject).to permit(root, Scene.new)
    end

    it 'does not allow a user to update a scene' do
      expect(subject).to_not permit(user, Scene.new)
    end
  end

  permissions :destroy? do
    it 'allows root to destroy a scene' do
      expect(subject).to permit(root, Scene.new)
    end

    it 'does not allow a user to destroy a scene' do
      expect(subject).to_not permit(user, Scene.new)
    end
  end
end
