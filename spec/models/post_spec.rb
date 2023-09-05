require 'rails_helper'

RSpec.describe Post, type: :model do

  let(:long_body) { File.read(Rails.root.join('spec', 'fixtures', 'long-action-text-body.html')) }
  let(:long_body_truncated) { File.read(Rails.root.join('spec', 'fixtures', 'long-action-text-truncated.txt')) }

  it 'creates' do
    create :post
  end

  describe '#truncated' do
    context 'given multiple paragraphs and an attachment in the first' do
      let(:post) { create :post, content: long_body }
      it 'truncates and removes attachment' do
        expect(post.truncated(length: 600)).to eq long_body_truncated
      end
    end
  end
end
