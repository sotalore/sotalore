# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clock do

  describe '#time_to_bst' do

    subject { Clock.time_to_bst(time) }

    context 'Given the beginning of the new era' do
      let(:time) { Time.zone.parse('September 1, 1997 19:00:00 -0500') }
      it { is_expected.to eq('Janus 1, 0PC 00:00') }
    end

    context 'Given a recent milestone (Release 112)' do
      let(:time) { Time.zone.parse('March 30, 2023 10:30:00 -0500') }
      it { is_expected.to eq('Marse 8, 667PC 12:00') }
    end

  end
end
