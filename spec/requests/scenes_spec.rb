require 'rails_helper'

RSpec.describe "Scenes", type: :request do

  let!(:overworld) { create :scene, :overworld }

  context 'Given current_user is root' do
    let(:current_user) { create :user, :root }
    before { sign_in current_user }

    describe "DELETE /scenes/:id" do
      let!(:scene) { create :scene, parent: overworld }

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

    it_behaves_like "an editable resource", except: [:destroy] do
      let(:model) { Scene }
      let(:fixture) { :scene }
      let(:invalid_attributes) { { name: '' } }
    end
  end

  context 'Given current_user is a regular user' do
    it_behaves_like "a non-editable resource" do
      let(:model) { Scene }
      let(:fixture) { :scene }
      let(:invalid_attributes) { { name: '' } }
    end
  end
end
