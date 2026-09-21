require 'rails_helper'

RSpec.describe Release do
  subject(:release) { described_class.new(env) }

  context 'on Heroku with dyno metadata enabled' do
    let(:env) do
      {
        'HEROKU_RELEASE_VERSION'    => 'v42',
        'HEROKU_RELEASE_CREATED_AT' => '2015-04-02T18:00:42Z',
        'HEROKU_BUILD_COMMIT'       => '2c3a0b24069af49b3de35b8e8c26765c1dba9ff0',
        'HEROKU_SLUG_COMMIT'        => 'ffffffffffffffffffffffffffffffffffffffff',
      }
    end

    it 'reports the release' do
      expect(release).to be_known
      expect(release.version).to eq('v42')
      expect(release.released_at).to eq(Time.utc(2015, 4, 2, 18, 0, 42))
    end

    it 'prefers the build commit over the deprecated slug commit' do
      expect(release.commit).to eq('2c3a0b24069af49b3de35b8e8c26765c1dba9ff0')
      expect(release.short_commit).to eq('2c3a0b2')
    end
  end

  context 'on Heroku with only the deprecated slug commit' do
    let(:env) { { 'HEROKU_SLUG_COMMIT' => '2c3a0b24069af49b3de35b8e8c26765c1dba9ff0' } }

    it 'falls back to the slug commit' do
      expect(release.short_commit).to eq('2c3a0b2')
    end
  end

  context 'on Render' do
    let(:env) { { 'RENDER_GIT_COMMIT' => '9f89584a1b2c3d4e5f60718293a4b5c6d7e8f901' } }

    it 'reports only the commit' do
      expect(release).to be_known
      expect(release.short_commit).to eq('9f89584')
      expect(release.version).to be_nil
      expect(release.released_at).to be_nil
    end
  end

  context 'when the host reports nothing' do
    let(:env) { {} }

    it 'is unknown' do
      expect(release).not_to be_known
      expect(release.commit).to be_nil
      expect(release.short_commit).to be_nil
    end
  end

  context 'with blank or malformed values' do
    let(:env) do
      {
        'HEROKU_RELEASE_VERSION'    => '',
        'HEROKU_BUILD_COMMIT'       => '',
        'HEROKU_RELEASE_CREATED_AT' => 'not a time',
        'RENDER_GIT_COMMIT'         => '9f89584a1b2c3d4e5f60718293a4b5c6d7e8f901',
      }
    end

    it 'ignores blanks and does not raise on a bad timestamp' do
      expect(release.version).to be_nil
      expect(release.short_commit).to eq('9f89584')
      expect(release.released_at).to be_nil
    end
  end

  describe '.current' do
    it 'reads from ENV' do
      stub_const('ENV', ENV.to_h.merge('HEROKU_RELEASE_VERSION' => 'v7'))
      expect(described_class.current.version).to eq('v7')
    end
  end
end
