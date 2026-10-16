# frozen_string_literal: true

class Views::Adm::Users::Edit < Views::Base
  include Phlex::Rails::Helpers::FormWith

  # Never shown, even to admins.
  SECRET_ATTRIBUTES = %w[ encrypted_password reset_password_token confirmation_token ].freeze

  ROLE_HINTS = {
    'root' => 'runs the site: admin pages, users, imports, AI access',
    'editor' => 'edits game data: items, recipes, groups',
    'moderator' => 'looks after comments',
  }.freeze

  def initialize(user:)
    @user = user
  end

  def view_template
    div(class: "m-2 bg-white dark:bg-grey-800") do
      div(class: "grid grid-cols-2") do
        div(class: "p-4") do
          adm_form_with(model: @user, url: [ :adm, @user ]) do |form|
            form.text_field :name
            form.email_field :email
            form.select :disabled, [ [ "Enabled", false ], [ "Disabled", true ] ]
            roles_fields
            form.actions do
              default_button_to "Back", adm_users_path, class: "btn btn-secondary"
              form.submit
            end
          end
        end

        div(class: "p-4") do
          @user.attributes.except(*SECRET_ATTRIBUTES).each do |key, value|
            p do
              strong(class: "block") { key }
              plain value.to_s
            end
          end
        end
      end
    end
  end

  private

  def roles_fields
    fieldset(class: "my-4") do
      legend(class: "font-bold") { "Roles" }
      input(type: "hidden", name: "user[roles][]", value: "")
      User::ROLES.each do |role|
        label(class: "flex flex-row items-center gap-2") do
          input(type: "checkbox", name: "user[roles][]", value: role, checked: @user.roles.include?(role))
          strong { role }
          span(class: "text-sm text-grey-500") { ROLE_HINTS[role] }
        end
      end
      if @user.bot?
        p(class: "text-sm text-grey-500 mt-1") { "An AI account: it can't sign in, and acts through tokens." }
      end
    end
  end

  def adm_form_with(**options, &block)
    options[:builder] ||= AdmFormBuilder
    form_with(**options, &block)
  end

end
