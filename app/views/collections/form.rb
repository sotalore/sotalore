# frozen_string_literal: true

# A collection's name, description and the collections it's inside.
class Views::Collections::Form < Views::Form

  # +parent_ids+ are the collections ticked as holding this one.
  def initialize(collection:, parent_ids:)
    @collection = collection
    @parent_ids = parent_ids
  end

  def view_template
    render form_builder(model: @collection) do |f|
      f.error_messages if @collection.errors[:base].any?
      f.text_field(:name, autofocus: true)
      f.text_area_field(:description, optional: true,
                                      hint: "What belongs here. Shown on its page; Markdown works.")
      parents_field
      f.form_actions do
        f.cancel_button if @collection.persisted?
        f.submit_button
      end
    end
  end

  private

  def parents_field
    choices = @collection.possible_parents.to_a
    return if choices.empty?

    fieldset(class: "mb-4") do
      legend(class: "font-semibold") { "Inside" }
      p(class: "text-sm text-grey-600 dark:text-grey-300") do
        "The collections this one belongs to; its items count as theirs too. Tick as many as fit."
      end
      input(type: "hidden", name: "collection[parent_ids][]", value: "")
      div(class: "flex flex-row flex-wrap gap-x-4 gap-y-1") do
        choices.each do |parent|
          label(class: "inline-flex items-center gap-1") do
            input(type: "checkbox", class: "form-checkbox", name: "collection[parent_ids][]", value: parent.id,
                  checked: @parent_ids.include?(parent.id))
            plain parent.name
          end
        end
      end
    end
  end

end
