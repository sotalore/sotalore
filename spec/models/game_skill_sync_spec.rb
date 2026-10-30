require 'rails_helper'

RSpec.describe GameSkillSync do
  let(:thrust) { { 'name' => 'Thrust', 'xp_factor' => 1.0, 'key' => 'combat~blade~thrust', 'id' => 5, 'game_id' => 10, 'game_key' => 'Thrust' } }
  let(:mining) { { 'name' => 'Mining', 'xp_factor' => 1.0, 'key' => 'gathering~mining~mining', 'id' => 10_001, 'game_id' => 2041, 'game_key' => 'MiningProficiency' } }
  let(:lists) do
    { 'adventuring' => { 'combat' => { 'blades' => [ thrust ] } }, 'crafting' => { 'gathering' => { 'mining' => [ mining ] } } }
  end
  let(:game_thrust) { game(10, 'Thrust', 'Thrust', 'Blades', 'Combat') }
  let(:game_mining) { game(2041, 'MiningProficiency', 'Mining', 'Mining', 'Gathering') }

  def game(id, key, name, school, subcategory, xp = 1)
    { 'id' => id, 'key' => key, 'name' => name, 'school' => school, 'subcategory' => subcategory, 'xpMultiplier' => xp }
  end

  def sync(*skills) = described_class.new(skills, lists).call

  it 'changes nothing when the lists agree' do
    result = sync(game_thrust, game_mining)
    expect(result).not_to be_changed
    expect(result.moved + result.gone).to be_empty
  end

  it 'adds a new skill to its school with the next id of its list' do
    result = sync(game_thrust, game_mining, game(4349, 'SetTrap', 'Set Trap', 'Blades', 'Combat', 2))
    expect(result.added).to eq [ 'Set Trap (blades)' ]
    expect(lists['adventuring']['combat']['blades'].last).to eq(
      'name' => 'Set Trap', 'xp_factor' => 2.0, 'key' => 'combat~blades~set-trap', 'id' => 6, 'game_id' => 4349, 'game_key' => 'SetTrap'
    )
  end

  it 'keeps ids apart between the lists' do
    sync(game_thrust, game_mining, game(1, 'Dig', 'Dig', 'Mining', 'Gathering'))
    expect(lists['crafting']['gathering']['mining'].last['id']).to eq 10_002
  end

  it 'renames a skill and updates its factor, keeping its key and id' do
    result = sync(game(10, 'Thrust', 'Lunge', 'Blades', 'Combat', 0.5), game_mining)
    expect(thrust).to include('name' => 'Lunge', 'xp_factor' => 0.5, 'key' => 'combat~blade~thrust', 'id' => 5)
    expect(result.updated.first).to start_with('Lunge: name "Thrust" to "Lunge"')
  end

  it 'uses the site\'s names for schools the game calls something else' do
    lists['adventuring']['combat']['polearm'] = [ thrust.merge('game_id' => 111) ]
    expect(sync(game_thrust, game_mining, game(111, 'Thrust', 'Thrust', 'Polearms', 'Combat')).moved).to be_empty
  end

  it 'only reports a skill that moved school or left the game' do
    result = sync(game(10, 'Thrust', 'Thrust', 'Fire', 'Combat'))
    expect(result.moved).to eq [ 'Thrust: blades to fire' ]
    expect(result.gone).to eq [ 'Mining' ]
    expect(result).not_to be_changed
    expect(lists['crafting']['gathering']['mining']).to eq [ mining ]
  end

  it 'refuses a new skill in a category it does not know' do
    expect { sync(game(1, 'X', 'X', 'Y', 'Mystery')) }.to raise_error(ArgumentError, /Mystery/)
  end

  it 'finds the site in step with the example export' do
    game_skills = JSON.parse(Rails.root.join('data/plugin-examples/sotalore-game-skills.json').read)['skills']
    site = GameSkillSync::FILES.keys.index_with { JSON.parse(Rails.root.join("app/models/skills-#{_1}.json").read) }
    result = described_class.new(game_skills, site).call
    expect(result).not_to be_changed
    expect(result.moved + result.gone).to be_empty
  end
end
