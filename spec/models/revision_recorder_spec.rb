require "rails_helper"

RSpec.describe RevisionRecorder do

  subject { RevisionRecorder }

  describe 'Changing an Item' do
    let(:user) { create :user, :editor }

    context 'Creating an Item' do
      let(:attrs) { attributes_for(:item) }
      let(:item)  { Item.create!(attrs) }

      it 'creates a revision comment' do

        expect { subject.call(item, user) }
          .to change { Comment.count }.by(1)

        comment = Comment.last
        expect(comment.subject).to eq item
        expect(comment.author).to eq user
        attrs.each do |k,v|
          attrs[k] = [ nil, v]
        end
        expect(comment.body).to eq({changes: attrs}.to_json)
      end
    end

    context 'Updating an Item' do
      let!(:abstract) { create :item, :abstract }
      let!(:existing) { create :item,
                              name: 'Original Name',
                              instance_of: abstract }

      it 'creates a revision comment' do
        existing.update!(name: 'A New Name',
                         instance_id: nil,
                         gathering_skill: CraftSkill.find('field_dressing'))

        expect { subject.call(existing, user) }
          .to change { Comment.count }.by(1)

        comment = Comment.last
        expect(comment.subject).to eq existing
        expect(comment.author).to eq user
        expected = { changes: {
                      name:['Original Name', 'A New Name'],
                      gathering_skill: [ nil, 'Field Dressing'],
                      instance: [abstract.to_s, nil]
                  }}.to_json
        expect(comment.body).to eq(expected)
      end

      context 'Given a Seed' do
        let(:seed) { Seed.create!(name: 'Random Sedd') }

        it 'Properly checks yield changes' do
          seed.update!(yield: 10)

          expect { subject.call(seed, user) }
            .to change { Comment.count }.by(1)

          comment = Comment.last
          expect(comment.subject).to eq seed
          expect(comment.author).to eq user
          expected = { changes: { yield:[nil, 10] } }.to_json
          expect(comment.body).to eq(expected)
        end

      end


    end
  end

end
