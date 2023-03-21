require 'rails_helper'

RSpec.describe "Posts", type: :request do
  let(:user) { create :user, :root }

  before { sign_in user }

  describe "GET /index" do
    let!(:posts) { create_list(:post, 3, author: user) }
    it 'works' do
      get posts_path
      expect(response).to have_http_status(200)
    end
  end

  describe "GET /show" do
    let!(:post) { create(:post, author: user) }
    it 'works' do
      get post_path(post)
      expect(response).to have_http_status(200)
    end
  end

  describe "GET /edit" do
    let!(:post) { create(:post, author: user) }
    it 'works' do
      get edit_post_path(post)
      expect(response).to have_http_status(200)
    end
  end

  describe "GET /new" do
    it 'works' do
      get new_post_path
      expect(response).to have_http_status(200)
    end
  end

  describe "POST /create" do
    it 'works' do
      post posts_path, params: { post: { title: 'Test Title', content: "This is some content" } }
      expect(response).to redirect_to(posts_path)
    end

    it 'handles invalid data' do
      post posts_path, params: { post: { title: '', content: "This is some content" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template :new
    end
  end

  describe "PATCH /update" do
    let!(:post) { create(:post, author: user) }
    it 'works' do
      patch post_path(post), params: { post: { title: 'Test Title', content: "The changed content" } }
      expect(response).to redirect_to(posts_path)
    end

    it 'handles invalid data' do
      patch post_path(post), params: { post: { title: '', content: "This is some content" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template :edit
    end
  end

  describe "DELETE /destroy" do
    let!(:post) { create(:post, author: user) }
    it 'works' do
      delete post_path(post)
      expect(response).to redirect_to(posts_path)
    end
  end

end
