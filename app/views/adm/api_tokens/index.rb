# frozen_string_literal: true

class Views::Adm::ApiTokens::Index < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  INPUT_CSS = 'border border-grey-400 rounded px-2 py-1 text-sm dark:bg-grey-700'

  def initialize(accounts:, tokens:, new_token: nil, new_api_token: nil)
    @accounts = accounts
    @tokens = tokens
    @new_token = new_token
    @new_api_token = new_api_token
  end

  def view_template
    div(class: 'm-2 bg-white dark:bg-grey-800 p-4') do
      h1(class: 'text-2xl font-bold') { 'AI Access' }
      intro
      new_token_notice if @new_token
      accounts_section
      tokens_section
    end
  end

  private

  def intro
    p(class: 'my-2 max-w-prose text-sm') do
      plain 'AI uses the site through its own accounts, so everything it does is shown as theirs. '
      plain 'An AI account has no password and can\'t sign in; it uses tokens issued here, sent as '
      code { 'Authorization: Bearer <token>' }
      plain ' to the API (try '
      code { '/api/v1/me' }
      plain '). A token is shown once, when it\'s made. Revoke one that may have leaked.'
    end
  end

  def new_token_notice
    div(class: 'Callout Callout-notice my-4') do
      p(class: 'font-bold') { "New token for #{@new_api_token.user.name}: #{@new_api_token.name}" }
      p(class: 'text-sm') { 'Copy it now; it won\'t be shown again.' }
      input(type: 'text', readonly: true, value: @new_token, class: "#{INPUT_CSS} w-full font-mono mt-2")
    end
  end

  def accounts_section
    h2(class: 'mt-6 mb-2 text-lg font-bold') { 'AI accounts' }
    if @accounts.empty?
      p(class: 'text-sm text-grey-500') { 'None yet.' }
    else
      ul(class: 'mb-2 text-sm') do
        @accounts.each do |account|
          li do
            strong { account.name }
            plain " · #{account.roles.presence&.join(', ') || 'no roles'}"
            plain ' · disabled' if account.disabled?
          end
        end
      end
    end
    form(action: adm_ai_accounts_path, method: 'post', class: 'flex flex-row flex-wrap items-center gap-2') do
      authenticity_token_field
      input(type: 'text', name: 'name', placeholder: 'Account name, e.g. Claude', required: true, class: INPUT_CSS)
      button(type: 'submit', class: 'Button Button--sm Button--default') { 'Make AI account' }
    end
  end

  def tokens_section
    h2(class: 'mt-6 mb-2 text-lg font-bold') { 'Tokens' }
    new_token_form if @accounts.any?
    if @tokens.empty?
      p(class: 'text-sm text-grey-500') { 'None yet.' }
      return
    end
    table(class: 'table-auto w-full text-sm mt-4') do
      thead do
        tr(class: 'border-b-2 border-grey-400 text-left') do
          %w[ Name Account Scopes Made Expires Last\ used Status ].each { |h| th(class: 'pr-3') { h } }
          th
        end
      end
      tbody { @tokens.each { |token| token_row(token) } }
    end
  end

  def token_row(token)
    tr(class: 'border-b border-grey-200 dark:border-grey-700') do
      td(class: 'pr-3') { token.name }
      td(class: 'pr-3') { token.user.name }
      td(class: 'pr-3') { token.scopes.join(', ') }
      td(class: 'pr-3') do
        time_ago_tag token.created_at
        plain " by #{token.created_by.name}"
      end
      td(class: 'pr-3') { token.expires_at ? token.expires_at.to_date.to_s : 'never' }
      td(class: 'pr-3') { token.last_used_at ? time_ago_tag(token.last_used_at) : plain('never') }
      td(class: 'pr-3') do
        if token.revoked? then plain 'revoked'
        elsif token.expired? then plain 'expired'
        else plain 'active'
        end
      end
      td do
        if token.active?
          button_to('Revoke', revoke_adm_api_token_path(token), method: :post,
                    class: 'Button Button--sm Button--danger',
                    form: { class: 'inline-block', data: { turbo_confirm: "Revoke #{token.name}?" } })
        end
      end
    end
  end

  # Turbo ignores a form response that isn't a redirect, and the new token is
  # rendered in the response (not redirected, so it never goes through the
  # session), so this form is submitted without Turbo.
  def new_token_form
    form(action: adm_api_tokens_path, method: 'post', class: 'flex flex-row flex-wrap items-center gap-2',
         data: { turbo: 'false' }) do
      authenticity_token_field
      select(name: 'user_id', class: INPUT_CSS) do
        @accounts.reject(&:disabled?).each { |account| option(value: account.id) { account.name } }
      end
      input(type: 'text', name: 'name', placeholder: 'Token name, e.g. Claude Code on laptop', required: true,
            class: "#{INPUT_CSS} w-64")
      ApiToken::SCOPES.each do |scope|
        label(class: 'flex flex-row items-center gap-1') do
          input(type: 'checkbox', name: 'scopes[]', value: scope, checked: scope == 'read')
          plain scope
        end
      end
      select(name: 'expires_in_days', class: INPUT_CSS) do
        Adm::ApiTokensController::EXPIRY_DAYS.each do |days|
          option(value: days, selected: days == 90) { "expires in #{days} days" }
        end
        option(value: '') { 'never expires' }
      end
      button(type: 'submit', class: 'Button Button--sm Button--primary') { 'Make token' }
    end
  end

  def authenticity_token_field
    input(type: 'hidden', name: 'authenticity_token', value: view_context.form_authenticity_token)
  end
end
