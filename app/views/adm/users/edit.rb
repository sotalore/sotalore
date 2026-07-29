# frozen_string_literal: true

class Views::Adm::Users::Edit < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(user:)
    @user = user
  end

  def view_template
    div(class: "m-2 bg-white") do
      div(class: "grid grid-cols-2") do
        div(class: "p-4") do
          adm_form_with(model: @user, url: [ :adm, @user ]) do |form|
            form.text_field :name
            form.email_field :email
            form.select :disabled, [ [ "Enabled", false ], [ "Disabled", true ] ]
            form.actions do
              default_button_to "Back", adm_users_path, class: "btn btn-secondary"
              form.submit
            end
          end
        end

        div(class: "p-4") do
          @user.attributes.each do |key, value|
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

  def adm_form_with(**options, &block)
    options[:builder] ||= AdmFormBuilder
    form_with(**options, &block)
  end

end
