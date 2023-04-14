# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Astronomy, type: :model do

  describe '#orbital_period_real_seconds' do
    it 'has the correct orbital period for deceit' do
      expect(Astronomy.orbital_period_real_seconds(:deceit)).to eq(19 * Clock::NB_DAY)
    end
  end

  describe '#planet_position' do

    context "At the beginning of time (PC)" do
      let(:time) { Clock::BEGINNING_OF_PC }

      it 'returns the position of a planet' do
        expect(Astronomy.planet_position(:deceit, time: time)).to eq(0)
        expect(Astronomy.planet_position(:despise, time: time)).to eq(0)
        expect(Astronomy.planet_position(:dastard, time: time)).to eq(0)
        expect(Astronomy.planet_position(:injustice, time: time)).to eq(0)
        expect(Astronomy.planet_position(:punishment, time: time)).to eq(0)
        expect(Astronomy.planet_position(:dishonor, time: time)).to eq(0)
        expect(Astronomy.planet_position(:carnality, time: time)).to eq(0)
        expect(Astronomy.planet_position(:vanity, time: time)).to eq(0)
      end

    end

    context "At 2 hours later" do
      # 2 hours, or 2 NB days, is one orbit of dishonor
      let(:time) { Clock::BEGINNING_OF_PC + 2.hours }

      it 'returns the position of a planet' do
        expect(Astronomy.planet_position(:dishonor, time: time)).to eq(0)
      end
    end

    context "At 30 minutes later" do
      # dishonor is setting in the west
      let(:time) { Clock::BEGINNING_OF_PC + 30.minutes }

      it 'returns the position of a planet' do
        expect(Astronomy.planet_position(:dishonor, time: time)).to eq(270)
      end
    end

    context "At 3 hours later" do
      # 3 days is the orbit punishment
      let(:time) { Clock::BEGINNING_OF_PC + 3.hours }

      it 'returns the position of the planets' do
        expect(Astronomy.planet_position(:dishonor, time: time)).to eq(180)
        expect(Astronomy.planet_position(:punishment, time: time)).to eq(0)
      end
    end

    context "At 6 hours later" do
      # 6 days is the orbit of dishonor * punishment
      let(:time) { Clock::BEGINNING_OF_PC + 6.hours }

      it 'returns the position of the planets' do
        expect(Astronomy.planet_position(:dishonor, time: time)).to eq(0)
        expect(Astronomy.planet_position(:punishment, time: time)).to eq(0)
      end
    end

    context "At a specific observed time" do
      let(:time) { Time.zone.parse('April 14, 2023 11:00:00 -0700') }

      it 'returns the position of the planets' do
        expect(Astronomy.planet_position(:dishonor, time: time)).to eq(0)
        expect(Astronomy.planet_position(:punishment, time: time)).to eq(0)
      end
    end

    context "Vanity crossing zenith" do
      # longest orbital period of 29 days
      let(:vanity_seconds_per_degree) do
        Astronomy.orbital_period_real_seconds(:vanity) / 360.0
      end

      subject { Astronomy.planet_position(:vanity, time: time) }

      context "Just over 1/2 a degree before zenith" do
        let(:time) { Clock::BEGINNING_OF_PC - vanity_seconds_per_degree * 0.51 }
        it { is_expected.to be_within(0.009).of(0.50) }
      end

      context "Just over 1/2 a degree after zenith" do
        let(:time) { Clock::BEGINNING_OF_PC + vanity_seconds_per_degree * 0.51 }
        it { is_expected.to be_within(0.009).of(359.49) }
      end

      context "Just under 1/2 a degree after zenith" do
        let(:time) { Clock::BEGINNING_OF_PC + vanity_seconds_per_degree * 0.49 }
        it { is_expected.to be_within(0.009).of(359.51) }
      end
    end

    context 'for several planets' do
      subject { Astronomy.planet_position(planet, time: time) }

      context 'Given the beginning of the new era' do
        let(:time) { Clock::BEGINNING_OF_PC }

        context 'Given deceit' do
          let(:planet) { :deceit } # 19 days
          it { is_expected.to eq(0) }
        end

        context 'Given dishonor' do
          let(:planet) { :dishonor } # 2 days
          it { is_expected.to eq(0) }
        end
      end

      context 'Given 5 NB days after beginning of the new era' do
        let(:time) { Clock::BEGINNING_OF_PC + 5.hours }

        context 'Given deceit' do
          let(:planet) { :deceit } # 19 days
          it { is_expected.to eq(360 - ((5/19.0) * 360)) }
        end

        context 'Given dishonor' do
          let(:planet) { :dishonor } # 2 days
          it { is_expected.to eq(180) }
        end
      end

      context 'Given injustice with an 11 day period' do
        let(:planet) { :injustice } # 11 days

        context 'Given the EPOCH' do
          let(:time) { Clock::BEGINNING_OF_PC }
          it { is_expected.to eq(0) }
        end

        context 'Given the 0.25 orbit later' do
          let(:time) { Clock::BEGINNING_OF_PC + (0.25 * 11).hours }
          it { is_expected.to eq(270) }
        end

        context 'Given the 0.75 orbit later' do
          let(:time) { Clock::BEGINNING_OF_PC + (0.75 * 11).hours }
          it { is_expected.to eq(90) }
        end

      end
    end
  end

  describe '#time_to' do
    let(:target) { 0 }
    let(:target_period) { 0 }
    subject { Astronomy.time_to(position: position, period: period, target: target, target_period: target_period) }

    context 'Given already at target' do
      let(:position) { target }
      let(:period) { 2.hours }
      it { is_expected.to eq(0) }
    end

    context 'Given 1/4 of the way to target' do
      let(:position) { 270 }
      let(:period) { 2.hours }
      it { is_expected.to eq(1.5.hours) }
    end

    context 'Given 1/2 of the way to target' do
      let(:position) { 180 }
      let(:period) { 2.hours }
      it { is_expected.to eq(1.hours) }
    end

    context 'Given 3/4 of the way to target' do
      let(:position) { 90 }
      let(:period) { 2.hours }
      it { is_expected.to eq(0.5.hours) }
    end

    context 'Crossing the zenith' do
      context 'Due east to due west' do
        let(:position) { 90 }
        let(:target) { 270 }
        let(:period) { 2.hours }
        it { is_expected.to eq(1.hours) }
      end

      context 'Due west to due east' do
        let(:position) { 270 }
        let(:target) { 90 }
        let(:period) { 2.hours }
        it { is_expected.to eq(1.hours) }
      end

      context 'NE to NW' do
        let(:position) { 45 }
        let(:target) { 315 }
        let(:period) { 2.hours }
        it { is_expected.to eq(0.5.hours) }
      end

      context 'NW to NE' do
        # not crossing the zenith, but, similar test...
        let(:position) { 315 }
        let(:target) { 45 }
        let(:period) { 2.hours }
        it { is_expected.to eq(1.5.hours) }
      end

      context 'very small move over Zenith' do
        let(:position) { 1 }
        let(:target) { 359 }
        let(:period) { 1.hours }
        it { is_expected.to eq((2/360.0).hours.to_i) }
      end
    end

    context 'Given a target period (velocity of non-zero)' do
      let(:target_period) { 4.hours }
      context 'Given 1/2 of the way to target' do
        let(:position) { 180 }
        let(:period) { 2.hours }
        it { is_expected.to eq(2.hours.to_i) }
      end
    end

  end

end
