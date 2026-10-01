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

    it 'stays within rounding of the published values for every skill' do
      CSV.foreach(Rails.root.join('data/skill-costs.csv'), headers: true) do |row|
        skill = Skill.new(xp_factor: row['Exp Factor'].to_f)
        [ 50, 80, 100, 120, 140, 160, 180, 200 ].each do |level|
          expect(skill.xp_to_level(level)).to be_within(skill.xp_factor.ceil).of(row["Lv #{level}"].to_i)
        end
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
