# frozen_string_literal: true

class Views::Adm::Styles::Forms < Views::Base

  include Phlex::Rails::Helpers::FormWith
  register_builder_yielding_helper :sl_inline_form_with

  def view_template
    layout_main_content(size: :full) do
      render Views::Adm::Styles::Menu.new

      div(class: "p-2 bg-white") do
        sl_inline_form_with(model: Planting.new, url: "#") do |form|
          form.text_field(:search)
          form.select(:sort, [ [ "Name", "name" ], [ "Price", "price" ] ])
          form.text_field(:password_confirmation, label: "Password Confirmation")
          form.actions do
            form.submit("Submit")
          end
        end
      end

      div(class: "p-4 mb-4 grid grid-cols-2") do
        item = Item.new
        item.errors.add(:name, "is required")
        item.errors.add(:source, "is in error")

        div(class: "m-4 p-2 bg-white") do
          form_with(model: item, url: "#", builder: BasicFormBuilder) do |form|
            form.group(:name) do
              form.label(:name, "Name")
              form.text_field(:name)
            end
            form.group do
              form.label(:email, "Email")
              form.email_field(:email)
            end
            form.group do
              form.label(:password, "Password")
              form.text_field(:password)
            end
            form.group do
              form.label(:notes, "Notes")
              form.text_area(:notes)
            end
            form.group do
              form.label(:updated_at, "Updated")
              form.date_select(:updated_at)
            end
            form.group do
              form.label(:source, "Source")
              form.radio_buttons(:source, Item::ITEM_SOURCES)
            end

            form.submit("Submit")
          end
        end

        div(class: "m-4 p-2 bg-white") do
          form_with(model: item, url: "#", builder: SLFormBuilder) do |form|
            form.text_field(:name, label: "Name", hint: "this is the hint")
            form.email_field(:email, label: "Email")
            form.text_field(:password, label: "Password")
            form.text_field(:password_confirmation, label: "Password Confirmation")
            form.radio_buttons(:source, Item::ITEM_SOURCES)
            form.actions do
              form.cancel("Cancel", "#")
              form.submit("Submit")
            end
          end
        end
      end
    end
  end

end
