require 'rails_helper'

RSpec.describe Skill, type: :model do

  describe 'xp_to_level' do
    subject { Skill.new(name: 'Test Skill', xp_factor: 1.0) }

    it 'calculates the XP through levels' do
      expect(subject.xp_to_level(0)).to eq 0
      expect(subject.xp_to_level(1)).to eq 0
      expect(subject.xp_to_level(50)).to eq 10_233
      expect(subject.xp_to_level(100)).to be_within(1).of 1_212_424
      expect(subject.xp_to_level(200)).to eq 16_709_249_906
    end

    it 'scales by the xp factor' do
      expect(Skill.new(xp_factor: 20.0).xp_to_level(200)).to eq 334_184_998_120
      expect(Skill.new(xp_factor: 0.5).xp_to_level(50)).to eq 5_117
    end

    it 'stays within rounding of the published values for every XP factor' do
      published = { 50 => 10_233, 80 => 180_138, 100 => 1_212_424, 120 => 8_157_124,
                    140 => 54_877_598, 160 => 369_189_582, 180 => 2_483_723_446, 200 => 16_709_249_906 }
      [ 0.5, 1, 2, 3, 4, 5, 6, 8, 10, 20 ].each do |factor|
        skill = Skill.new(xp_factor: factor.to_f)
        published.each { |level, xp| expect(skill.xp_to_level(level)).to be_within(factor.ceil).of(xp * factor) }
      end
    end
  end


  describe 'loading the skills' do
    it 'loads all the adventuring skills' do
      expect(Skill::ADVENTURING.length).to eq 3
    end

    it 'loads all the crafting skills' do
      expect(Skill::CRAFTING.length).to eq 3
    end

    it 'loads all the data from the json' do
      skill = Skill::ADVENTURING['combat']['shield'].first
      expect(skill.category).to eq 'combat'
      expect(skill.school).to eq 'shield'
      expect(skill.name).to eq 'Angles'
      expect(skill.xp_factor).to eq 4.0
      expect(skill.key).to eq 'combat~shield~angles'
    end
  end

  describe 'finding skills' do
    it 'finds a skill by a key' do
      expect(Skill.find("combat~shield~dig-in")).to be_present
    end

    it 'simply returns nil with no key' do
      expect(Skill.find('foo|bar|baz')).to be_nil
    end

    it 'finds a skill by the game\'s id' do
      skill = Skill.find_by_game_id(131)
      expect(skill.key).to eq 'combat~shield~deflect'
      expect(skill.game_key).to eq 'Deflect'
      expect(Skill.find_by_game_id(999_999)).to be_nil
    end
  end

  describe 'order' do
    it 'keeps each school by name, like the game\'s list view' do
      [ Skill::ADVENTURING, Skill::CRAFTING ].flat_map { _1.values.flat_map(&:values) }.each do |skills|
        names = skills.map { _1.name.downcase }
        expect(names).to eq names.sort
      end
    end

    it 'puts skills in the pages\' order: adventuring then crafting, by category, school and name' do
      in_page_order = [ Skill::ADVENTURING, Skill::CRAFTING ].flat_map { _1.values.flat_map(&:values).flatten }
      expect(Skill.in_page_order(in_page_order.reverse)).to eq in_page_order
    end
  end

  describe 'game ids' do
    let(:skills) { Skill::BY_KEY.values }

    it 'gives every skill a different game id' do
      expect(skills.map(&:game_id)).to all(be_an(Integer))
      expect(skills.map(&:game_id).uniq.size).to eq skills.size
    end
  end

  describe 'validating adventuring data' do
    it 'has no duplicate keys' do
      keys = []
      Skill::ADVENTURING.each do |category, schools|
        schools.each do |school, skills|
          skills.each do |skill|
            keys << skill.key
          end
        end
      end

      expect(keys.uniq.length).to eq keys.length
    end

    it 'has no duplicate IDs' do
      ids = []
      Skill::ADVENTURING.each do |category, schools|
        schools.each do |school, skills|
          skills.each do |skill|
            ids << skill.id
          end
        end
      end

      expect(ids.uniq.length).to eq ids.length
    end

    it 'has no duplicate names' do
      names = []
      Skill::ADVENTURING.each do |category, schools|
        schools.each do |school, skills|
          skills.each do |skill|
            names << skill.name
          end
        end
      end

      expect(names.uniq.length).to eq names.length
    end
  end

  describe 'validating crafting data' do
    it 'has no duplicate keys' do
      keys = []
      Skill::CRAFTING.each do |category, schools|
        schools.each do |school, skills|
          skills.each do |skill|
            keys << skill.key
          end
        end
      end

      expect(keys.uniq.length).to eq keys.length
    end

    it 'has no duplicate IDs' do
      ids = []
      Skill::CRAFTING.each do |category, schools|
        schools.each do |school, skills|
          skills.each do |skill|
            ids << skill.id
          end
        end
      end

      expect(ids.uniq.length).to eq ids.length
    end

    it 'has no duplicate names' do
      names = []
      Skill::CRAFTING.each do |category, schools|
        schools.each do |school, skills|
          skills.each do |skill|
            names << skill.name
          end
        end
      end

      expect(names.uniq.length).to eq names.length
    end
  end

end
