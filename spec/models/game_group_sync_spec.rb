require 'rails_helper'

RSpec.describe GameGroupSync do
  let(:user) { create(:user, :root) }
  let!(:blade)   { create(:item, name: 'Dagger Blade', kind: :group) }
  let!(:iron)    { create(:item, name: 'Iron Dagger Blade') }
  let!(:copper)  { create(:item, name: 'Copper Dagger Blade') }
  let!(:old)     { create(:item, name: 'Old Dagger Blade') }
  let!(:weapons) { create(:item, name: 'Crafted Weapon', kind: :category) }
  let!(:dagger)  { create(:item, name: 'Dagger', kind: :archetype) }

  before do
    blade.game_keys.create!(key: 'group:4', name: 'Dagger Blade')
    weapons.game_keys.create!(key: 'group:5', name: 'Crafted Weapon')
    iron.game_keys.create!(key: item_key('iron'), name: 'Iron Dagger Blade')
    ItemMembership.create!(group: blade, member: old)
  end

  let(:blade_members) do
    { item_key('iron') => 'Iron Dagger Blade', item_key('copper') => 'Copper Dagger Blade',
      item_key('horn') => 'Dark Unicorn Horn' }
  end

  def import_with(blade_complete: true)
    RecipeImport.create_from_json!(game_export_json(
      game_recipe_hash(name: 'Dagger', ingredients: { 'Dagger Blade' => 1 }, keys: { 'Dagger Blade' => 'group:4' }),
      groups: [
        { key: 'group:4', name: 'Dagger Blade', members: blade_members, complete: blade_complete },
        { key: 'group:5', name: 'Crafted Weapon', complete: true,
          members: { item_key('copper') => 'Copper Dagger Blade', item_key('dagger') => 'Dagger',
                     item_key('ghost') => 'Ghost Sword' } },
        { key: 'group:6', name: 'Hilt', members: {} },
      ]), user: user)
  end

  subject(:sync) { GameGroupSync.new(import_with, user) }

  it 'works out what each group needs' do
    blade_row = sync.row('group:4')
    expect(blade_row.status).to eq 'differs'
    expect(blade_row.add).to eq [ [ copper, [ item_key('copper') ] ], [ iron, [] ] ]
    expect(blade_row.create).to eq [ [ 'Dark Unicorn Horn', [ item_key('horn') ] ] ]
    expect(blade_row.remove).to eq [ old ]

    weapons_row = sync.row('group:5')
    expect(weapons_row.add).to eq [ [ copper, [ item_key('copper') ] ], [ dagger, [ item_key('dagger') ] ] ]
    expect([ weapons_row.create, weapons_row.remove, weapons_row.conflicts ]).to eq [ [], [], [] ]

    expect(sync.row('group:6').status).to eq 'unmapped'
  end

  it 'adds and creates members, recording keys and revisions' do
    expect(sync.add!('group:4')).to eq 3
    horn = Item.find_by_name('Dark Unicorn Horn').sole
    expect(horn).to have_attributes(kind: 'concrete')
    expect(horn.game_keys.pluck(:key)).to eq [ item_key('horn') ]
    expect(copper.game_keys.pluck(:key)).to eq [ item_key('copper') ]
    expect(blade.members.reload).to contain_exactly(copper, horn, iron, old)
    expect(iron.game_keys.count).to eq 1
    expect(blade.comments.count).to eq 3

    fresh = GameGroupSync.new(RecipeImport.last, user).row('group:4')
    expect([ fresh.add, fresh.create ]).to eq [ [], [] ]
  end

  it 'removes members a complete game group does not list' do
    expect(sync.remove!('group:4')).to eq 1
    expect(blade.members.reload).to be_empty
  end

  it "won't add an archetype to a group" do
    blade_members[item_key('dagger')] = 'Dagger'
    expect(sync.row('group:4').conflicts).to eq [ [ 'Dagger', dagger ] ]
  end

  it 'never removes on a partial list' do
    expect(GameGroupSync.new(import_with(blade_complete: false), user).row('group:4').remove).to be_empty
  end

  it 'adds known members to a category as examples, archetypes too, creating nothing' do
    expect(sync.add!('group:5')).to eq 2
    expect(weapons.members).to eq [ copper, dagger ]
    expect(Item.find_by_name('Ghost Sword')).to be_empty
  end

  it 'is in sync once everything is across' do
    sync.add!('group:4')
    sync.remove!('group:4')
    expect(GameGroupSync.new(RecipeImport.last, user).row('group:4').status).to eq 'in_sync'
  end
end
