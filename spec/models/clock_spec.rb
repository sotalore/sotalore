# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clock do

  describe 'time math' do
    it "has 2.5 seconds per NB minute" do
      expect(Clock::NB_MINUTE).to eq(2.5)
    end

    it "has 60 NB minutes per NB hour" do
      expect(Clock::NB_HOUR).to eq(60 * 2.5)
    end

    it "has 24 NB hours per NB day" do
      expect(Clock::NB_DAY).to eq(24 * 60 * 2.5)
    end

    it 'has one real hour per NB day' do
      expect(Clock::NB_DAY).to eq(1.hour)
    end

    it 'has 28 NB days per NB month' do
      expect(Clock::NB_MONTH).to eq(28 * 24 * 60 * 2.5)
    end

    it 'has 12 NB months per NB year' do
      expect(Clock::NB_YEAR).to eq(12 * 28 * 24 * 60 * 2.5)
    end

    it 'has 336 real hours per NB year' do
      expect(Clock::NB_YEAR).to eq(336.hours)
    end

    it 'has 2 real weeks per NB year' do
      expect(Clock::NB_YEAR).to eq(2.weeks)
    end
  end

  describe '#real_seconds_since_beginning' do
    subject { Clock.real_seconds_since_beginning(time) }

    context "At the beginning of time" do
      let(:time) { Clock::BEGINNING_OF_PC }
      it { is_expected.to eq(0) }
    end

    context "At the beginning of time plus 1 second" do
      let(:time) { Clock::BEGINNING_OF_PC + 1.second }
      it { is_expected.to eq(1) }
    end

    context "At the beginning of time plus 1 minute" do
      let(:time) { Clock::BEGINNING_OF_PC + 1.minute }
      it { is_expected.to eq(60) }
    end

  end

  describe '#time_to_nbt' do

    subject { Clock.time_to_nbt(time) }

    context 'Given the beginning of the new era' do
      let(:time) { Time.zone.parse('September 1, 1997 19:00:00 -0500') }
      it { is_expected.to eq('Janus 1, 0PC 00:00') }
    end

    context 'Given a recent milestone (Release 112)' do
      let(:time) { Time.zone.parse('March 30, 2023 10:30:00 -0500') }
      it { is_expected.to eq('Marse 8, 667PC 12:00') }
    end

  end

  describe '#time_to_nbt_date_parts' do

    subject { Clock.time_to_nbt_date_parts(time) }

    context 'Given a recent milestone (Release 112)' do
      let(:time) { Time.zone.parse('March 30, 2023 10:45:40 -0500') }
      it { is_expected.to eq([667, 3, 8, 18, 16]) }
    end

    # hours and minutes are zero-based (0-59)
    context 'Given a fractional minute' do
      # 37 seconds is 14.8 seconds, we want 14
      let(:time) { Time.zone.parse('March 30, 2023 10:45:41 -0500') }
      it { is_expected.to eq([667, 3, 8, 18, 16]) }
    end

    context 'Given a zero hour and zero minute' do
      let(:time) { Time.zone.parse('March 30, 2023 10:00:00 -0500') }
      it { is_expected.to eq([667, 3, 8, 0, 0]) }
    end

    context 'Given the first and zero minute' do
      # 150 seconds in
      let(:time) { Time.zone.parse('March 30, 2023 10:02:30 -0500') }
      it { is_expected.to eq([667, 3, 8, 1, 0]) }
    end

    context 'Given the second hour' do
      # 150 + 150 seconds in
      let(:time) { Time.zone.parse('March 30, 2023 10:05:00 -0500') }
      it { is_expected.to eq([667, 3, 8, 2, 00]) }
    end

    context 'Given one minute before the second hour' do
      # 150 + 150 - 2.5 seconds in
      let(:time) { Time.zone.parse('March 30, 2023 10:04:58 -0500') }
      it { is_expected.to eq([667, 3, 8, 1, 59]) }
    end

    context 'Given the last hour and minute' do
      let(:time) { Time.zone.parse('March 30, 2023 10:59:59 -0500') }
      it { is_expected.to eq([667, 3, 8, 23, 59]) }
    end

    # years are zero based, but days(1-28) and months(1-12) are one-based
    context 'Given the very first day of the first month of the first year' do
      let(:time) { Time.zone.parse('September 2, 1997 00:00:00 -0000') }
      it { is_expected.to eq([0, 1, 1, 0, 0]) }
    end

    context 'Given the last day of the first month' do
      let(:time) { Time.zone.parse('September 3, 1997 03:00:00 -0000') }
      it { is_expected.to eq([0, 1, 28, 0, 0]) }
    end

    context 'Given the last day of the last month of the first year' do
      # 335 NB-days after the start
      # one NB year is exactly 14 days, so 13 days 23 hours
      let(:time) { Time.zone.parse('September 15, 1997 23:00:00 -0000') }
      it { is_expected.to eq([0, 12, 28, 0, 0]) }
    end

  end
end
