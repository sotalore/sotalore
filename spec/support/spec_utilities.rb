# frozen_string_literal: true

module SpecUtilities

  def load_fixture_file(filename)
    File.read(Rails.root.join('spec', 'fixtures', filename))
  end

  def sign_in(user)
    allow(Current).to receive(:ip_address).and_return('192.168.1.1')
    allow(Current).to receive(:user_agent).and_return('Rails Testing')
    allow(Current).to receive(:user).and_return(user)
    user
  end

end
