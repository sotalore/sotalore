require 'rails_helper'

RSpec.describe "Comments", type: :request do
  let!(:parent) { create :item }
  let(:current_user) { create :user }
  before { sign_in current_user }

  describe 'GET index' do
    let(:comments) { create_list :comment, 3, subject: parent }
    it 'works' do
      get item_comments_path(parent)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET moderate' do
    let(:current_user) { create :user, :root }
    let(:comments) { create_list :comment, 3, subject: parent }

    it 'works' do
      get moderate_comments_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST create' do
    context 'Given valid parameters' do
      it 'creates a new Comment' do
        expect {
          post item_comments_path(parent), params: {
             comment: { body: 'the body' } }
        }.to change { parent.comments.reload.size }.by(1)

        comment = parent.comments.last
        expect(comment.author).to eq current_user
        expect(comment.message?).to eq true
        expect(response).to redirect_to(parent)
      end

    end
    context 'Given invalid parameters' do
      it 'renders the form' do
        expect {
          post item_comments_path(parent), params: {
             comment: { body: '' } }
        }.to_not change { parent.comments.reload.size }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  context 'Given an existing comment' do
    let!(:comment) { create :comment, subject: parent, author: current_user }

    describe 'GET edit' do
      it 'works' do
        get edit_item_comment_path(parent, comment)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'PATCH update' do
      context 'Given valid parameters' do
        it 'updates the Comment' do
          patch comment_path(comment, item_id: parent), params: {
                                   comment: { body: 'new body' } }

          comment.reload
          expect(comment.body).to eq 'new body'
          expect(response).to redirect_to(parent)
        end
      end

      context 'Given invalid parameters' do
        it 'renders the form' do
          patch comment_path(comment, item_id: parent), params: {
                                    comment: { body: '' } }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    describe 'DELETE destroy' do
      it 'deletes the comment' do
        expect {
          delete item_comment_path(parent, comment)
        }.to change { parent.comments.size }.by(-1)
        expect(response).to redirect_to(parent)
      end
    end

  end
end
