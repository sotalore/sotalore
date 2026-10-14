require 'rails_helper'

RSpec.describe RecipeImportItemResolution do
  let(:user) { create(:user, :root) }
  let!(:citrine) { create(:item, name: 'Citrine') }
  let!(:board) { create(:item, name: 'Maple Board') }
  let(:import) do
    RecipeImport.create_from_json!(game_export_json(
      game_recipe_hash(name: 'Ring', ingredients: { 'Citrine (Unrefined Gemstone)' => 1, 'Maple Board' => 1,
                                                    'Pine or Maple Board' => 2 }, tools: [ 'Ring Mold' ])
    ))
  end
  subject { RecipeImportItemResolution.new(import, user) }

  it 'lists unknown names with how they are used' do
    names = import.unresolved_item_names.to_h { [ _1.name, [ _1.as_tool, _1.as_result, _1.likely_kind ] ] }
    expect(names).to eq(
      'Citrine (Unrefined Gemstone)' => [ false, false, 'concrete' ],
      'Pine or Maple Board' => [ false, false, 'group' ],
      'Ring Mold' => [ true, false, 'concrete' ],
      'Ring' => [ false, true, 'concrete' ],
    )
  end

  it 'suggests the unqualified name first' do
    expect(subject.suggestions_for('Citrine (Unrefined Gemstone)').first.item).to eq citrine
  end

  it 'suggests for many names in a constant number of queries' do
    names = import.unresolved_item_names.map(&:name)
    resolution = subject
    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name] == 'SCHEMA' }
    result = ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
      resolution.suggestions_for_names(names)
    end
    expect(result.keys).to match_array names
    expect(result['Citrine (Unrefined Gemstone)'].first.item).to eq citrine
    expect(result['Ring Mold']).to eq []
    expect(queries).to eq 2
  end

  it "won't offer items the game also uses by name" do
    suggestion = subject.suggestions_for('Pine or Maple Board').find { _1.item == board }
    expect(suggestion).not_to be_usable
    expect { subject.rename(board, 'Pine or Maple Board') }.to raise_error(RecipeImportItemResolution::Error)
  end

  it 'renames an item to the game name, keeping the old name as an alias' do
    subject.rename(citrine, 'Citrine (Unrefined Gemstone)')
    expect(citrine.reload.name).to eq 'Citrine (Unrefined Gemstone)'
    expect(citrine.aliases.map(&:name)).to eq [ 'Citrine' ]
    expect(citrine.comments.last).to be_revision
    expect(ItemLookup.new.id_for('citrine')).to eq citrine.id
  end

  it 'aliases an item' do
    subject.alias(citrine, 'Citrine (Unrefined Gemstone)')
    expect(citrine.reload.name).to eq 'Citrine'
    expect(ItemLookup.new.id_for('Citrine (Unrefined Gemstone)')).to eq citrine.id
  end

  it 'creates items, guessing use and source' do
    expect(subject.create('Ring Mold')).to have_attributes(use: 'tool', source: 'unknown')
    expect(subject.create('Ring')).to have_attributes(use: 'unknown', source: 'recipe')
  end

  it 'creates items of any kind, but no groups for what a game recipe makes' do
    expect(subject.create('Pine or Maple Board', kind: 'group')).to be_group
    expect(subject.create('Citrine (Unrefined Gemstone)', kind: 'category')).to be_category
    expect { subject.create('Ring', kind: 'group') }.to raise_error(RecipeImportItemResolution::Error, /archetype/)
    expect(subject.create('Ring', kind: 'archetype')).to have_attributes(kind: 'archetype', source: 'unknown')
  end

  it 'knows what a modification recipe acts on' do
    import = RecipeImport.create_from_json!(game_export_json(
      game_recipe_hash(name: 'Masterwork Carpentry Upgrade', ingredients: { 'Crafted Carpentry Equipable' => 1 },
                                                             results: { 'Crafted Carpentry Equipable' => 1 })
    ))
    unknown = import.unresolved_item_names.sole
    expect(unknown).to have_attributes(as_modified: true, as_result: false, likely_kind: 'category')
    expect(unknown).to be_can_be_group
  end

  it 'refuses names that are not unknown in the import' do
    expect { subject.create('Maple Board') }.to raise_error(RecipeImportItemResolution::Error)
    expect { subject.create('Something Else') }.to raise_error(RecipeImportItemResolution::Error)
  end

  describe 'with game keys' do
    let!(:head) { create(:item, name: 'Dragon Head') }
    let(:import) do
      RecipeImport.create_from_json!(game_export_json(
        game_recipe_hash(name: 'Trophy', ingredients: { 'Dragon Head' => 1, 'Glue' => 1 },
                                         results: { 'Mounted Head' => 1 },
                         keys: { 'Dragon Head' => 'group:9', 'Glue' => item_key('glue'),
                                 'Mounted Head' => item_key('mounted') }),
        groups: [ { key: 'group:9', name: 'Dragon Head', members: { item_key('red') => 'Red Dragon Head' } } ]))
    end

    def unknown(name, group_slot: false)
      import.reload.unresolved_item_names.find { _1.name == name && _1.group_slot? == group_slot }
    end

    it 'lists group slots named like a site item, which the slot never resolves to' do
      expect(unknown('Dragon Head', group_slot: true))
        .to have_attributes(keys: [ 'group:9' ], complete: true, name_taken: true, likely_kind: 'group',
                            kinds: %w[ group category ], new_item_name: 'Dragon Head (any)')
      expect(unknown('Glue')).to have_attributes(keys: [ item_key('glue') ], kinds: %w[ concrete archetype ])
    end

    it 'creates an "(any)" group for a slot, with its key' do
      item = subject.create('Dragon Head', kind: 'group', group_slot: true)
      expect(item).to have_attributes(name: 'Dragon Head (any)', kind: 'group')
      expect(item.game_keys.pluck(:key, :name)).to eq [ [ 'group:9', 'Dragon Head' ] ]
      expect(head.game_keys).to be_empty
      expect(unknown('Dragon Head', group_slot: true)).to be_nil
    end

    it 'only creates kinds that suit the keys' do
      expect { subject.create('Dragon Head', kind: 'concrete', group_slot: true) }
        .to raise_error(RecipeImportItemResolution::Error, /can only be a group or category/)
      expect { subject.create('Glue', kind: 'group') }
        .to raise_error(RecipeImportItemResolution::Error, /can only be concrete or an archetype/)
    end

    it 'records keys when renaming, aliasing or using an existing item' do
      paste = create(:item, name: 'Paste')
      subject.alias(paste, 'Glue')
      expect(paste.game_keys.pluck(:key)).to eq [ item_key('glue') ]

      heads = create(:item, name: 'Dragon Heads', kind: :group)
      subject.use(heads, 'Dragon Head', group_slot: true)
      expect(heads.reload).to have_attributes(name: 'Dragon Heads', game_keys: [ ItemGameKey.find_by!(key: 'group:9') ])

      mounted = create(:item, name: 'Head Mount')
      subject.rename(mounted, 'Mounted Head')
      expect(mounted.reload.game_keys.pluck(:key)).to eq [ item_key('mounted') ]
      expect(import.reload.unresolved_item_names).to be_empty
    end

    it "won't use an item of the wrong kind" do
      expect { subject.use(head, 'Dragon Head', group_slot: true) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'adopts a name the game changed' do
      glue = create(:item, name: 'Glue')
      glue.game_keys.create!(key: item_key('glue'), name: 'Glue')
      renamed = RecipeImport.create_from_json!(game_export_json(
        game_recipe_hash(name: 'Box', ingredients: { 'Hide Glue' => 1 }, results: { 'Glue' => 1 },
                         keys: { 'Hide Glue' => item_key('glue') })))
      resolution = RecipeImportItemResolution.new(renamed, user)
      expect(GameKeyRecorder.new(renamed).proposals.find { _1.key == item_key('glue') }.status).to eq 'renamed'

      resolution.adopt_game_name(item_key('glue'))
      expect(glue.reload.name).to eq 'Hide Glue'
      expect(glue.aliases.pluck(:name)).to eq [ 'Glue' ]
      expect(glue.game_keys.sole.name).to eq 'Hide Glue'
    end
  end
end
