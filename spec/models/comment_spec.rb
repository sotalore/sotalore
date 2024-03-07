require 'rails_helper'

RSpec.describe Comment, type: :model do
  let(:item) { create :item }
  let(:user) { create :user }

  it 'works' do
    item.comments.create!(author: user, body: 'hi there')
  end

  describe 'Setting the author' do
    it 'sets a NullUser, but not as the actual_author' do
      comment = item.comments.create!(author: NullUser.new, body: 'hi there')
      expect(comment.author.null?).to eq true
      expect(comment.actual_author).to be_nil
    end
  end

  describe 'Comment by the anonymous user' do
    before do
      sign_in NullUser.new
      expect(Current).to receive(:user_key).and_return('key')
    end

    subject { item.comments.create!(author: NullUser.new, body: 'hi there') }

    it 'has the correct author' do
      expect(subject.author.null?).to eq true
    end

    it 'has the current author_name' do
      expect(subject.author_name).to eq NullUser.new.name
    end

    it 'is not visible' do
      expect(subject.visible?).to eq false
    end

    it 'sets the user_key' do
      expect(subject.user_key).to eq 'key'
    end

  end
end
