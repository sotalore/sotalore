require 'rails_helper'

RSpec.describe "Scenes", type: :request do
  # TODO Move controller specs here

  let(:current_user) { create :user, :root }
  before { sign_in current_user }

  describe "DELETE /scenes/:id" do

    let!(:scene) { create :scene }

    it "won't delete a scene" do
      # we don't support this ... yet
      delete scene_path(scene)
      expect(response).to redirect_to(scene_path(scene))
      expect(scene.reload).to be_present
    end

    context 'Given an attachment_id' do
      let(:image) { file_fixture('hawk-on-agave.jpg') }
      before do
        scene.images.attach(io: File.open(image), filename: 'hawk-on-agave.jpg', content_type: 'image/jpeg')
      end

      it 'deletes the attachment' do
        delete scene_path(scene, attachment_id: scene.images.first.id)
        expect(response).to redirect_to(scene_path(scene))
        expect(scene.reload.images).to be_empty
      end
    end
  end
end
