require 'rails_helper'

RSpec.describe "ItemMemberships", type: :request do
  let(:editor) { create(:user, :editor) }
  let!(:group)  { create(:item, name: 'Metal Ingot', kind: :group) }
  let!(:member) { create(:item, name: 'Iron Ingot') }

  context 'as an editor' do
    before { sign_in editor }

    it 'adds a member by id, recording revisions on both items' do
      expect {
        post item_memberships_path, params: { item_membership: { group_id: group.id, member_id: member.id } }
      }.to change(ItemMembership, :count).by(1).and change(Comment, :count).by(2)
      expect(group.members).to eq [ member ]
      expect(JSON.parse(group.comments.last.body)).to eq('changes' => { 'member' => [ nil, 'Iron Ingot' ] })
    end

    it 'adds to a group by name from the member page' do
      post item_memberships_path, params: { item_membership: { member_id: member.id, group_name: 'metal ingot' } }
      expect(member.groups).to eq [ group ]
    end

    it 'reports invalid memberships' do
      post item_memberships_path, params: { item_membership: { group_id: member.id, member_id: group.id } }
      expect(ItemMembership.count).to eq 0
      expect(flash[:alert]).to include 'must be a group or category'
    end

    it 'removes a member' do
      membership = ItemMembership.create!(group: group, member: member)
      expect { delete item_membership_path(membership) }.to change(ItemMembership, :count).by(-1)
    end

    it 'shows members and groups on item pages' do
      ItemMembership.create!(group: group, member: member)
      get item_path(group)
      expect(response.body).to include 'Group Members'
      expect(response.body).to include item_path(member)
      expect(response.body).to include item_membership_path(ItemMembership.last)
      expect(response.body).not_to include 'Salvage'

      get item_path(member)
      expect(response.body).to include 'Member of:'
      expect(response.body).to include item_path(group)
      expect(response.body).to include 'Salvage'
    end
  end

  it 'is not allowed for regular users' do
    sign_in create(:user)
    expect {
      post item_memberships_path, params: { item_membership: { group_id: group.id, member_id: member.id } }
    }.not_to change(ItemMembership, :count)
  end
end
