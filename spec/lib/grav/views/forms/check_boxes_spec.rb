# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::CheckBoxes do
  describe '#checkbox' do
    it 'renders a hidden 0-fallback input ahead of the checkbox, sharing its name' do
      frag = render_grav_form(model: GravFormsTestModel.new(accepted: false), url: '/somewhere') do |f|
        f.checkbox(:accepted)
      end
      checkbox = frag.at_css('input[type="checkbox"]')
      hidden = frag.at_css(%(input[type="hidden"][name="#{checkbox['name']}"]))
      expect(hidden['value']).to eq('0')
    end

    it 'is checked when the attribute is currently true' do
      frag = render_grav_form(model: GravFormsTestModel.new(accepted: true), url: '/somewhere') { |f| f.checkbox(:accepted) }
      expect(frag.at_css('input[type="checkbox"]')['checked']).to eq('checked')
    end

    it 'is unchecked when the attribute is currently false' do
      frag = render_grav_form(model: GravFormsTestModel.new(accepted: false), url: '/somewhere') { |f| f.checkbox(:accepted) }
      expect(frag.at_css('input[type="checkbox"]')['checked']).to be_nil
    end

    it 'is unchecked when the attribute is unset (nil)' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| f.checkbox(:accepted) }
      expect(frag.at_css('input[type="checkbox"]')['checked']).to be_nil
    end

    it 'lets an explicit checked: option override the derived state' do
      frag = render_grav_form(model: GravFormsTestModel.new(accepted: true), url: '/somewhere') do |f|
        f.checkbox(:accepted, checked: false)
      end
      expect(frag.at_css('input[type="checkbox"]')['checked']).to be_nil
    end

    it 'omits the hidden 0-fallback input when disabled' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| f.checkbox(:accepted, disabled: true) }
      expect(frag.at_css('input[type="hidden"][name="grav_forms_test_model[accepted]"]')).to be_nil
    end

    it 'does not leak framework-only options onto the rendered checkbox' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') do |f|
        f.checkbox(:accepted, hint: 'a hint')
      end
      expect(frag.at_css('input[type="checkbox"]').key?('hint')).to be false
    end

    it 'is aliased as #check_box' do
      form = GravFormsTestForm.new(url: '/somewhere')
      expect(form.method(:check_box)).to eq(form.method(:checkbox))
    end
  end

  describe '#checkbox_field' do
    it 'wraps the checkbox in a field_in_label with the attribute label' do
      frag = render_grav_form(model: GravFormsTestModel.new(accepted: true), url: '/somewhere') do |f|
        f.checkbox_field(:accepted)
      end
      label = frag.at_css('label.field-in-label')
      expect(label.at_css('span').text).to eq('Accepted')
      expect(label.at_css('input[type="checkbox"]')).to be_present
    end
  end

  describe '#collection_checkboxes' do
    let(:items) do
      [ GravFormsTestModel.new(id: 1, name: 'Red'), GravFormsTestModel.new(id: 2, name: 'Blue') ]
    end

    it 'renders one checkbox per collection item, sharing an array-style name' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') do |f|
        f.collection_checkboxes(:tags, items, value: :id, display: :name)
      end

      boxes = frag.css('input[type="checkbox"]')
      expect(boxes.size).to eq(2)
      expect(boxes.map { |b| b['name'] }.uniq).to eq([ 'grav_forms_test_model[tags][]' ])
      expect(boxes.map { |b| b['value'] }).to eq(%w[1 2])
      expect(frag.css('label span').map(&:text)).to eq(%w[Red Blue])
    end

    it 'renders a leading hidden empty-value input, so an empty selection still submits the param' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') do |f|
        f.collection_checkboxes(:tags, items, value: :id, display: :name)
      end
      hidden = frag.at_css('input[type="hidden"][name="grav_forms_test_model[tags][]"]')
      expect(hidden['value']).to eq('')
    end

    it 'does not leak framework-only options onto the rendered checkboxes' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') do |f|
        f.collection_checkboxes(:tags, items, value: :id, display: :name, hint: 'leaked?')
      end
      expect(frag.at_css('input[type="checkbox"]').key?('hint')).to be false
    end
  end
end
