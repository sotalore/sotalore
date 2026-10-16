require 'rails_helper'

RSpec.describe Proposal do
  let(:reviewer) { create(:user, :root) }
  let(:ai)       { User.create_ai_account!(name: 'Claude') }
  let!(:wax)     { create(:item, name: 'Wax', weight: 0.1) }
  let!(:blade)   { create(:item, name: 'Dagger Blade', kind: :group) }
  let!(:iron)    { create(:item, name: 'Iron Dagger Blade') }

  def propose(change, subject: nil, **params)
    Proposal.create(author: ai, change: change, subject: subject, params: params, reason: 'The game says so')
  end

  it 'snapshots what it would change, and makes it as the reviewer when accepted' do
    proposal = propose('item.attributes', subject: wax, weight: '0.05')
    expect(proposal).to be_persisted
    expect(proposal).to have_attributes(before: { 'weight' => '0.1' }, summary: 'Change weight of Wax')
    expect(proposal.differences).to eq [ [ 'weight', '0.1', '0.05' ] ]

    expect(proposal.accept!(reviewer, note: 'checked in game')).to be true
    expect(wax.reload.weight).to eq BigDecimal('0.05')
    expect(proposal).to have_attributes(status: 'accepted', reviewed_by: reviewer, review_note: 'checked in game')
    expect(wax.comments.sole.author).to eq reviewer
  end

  it 'is stale when what it would change changes first' do
    proposal = propose('item.attributes', subject: wax, weight: '0.05')
    expect(proposal).not_to be_stale
    wax.update!(weight: 0.2)
    expect(proposal.reload).to be_stale
  end

  it 'stays pending with the error when the change can no longer be made' do
    proposal = propose('membership.add', subject: blade, member_id: iron.id)
    ItemMembership.create!(group: blade, member: iron)
    expect(proposal.accept!(reviewer)).to be false
    expect(proposal.reload).to be_pending
    expect(proposal.error).to include 'already in this group'
  end

  it 'refuses unknown changes and parameters, no-ops, and duplicates' do
    expect(propose('item.delete', subject: wax).errors[:change]).to be_present
    expect(propose('item.attributes', subject: wax, colour: 'red').errors.full_messages.join).to include 'unknown colour'
    expect(propose('item.kind', subject: wax, kind: 'concrete').errors.full_messages.join).to include 'already'
    expect(propose('item.kind', subject: nil, kind: 'group').errors[:subject]).to be_present
    expect(propose('item.rename', subject: wax, name: 'Dagger Blade').errors.full_messages.join).to include 'already an item'
    expect(Proposal.create(author: ai, change: 'item.kind', subject: wax, params: { kind: 'group' }).errors[:reason])
      .to be_present

    expect(propose('item.kind', subject: wax, kind: 'category')).to be_persisted
    expect(propose('item.kind', subject: wax, kind: 'category').errors.full_messages.join).to include 'already proposed'
  end

  describe 'changes' do
    it 'makes items' do
      proposal = propose('item.create', name: 'Dark Unicorn Horn', use: 'component', weight: '0.8')
      proposal.accept!(reviewer)
      item = proposal.reload.subject
      expect(item).to have_attributes(name: 'Dark Unicorn Horn', kind: 'concrete', use: 'component')
      expect(item.weight).to eq BigDecimal('0.8')
      expect(propose('item.create', name: 'wax').errors.full_messages.join).to include 'already an item'
    end

    it 'changes kinds, clearing the price of what becomes abstract' do
      wax.update!(price: 5)
      propose('item.kind', subject: wax, kind: 'category').accept!(reviewer)
      expect(wax.reload).to have_attributes(kind: 'category', price: nil)
    end

    it 'renames, keeping the old name, and adds aliases' do
      propose('item.rename', subject: wax, name: 'Beeswax').accept!(reviewer)
      expect(wax.reload.name).to eq 'Beeswax'
      propose('item.alias', subject: wax, name: 'Candle Wax').accept!(reviewer)
      expect(wax.aliases.pluck(:name)).to contain_exactly('Wax', 'Candle Wax')
    end

    it 'adds and removes members' do
      propose('membership.add', subject: blade, member_id: iron.id).accept!(reviewer)
      expect(blade.members).to eq [ iron ]
      expect(propose('membership.add', subject: blade, member_id: blade.id).errors.full_messages.join)
        .to include 'must be a concrete item'
      propose('membership.remove', subject: blade, member_id: iron.id).accept!(reviewer)
      expect(blade.members.reload).to be_empty
      expect(propose('membership.remove', subject: blade, member_id: iron.id).errors.full_messages.join)
        .to include "isn't in Dagger Blade"
    end
  end

  describe 'policy' do
    let(:editor) { create(:user, :editor) }

    it "lets editors review others' proposals, not their own" do
      proposal = propose('item.kind', subject: wax, kind: 'category')
      expect(ProposalPolicy.new(editor, proposal).accept?).to be true
      expect(ProposalPolicy.new(ai, proposal).accept?).to be false
      own = Proposal.create!(author: editor, change: 'item.kind', subject: iron, params: { kind: 'archetype' },
                             reason: 'mine')
      expect(ProposalPolicy.new(editor, own).accept?).to be false
      expect(ProposalPolicy.new(editor, own).withdraw?).to be true
      expect(ProposalPolicy.new(create(:user), proposal).show?).to be false
    end
  end
end
