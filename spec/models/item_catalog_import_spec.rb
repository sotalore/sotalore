require 'rails_helper'

RSpec.describe ItemCatalogImport do
  let(:user) { create(:user, :root) }
  let!(:boots)  { create(:item, name: 'Epic Leather Boots') }
  let!(:scrap)  { create(:item, name: 'Leather Scrap') }
  let!(:yard)   { create(:item, name: 'Yard of Simple Leather') }
  let!(:supple) { create(:item, name: 'Yard of Supple Leather') }
  let!(:gloves) { create(:item, name: 'Epic Leather Gloves') }
  let!(:dagger) { create(:item, name: 'Dagger', kind: :archetype) }
  let!(:knife)  { create(:item, name: 'Skinning Knife', weight: 2) }

  before do
    boots.game_keys.create!(key: item_key('boots'), name: boots.name)
    gloves.game_keys.create!(key: item_key('gloves'), name: gloves.name)
    dagger.game_keys.create!(key: item_key('dagger'), name: dagger.name)
  end

  def import_of(*entries)
    ItemCatalogImport.create_from_json!(catalog_json(*entries), filename: 'sotalore-items.json', user: user)
  end

  let(:import) do
    import_of(
      catalog_entry(name: 'Epic Leather Boots +13', key: item_key('boots'), crafted: true,
                    salvage: { 'Leather Scrap' => [ 1, 25, 90.5 ], 'Yard of Simple Leather' => [ 1, 1, 9.5 ] },
                    yields: 'Eternal Pattern: Epic Leather Boots'),
      catalog_entry(name: 'Supple Epic Leather Gloves +12', key: item_key('gloves'), crafted: true,
                    salvage: { 'Yard of Supple Leather' => [ 1, 1, 9.5 ] }),
      catalog_entry(name: 'Bronze Dagger +11', key: item_key('dagger'), crafted: true,
                    salvage: { 'Bronze Hilt' => [ 1, 1, 5.7 ] }),
      catalog_entry(name: 'Iron Sword +12', key: item_key('iron sword'), crafted: true),
      catalog_entry(name: 'Skinning Knife', weight: 0.5, tool: true, salvage: { 'Metal Scrap' => [ 1, 15, 100 ] }),
      catalog_entry(name: 'Leather Scrap', weight: 0.05),
      catalog_entry(name: '[u]Love Letter[/u]', hovered: false),
      catalog_entry(name: 'Elven Woodwind Bow +1', hovered: false)
    )
  end

  it 'rejects files that are not item catalogs' do
    expect { ItemCatalogImport.create_from_json!({ recipes: [] }.to_json) }.to raise_error(ArgumentError)
    expect { ItemCatalogImport.create_from_json!({ scenes: [], items: [] }.to_json) }.to raise_error(ArgumentError)
    expect { ItemCatalogImport.create_from_json!({ type: 'finds', items: [ catalog_entry(name: 'Wax') ] }.to_json) }
      .to raise_error(ArgumentError, 'That file holds finds, not items')
  end

  it 'refuses files from plugins before 0.8.1' do
    expect { ItemCatalogImport.create_from_json!(catalog_json(catalog_entry(name: 'Wax'), plugin_version: '0.7.3')) }
      .to raise_error(ArgumentError, /before 0.8.1/)
    expect { ItemCatalogImport.create_from_json!(catalog_json(catalog_entry(name: 'Wax'), plugin_version: nil)) }
      .to raise_error(ArgumentError, /before 0.8.1/)
  end

  it 'refuses files from plugins before 0.11.1 on game API 41 or later, which divide by the stack size twice' do
    expect { ItemCatalogImport.create_from_json!(catalog_json(catalog_entry(name: 'Wax'), plugin_version: '0.11.0', api_version: 44)) }
      .to raise_error(ArgumentError, /before 0.11.1 on game API 41 or later/)
    expect(ItemCatalogImport.create_from_json!(catalog_json(catalog_entry(name: 'Wax'), plugin_version: '0.11.1', api_version: 44)))
      .to be_supported
  end

  it "won't apply a stored file that divided by the stack size twice" do
    stored = ItemCatalogImport.create!(payload: JSON.parse(catalog_json(catalog_entry(name: 'Skinning Knife', weight: 0.01),
                                                                        plugin_version: '0.11.0', api_version: 44)))
    expect(stored).not_to be_supported
    expect { stored.update_weights!(user) }.to raise_error(ItemCatalogImport::Error, /divided by the stack size twice/)
    expect(knife.reload.weight).to eq 2
  end

  describe 'analysis' do
    subject(:analysis) { import.analysis }

    it 'takes salvage from plain crafted items only, never archetypes, and skips unknown crafted items' do
      rows = analysis.rows.index_by { _1.entry.name }
      expect(rows['Epic Leather Boots +13'].salvage.map { [ _1.game.name, _1.missing? ] })
        .to eq [ [ 'Leather Scrap', true ], [ 'Yard of Simple Leather', true ] ]
      expect(rows['Supple Epic Leather Gloves +12'].salvage).to be_empty
      expect(rows['Bronze Dagger +11'].salvage).to be_empty
      expect(analysis.skipped_crafted.map(&:name)).to eq [ 'Iron Sword +12' ]
    end

    it 'finds weights to fill, tools, and unknown items' do
      rows = analysis.rows.index_by { _1.entry.name }
      expect(rows['Leather Scrap']).to be_missing_weight
      expect(rows['Skinning Knife']).to have_attributes(different_weight?: true, tool?: true)
      expect(rows['Epic Leather Boots +13']).not_to be_missing_weight
      expect(analysis.unknown_components.map(&:name)).to eq [ 'Metal Scrap' ]
      expect(analysis.unknown_catalog_items.map(&:name)).to eq [ 'Elven Woodwind Bow +1', 'Love Letter' ]
    end
  end

  describe 'applying' do
    it 'brings in salvage, missing weights, tools and keys, with revisions' do
      counts = import.apply!(user)
      expect(counts).to include(salvage_added: 2, weights: 1, tools: 1, keys: 2)
      salvage = boots.item_salvages_as_source.index_by(&:salvage_to)
      expect(salvage[scrap]).to have_attributes(min_count: 1, max_count: 25, chance: BigDecimal('90.5'))
      expect(salvage[scrap].amount).to eq '1–25, 90.5%'
      expect(salvage.keys).to contain_exactly(scrap, yard)
      expect(scrap.reload.weight).to eq BigDecimal('0.05')
      expect(knife.reload).to have_attributes(use: 'tool', weight: BigDecimal('2'))
      expect(knife.comments.revision.count).to eq 1
      expect(knife.game_keys.sole.catalog).to include('value' => 1, 'details' => include('tool' => true))
      expect(gloves.item_salvages_as_source).to be_empty

      again = ItemCatalogImport.find(import.id).apply!(user)
      expect(again.values_at(:salvage_added, :weights, :tools, :keys)).to all(eq 0)
    end

    it "updates weights to the game's, to 4 decimals" do
      fine = import_of(catalog_entry(name: 'Skinning Knife', weight: 0.0525))
      expect(fine.update_weights!(user)).to eq 1
      expect(knife.reload.weight).to eq BigDecimal('0.0525')
      expect(ItemCatalogImport.find(fine.id).analysis.rows.sole).not_to be_different_weight
    end

    it "doesn't take float noise for a different weight" do
      knife.update!(weight: 0.13)
      noisy = import_of(catalog_entry(name: 'Skinning Knife', weight: 0.129999995231628))
      expect(noisy.analysis.rows.sole).not_to be_different_weight
    end

    it 'leaves a weight the game does not know alone' do
      unweighed = import_of(catalog_entry(name: 'Leather Scrap', weight: nil))
      expect(unweighed.analysis.rows.sole).not_to be_missing_weight
      unweighed.apply!(user)
      expect(scrap.reload.weight).to be_nil
    end

    it "sets values from the tooltip, not the file's value, with revisions" do
      counts = import_of(catalog_entry(name: 'Leather Scrap', value: 0.0625, text: "Leather Scrap\nValue: 1\nMerchant pays: 1"),
                         catalog_entry(name: 'Skinning Knife', text: "Quantity: 3 | Stack Weight: 6 | Stack Value: 1,500"),
                         catalog_entry(name: 'Yard of Simple Leather', no_value: true, text: "Yard of Simple Leather\nNo Value")).apply!(user)
      expect(counts[:values]).to eq 3
      expect([ scrap, knife, yard ].map { _1.reload.value }).to eq [ 1, 500, 0 ]
      expect(scrap.comments.revision.sole.body).to include('"value":[null,1]')
    end

    it 'leaves values alone when the tooltip does not give one, and for crafted items and archetypes' do
      scrap.update!(value: 2)
      import_of(catalog_entry(name: 'Leather Scrap', text: 'Leather Scrap'),
                catalog_entry(name: 'Bronze Dagger +11', key: item_key('dagger'), crafted: true),
                catalog_entry(name: 'Dagger', key: item_key('dagger'), text: "Dagger\nValue: 30")).apply!(user)
      expect(scrap.reload.value).to eq 2
      expect(dagger.reload.value).to be_nil
    end

    it 'keeps a known value when the game does not know it' do
      import_of(catalog_entry(name: 'Leather Scrap', value: 3)).apply!(user)
      import_of(catalog_entry(name: 'Leather Scrap', value: nil)).apply!(user)
      expect(scrap.game_keys.sole.catalog).to include('value' => 3)
    end

    it 'updates changed salvage numbers, and removes salvage the game does not list on request' do
      old = ItemSalvage.create!(salvage_from: boots, salvage_to: scrap, min_count: 1, max_count: 10)
      extra = ItemSalvage.create!(salvage_from: boots, salvage_to: supple)
      row = import.analysis.rows.find { _1.item == boots }
      expect(row.salvage.find { _1.item == scrap }).to be_changed
      expect(row.extra_salvage).to eq [ extra ]

      import.apply!(user)
      expect(old.reload).to have_attributes(max_count: 25)
      expect(import.remove_extra_salvage!(boots)).to eq 1
      expect(ItemSalvage.exists?(extra.id)).to be false
    end

    it 'resolves unknown components so their salvage comes in' do
      import.create_item!(name: 'Metal Scrap')
      import.reload.apply!(user)
      expect(knife.item_salvages_as_source.map(&:salvage_to).map(&:name)).to eq [ 'Metal Scrap' ]
    end
  end
end
