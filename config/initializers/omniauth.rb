# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  # provider :developer unless Rails.env.production?
  # provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], callback_path: '/users/auth/google_oauth2/callback'
  provider :discord, ENV['DISCORD_CLIENT_ID'], ENV['DISCORD_CLIENT_SECRET'], scope: 'identify email', callback_path: '/user/oauth/discord/callback'
end

OmniAuth.config.path_prefix = '/user/oauth'
