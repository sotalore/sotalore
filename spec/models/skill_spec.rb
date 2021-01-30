require 'rails_helper'

RSpec.describe Skill, type: :model do
 
  describe 'xp_to_level' do
    subject { Skill.new(name: 'Test Skill', xp_factor: 1.0) }

    it 'calculates the XP through levels' do
      expect(subject.xp_to_level(1)).to eq 0
      expect(subject.xp_to_level(2)).to eq 10
      expect(subject.xp_to_level(3)).to eq 21
      expect(subject.xp_to_level(4)).to eq 33
      expect(subject.xp_to_level(150)).to eq 141_418_589
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
      skill = Skill::ADVENTURING['combat']['shield'].third
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
  end

end
