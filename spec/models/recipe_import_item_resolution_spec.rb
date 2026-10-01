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
    names = import.unresolved_item_names.to_h { [ _1.name, [ _1.as_tool, _1.as_result ] ] }
    expect(names).to eq(
      'Citrine (Unrefined Gemstone)' => [ false, false ],
      'Pine or Maple Board' => [ false, false ],
      'Ring Mold' => [ true, false ],
      'Ring' => [ false, true ],
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

  it 'creates groups, but not for things a recipe makes' do
    expect(subject.create('Pine or Maple Board', group: true)).to be_abstract
    expect { subject.create('Ring', group: true) }.to raise_error(RecipeImportItemResolution::Error)
  end

  it 'refuses names that are not unknown in the import' do
    expect { subject.create('Maple Board') }.to raise_error(RecipeImportItemResolution::Error)
    expect { subject.create('Something Else') }.to raise_error(RecipeImportItemResolution::Error)
  end
end
