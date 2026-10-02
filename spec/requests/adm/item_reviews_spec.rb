require 'rails_helper'

RSpec.describe "Adm::ItemReviews", type: :request do
  let(:user) { create(:user, :root) }
  before { sign_in user }

  let!(:group) { create(:item, name: 'Dagger', kind: :group) }

  it 'lists items with their issues' do
    get adm_item_reviews_path
    expect(response).to have_http_status(200)
    expect(response.body).to include 'Dagger'
    expect(response.body).to include 'No members yet'

    %w[ group archetype category suspect ].each do |filter|
      get adm_item_reviews_path(filter: filter, issues: '1', q: 'dag')
      expect(response).to have_http_status(200)
    end
  end

  it 'changes an item kind, recording a revision' do
    expect {
      patch adm_item_review_path(group), params: { kind: 'archetype' }
    }.to change { group.comments.count }.by(1)
    expect(group.reload).to be_archetype
    expect(flash[:notice]).to eq 'Dagger is now an archetype.'
  end

  it 'clears the price of an item made abstract' do
    item = create(:item, name: 'Bucket', price: 5)
    patch adm_item_review_path(item), params: { kind: 'category' }
    expect(item.reload).to have_attributes(kind: 'category', price: nil)
  end

  it 'explains a change that would break memberships' do
    ItemMembership.create!(group: group, member: create(:item, name: 'Iron Dagger'))
    patch adm_item_review_path(group), params: { kind: 'archetype' }
    expect(group.reload).to be_group
    expect(flash[:alert]).to include 'has members'
  end

  it 'is only for root users' do
    sign_in create(:user)
    get adm_item_reviews_path
    expect(response).to redirect_to(root_path)
  end
end
