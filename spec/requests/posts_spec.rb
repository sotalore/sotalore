require 'rails_helper'

RSpec.describe "Posts", type: :request do
  let(:user) { create :user, :root }

  before { sign_in user }

  shared_examples "standard posts" do

    describe "GET /index" do
      let!(:posts) { create_list(:post, 3, author: user, parent: parent) }
      it 'works' do
        get polymorphic_path([parent, :posts])
        expect(response).to have_http_status(200)
      end
    end

    describe "GET /show" do
      let!(:post) { create(:post, author: user) }
      it 'works' do
        get polymorphic_path([parent, post])
        expect(response).to have_http_status(200)
      end
    end

    describe "GET /edit" do
      let!(:post) { create(:post, author: user) }
      it 'works' do
        get polymorphic_path([:edit, parent, post])
        expect(response).to have_http_status(200)
      end
    end

    describe "GET /new" do
      it 'works' do
        get polymorphic_path([:new, parent, :post])
        expect(response).to have_http_status(200)
      end
    end

    describe "POST /create" do
      it 'works' do
        expect {
          post polymorphic_path([parent, :posts]), params: { post: { title: 'Test Title', content: "This is some content" } }
        }.to change(Post, :count).by(1)
        new_post = Post.last
        expect(response).to redirect_to(polymorphic_path([parent, new_post]))
      end

      it 'handles invalid data' do
        post polymorphic_path([parent, :posts]), params: { post: { title: '', content: "This is some content" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe "PATCH /update" do
      let!(:post) { create(:post, author: user) }
      it 'works' do
        patch polymorphic_path([parent, post]), params: { post: { title: 'Test Title', content: "The changed content" } }
        expect(response).to redirect_to(posts_path)
      end

      it 'handles invalid data' do
        patch polymorphic_path([parent, post]), params: { post: { title: '', content: "This is some content" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe "DELETE /destroy" do
      let!(:post) { create(:post, author: user) }
      it 'works' do
        delete polymorphic_path([parent, post])
        expect(response).to redirect_to(posts_path)
      end
    end
  end

  context "Given no parent" do
    let(:parent) { nil }

    it_behaves_like "standard posts"
  end


  context 'Given a parent' do
    let(:parent) { create :scene }

    it_behaves_like "standard posts"
  end

end
