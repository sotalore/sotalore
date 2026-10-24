require 'rails_helper'

RSpec.describe 'Collection proposals' do
  let(:reviewer) { create(:user, :root) }
  let(:ai)       { User.create_ai_account!(name: 'Claude') }
  let!(:light)   { Collection.create!(name: 'Light Armor') }
  let!(:leather) { Collection.create!(name: 'Leather Armor') }
  let!(:boots)   { create(:item, name: 'Fortified Leather Boots', kind: :archetype) }
  let!(:helm)    { create(:item, name: 'Fortified Leather Helm', kind: :archetype) }
  let!(:strap)   { create(:item, name: 'Cloth or Leather Strap', kind: :group) }

  def propose(change, subject: nil, **params)
    Proposal.create(author: ai, change: change, subject: subject, params: params, reason: 'The game says so')
  end

  def errors(proposal) = proposal.errors.full_messages.to_sentence

  it 'makes a collection inside others, with its items, in one go' do
    proposal = propose('collection.create', name: 'Fortified Leather Armor', description: 'The set.',
                                            parent_ids: [ light.id, leather.id.to_s ], item_ids: [ helm.id, boots.id ])
    expect(proposal).to be_persisted
    expect(proposal.summary).to eq 'Make collection Fortified Leather Armor'
    expect(proposal.differences).to include [ 'inside', nil, 'Leather Armor and Light Armor' ],
                                            [ 'items', nil, 'Fortified Leather Boots and Fortified Leather Helm' ]

    expect(proposal.accept!(reviewer)).to be true
    made = Collection.find_by!(name: 'Fortified Leather Armor')
    expect(made).to have_attributes(description: 'The set.', parents: [ leather, light ], items: [ boots, helm ])
    expect(proposal.reload.subject).to eq made
  end

  it 'refuses a taken name, unknown ids and groups' do
    expect(errors(propose('collection.create', name: 'light armor'))).to include 'light armor is already a collection'
    expect(errors(propose('collection.create', name: 'New', parent_ids: [ 0 ]))).to include "parent_ids 0 isn't a collection"
    expect(errors(propose('collection.create', name: 'New', item_ids: 'boots'))).to include 'item_ids must be a list of ids'
    expect(errors(propose('collection.create', name: 'New', item_ids: [ strap.id ])))
      .to include 'Cloth or Leather Strap is a group; collections list concrete items and archetypes'
  end

  it 'renames and redescribes' do
    proposal = propose('collection.update', subject: light, description: 'Cloth and leather.')
    expect(proposal.differences).to eq [ [ 'description', nil, 'Cloth and leather.' ] ]
    expect(proposal.accept!(reviewer)).to be true
    expect(light.reload.description).to eq 'Cloth and leather.'
    expect(errors(propose('collection.update', subject: light, name: 'Light Armor'))).to include 'already says that'
    expect(errors(propose('collection.update', subject: boots, name: 'X'))).to include 'Subject must be a collection'
  end

  it 'adds and removes items' do
    light.collection_items.create!(item: helm)
    expect(errors(propose('collection.add_items', subject: light, item_ids: [ helm.id ])))
      .to include 'Fortified Leather Helm already in Light Armor'

    add = propose('collection.add_items', subject: light, item_ids: [ boots.id ])
    expect(add.summary).to eq 'Add Fortified Leather Boots to Light Armor'
    expect(add.accept!(reviewer)).to be true
    expect(light.items).to eq [ boots, helm ]

    expect(errors(propose('collection.remove_items', subject: leather, item_ids: [ boots.id ])))
      .to include 'Fortified Leather Boots not listed in Leather Armor'
    remove = propose('collection.remove_items', subject: light, item_ids: [ boots.id, helm.id ])
    expect(remove.accept!(reviewer)).to be true
    expect(light.reload.items).to be_empty
  end

  it 'puts a collection inside another and takes it out, never in a loop' do
    link = propose('collection.link', subject: light, parent_id: leather.id)
    expect(link.summary).to eq 'Put Light Armor inside Leather Armor'
    expect(link.accept!(reviewer)).to be true
    expect(light.parents).to eq [ leather ]

    expect(errors(propose('collection.link', subject: leather, parent_id: light.id)))
      .to include "Leather Armor can't be inside Light Armor"
    unlink = propose('collection.unlink', subject: light, parent_id: leather.id)
    expect(unlink.accept!(reviewer)).to be true
    expect(light.reload.parents).to be_empty
    expect(errors(propose('collection.unlink', subject: light, parent_id: leather.id))).to include "isn't inside"
  end
end
