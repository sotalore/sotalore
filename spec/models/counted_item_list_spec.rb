require "rails_helper"

RSpec.describe CountedItemList do

  CountedItem = CountedItemList::CountedItem

  let(:one_one) { CountedItem.new('one', 1) }
  let(:two_one) { CountedItem.new('one', 2) }
  let(:two_two) { CountedItem.new('two', 2) }
  let(:one_three) { CountedItem.new('three', 1) }

  context 'Given an empty list' do
    subject { CountedItemList.new([]) }

    context 'When comparing to an empty list' do
      before { subject.compare_to([]) }

      it 'has no added' do
        expect(subject.added).to be_empty
      end

      it 'has no removed' do
        expect(subject.removed).to be_empty
      end

      it 'has no changes' do
        expect(subject.changes).to be_empty
      end

      it 'provides appropriate hash for json' do
        expect(subject.as_json).to eq({})
      end

    end

    context 'When comparing to a list with one additional' do
      before { subject.compare_to([one_one]) }

      it 'has an added item' do
        expect(subject.added).to eq([one_one])
      end

      it 'has no removed' do
        expect(subject.removed).to be_empty
      end

      it 'has no changes' do
        expect(subject.changes).to be_empty
      end
    end

  end

  context 'Given a list with one item' do
    subject { CountedItemList.new([one_one]) }

    context 'When comparing to an empty list' do
      before { subject.compare_to([]) }

      it 'has no added' do
        expect(subject.added).to be_empty
      end

      it 'has one removed' do
        expect(subject.removed).to eq([one_one])
      end

      it 'has no changes' do
        expect(subject.changes).to be_empty
      end
    end

    context 'When comparing to an identical list' do
      before { subject.compare_to([one_one]) }

      it 'has no added' do
        expect(subject.added).to be_empty
      end

      it 'has no removed' do
        expect(subject.removed).to be_empty
      end

      it 'has no changes' do
        expect(subject.changes).to be_empty
      end
    end

    context 'When comparing to the same item different count' do
      before { subject.compare_to([two_one]) }

      it 'has no added' do
        expect(subject.added).to be_empty
      end

      it 'has no removed' do
        expect(subject.removed).to be_empty
      end

      it 'has one changes' do
        expect(subject.changes).to eq([[one_one, two_one]])
      end
    end

  end

  context 'Given two items' do
    subject { CountedItemList.new([one_one, two_two]) }
    context 'When comparing to a change, an addition and a removal' do

      before { subject.compare_to([two_one, one_three])}


      it 'has one added' do
        expect(subject.added).to eq([one_three])
      end

      it 'has one removed' do
        expect(subject.removed).to eq([two_two])
      end

      it 'has one changes' do
        expect(subject.changes).to eq([[one_one, two_one]])
      end

      it 'provides appropriate hash for json' do
        expect(subject.as_json)
          .to eq({
                   added: [ [ 'three', 1 ] ],
                   removed: [ [ 'two', 2 ] ],
                   changes: { 'one' => [1, 2] }
                 })
      end

    end
  end
end
