require 'rails_helper'

RSpec.describe SkillSync do
  let(:avatar) { create(:avatar, name: 'Gravidy') }
  let(:deflect) { Skill.find_by_game_id(131) }
  let(:gust)    { Skill.find_by_game_id(1) }
  let(:thrust)  { Skill.find_by_game_id(10) }
  let(:mining)  { Skill.find('gathering~mining~mining') }

  def sync(levels)
    SkillSync.new(avatar.reload, SkillCode.parse(skill_code(levels)))
  end

  def level(skill)
    avatar.skills.find_by(skill_key: skill.key)&.slice(:current, :target)&.symbolize_keys
  end

  before do
    avatar.skills.create!(skill_key: deflect.key, current: 40, target: 80)
    avatar.skills.create!(skill_key: thrust.key, current: 50, target: 60)
    avatar.skills.create!(skill_key: mining.key, current: 30, target: 100)
  end

  it 'sets current levels from the game, clears untrained ones, and leaves targets alone' do
    s = sync(131 => 90, 1 => 20, 10 => 50, 99_999 => 3)
    expect(s.changes.map { [ _1.skill, _1.from, _1.to ] }).to eq [ [ deflect, 40, 90 ], [ gust, nil, 20 ] ]
    expect(s.untrained.map(&:skill)).to eq [ mining ]
    expect(s.above_target.map { [ _1.skill, _1.from, _1.to ] }).to eq [ [ deflect, 80, 90 ] ]
    expect(s.unknown_ids).to eq [ 99_999 ]
    expect(s.unchanged_count).to eq 1

    expect(s.apply!).to eq 3
    expect(level(deflect)).to eq(current: 90, target: 80)
    expect(level(gust)).to eq(current: 20, target: nil)
    expect(level(thrust)).to eq(current: 50, target: 60)
    expect(level(mining)).to eq(current: nil, target: 100)
    expect(avatar.reload.skills_synced_at).to be_present
  end

  it 'keeps untrained levels, raises targets and reveals ignored skills when asked' do
    avatar.ignore_skill!(gust)
    s = sync(131 => 90, 1 => 20)
    expect(s.ignored_trained).to eq [ gust ]
    s.apply!(clear_untrained: false, raise_targets: true, reveal_ignored: true)
    expect(level(deflect)).to eq(current: 90, target: 90)
    expect(level(mining)).to eq(current: 30, target: 100)
    expect(avatar.reload.ignoring_skill?(gust)).to be false
  end

  it 'notices a code for another character, and the avatar it is for' do
    other = create(:avatar, user: avatar.user, name: 'gravidy two')
    s = SkillSync.new(avatar, SkillCode.parse(skill_code({ 1 => 1 }, character: 'Gravidy Two')))
    expect(s.character_matches?).to be false
    expect(s.matching_avatar).to eq other
    expect(sync(1 => 1).character_matches?).to be true
  end
end
