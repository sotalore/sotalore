require 'rails_helper'

RSpec.describe Planting, type: :model do

  let(:user) { create :user }
  let(:item) { create :item, use: :seed }

  it 'creates' do
    user.plantings.create!(seed: item, planted_at: Time.zone.now)
  end


  describe 'Plan calculations' do
    let(:item) { build :item, use: :seed, price: 16 }
    subject { Planting.new(planted_at: Time.zone.parse('Nov 30, 2016 12:00'), seed: item) }

    it 'figures out location_type_factor' do
      expect { subject.location_type = :greenhouse }
        .to change { subject.location_type_factor }
             .from(1).to(2)

      expect { subject.location_type = :indoor }
      .to change { subject.location_type_factor }
          .from(2).to(0.1)
    end

    it 'calculates total_growing_time' do
      expect { subject.location_type = :greenhouse }
        .to change { subject.total_growing_time }
             .from(48).to(24)
    end

    it 'calculates single_step_time' do
      expect { subject.location_type = :greenhouse }
        .to change { subject.single_step_time }
             .from(16).to(8)
    end

    it 'calculates days_of_growing' do
      day1 = subject.planted_at.to_date
      expect { subject.location_type = :greenhouse }
        .to change { subject.days_of_growing }
             .from([day1, day1 + 1, day1 + 2])
             .to([day1, day1 + 1])
    end

    it 'calculates buffer_width' do
      expect { subject.location_type = :greenhouse }
        .to change { subject.buffer_width }
             .from(16).to(25)
    end

    it 'calculates step_width' do
      expect { subject.location_type = :greenhouse }
        .to change { subject.step_width }
             .from(22).to(16)
    end


    context 'Given a very fast planting starting late in the day' do

      let(:item) { build :item, use: :seed, price: 6 }
      subject { Planting.new(planted_at: Time.zone.parse('Nov 30, 2016 18:00'), seed: item) }
      # two calendar days, but growing time of 12 hours or 24 hours
      # 18 hours -> 8/4 -> 8/4 -> 8/4
      # buffer is 18/48

      it 'calculates total_growing_time' do
        expect { subject.location_type = :greenhouse }
          .to change { subject.total_growing_time }
               .from(24).to(12)
      end

      it 'calculates total_calendar_days' do
        expect { subject.location_type = :greenhouse }
          .to_not change { subject.total_calendar_days }
               .from(2)
      end

      it 'calculates buffer_width' do
        expect { subject.location_type = :greenhouse }
          .to_not change { subject.buffer_width }
                   .from(1800/48)
      end

    end
  end
end
