require 'spec_helper'

describe Hashie::Extensions::DeepFind do
  subject { Class.new(Hash) { include Hashie::Extensions::DeepFind } }
  let(:hash) do
    {
      library: {
        books: [
          { title: 'Call of the Wild' },
          { title: 'Moby Dick' }
        ],
        shelves: nil,
        location: {
          address: '123 Library St.',
          title: 'Main Library'
        }
      }
    }
  end
  let(:instance) { subject.new.update(hash) }

  describe '#deep_find' do
    it 'detects a value from a nested hash' do
      expect(instance.deep_find(:address)).to eq('123 Library St.')
    end

    it 'detects a value from a nested array' do
      expect(instance.deep_find(:title)).to eq('Call of the Wild')
    end

    it 'returns nil if it does not find a match' do
      expect(instance.deep_find(:wahoo)).to be_nil
    end
  end

  describe '#deep_find_all' do
    it 'detects all values from a nested hash' do
      expect(instance.deep_find_all(:title)).to eq(['Call of the Wild', 'Moby Dick', 'Main Library'])
    end

    it 'returns nil if it does not find any matches' do
      expect(instance.deep_find_all(:wahoo)).to be_nil
    end
  end
end
