require 'rails_helper'

RSpec.describe CommentsController, type: :controller do
  render_views

  let!(:parent) { create :item }
  let(:user)    { create :user }
  before        { sign_in user }

  describe 'GET index' do
    it 'works' do
      get :index, params: { item_id: parent }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST create' do
    context 'Given valid parameters' do
      it 'creates a new Comment' do
        expect {
          post :create, params: { item_id: parent, comment: {
                                    body: 'the body' } }
        }.to change { parent.comments.reload.size }.by(1)

        comment = parent.comments.last
        expect(comment.author).to eq user
        expect(comment.message?).to eq true
        expect(response).to redirect_to(parent)
      end

    end
    context 'Given invalid parameters' do
      it 'renders the form' do
        expect {
          post :create, params: { item_id: parent, comment: {
                                    body: '' } }
        }.to_not change { parent.comments.reload.size }

        expect(response).to render_template(:index)
      end
    end
  end

  context 'Given an existing comment' do
    let!(:comment) { create :comment, subject: parent, author: user }

    describe 'GET edit' do
      it 'works' do
        get :edit, params: { item_id: parent, id: comment }
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'PATCH update' do
      context 'Given valid parameters' do
        it 'updates the Comment' do
          patch :update, params: { item_id: parent, id: comment,
                                   comment: { body: 'new body' } }

          comment.reload
          expect(comment.body).to eq 'new body'
          expect(response).to redirect_to(parent)
        end
      end

      context 'Given invalid parameters' do
        it 'renders the form' do
          patch :update, params: { item_id: parent, id: comment,
                                    comment: { body: '' } }
          expect(response).to render_template(:edit)
        end
      end
    end

    describe 'DELETE destroy' do
      it 'deletes the comment' do
        expect {
          delete :destroy, params: { item_id: parent, id: comment }
        }.to change { parent.comments.size }.by(-1)
        expect(response).to redirect_to(parent)
      end
    end

  end
end
