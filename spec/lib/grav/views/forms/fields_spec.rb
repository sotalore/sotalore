# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::Fields do
  describe '#field_classes' do
    it 'always includes the base field-container class' do
      form = GravFormsTestForm.new(url: '/somewhere')
      expect(form.field_classes).to include('field-container')
    end

    it 'adds field-align-right when align: :right' do
      form = GravFormsTestForm.new(url: '/somewhere')
      expect(form.field_classes(:name, align: :right)).to include('field-align-right')
    end

    it 'adds field-with-errors when the attribute has an error' do
      model = GravFormsTestModel.new
      model.errors.add(:name, "can't be blank")
      form = GravFormsTestForm.new(model: model, url: '/somewhere')
      expect(form.field_classes(:name)).to include('field-with-errors')
    end

    it 'skips the error class when no attribute is given' do
      model = GravFormsTestModel.new
      model.errors.add(:name, "can't be blank")
      form = GravFormsTestForm.new(model: model, url: '/somewhere')
      expect(form.field_classes).not_to include('field-with-errors')
    end
  end

  describe '#label_classes' do
    it 'wraps the given label_class option' do
      form = GravFormsTestForm.new(url: '/somewhere')
      expect(form.label_classes(:name, label_class: 'big')).to eq([ 'big' ])
    end
  end

  describe '#field' do
    it 'renders a label (falling back to the titleized attribute name), the yielded content, and no hint/errors' do
      model = GravFormsTestModel.new(name: 'Ada')
      frag = render_grav_form(model: model, url: '/somewhere') do |f|
        f.field(:name) { f.plain 'content' }
      end

      container = frag.at_css('.field-container')
      expect(container.at_css('label').text).to eq('Name')
      expect(container.text).to include('content')
      expect(container.at_css('.field-hint')).to be_nil
      expect(container.at_css('.form-errors')).to be_nil
    end

    it 'omits the label when skip_label is true' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') do |f|
        f.field(:name, skip_label: true) { f.plain 'content' }
      end
      expect(frag.at_css('.field-container label')).to be_nil
    end

    it 'marks the label optional when optional: true' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') do |f|
        f.field(:name, optional: true) { f.plain 'content' }
      end
      expect(frag.at_css('.form-input-optional').text).to eq(' (optional)')
    end

    it 'renders the field errors and the field-with-errors class when the attribute is invalid' do
      model = GravFormsTestModel.new
      model.errors.add(:name, "can't be blank")
      frag = render_grav_form(model: model, url: '/somewhere') do |f|
        f.field(:name) { f.plain 'content' }
      end

      container = frag.at_css('.field-container')
      expect(container['class']).to include('field-with-errors')
      expect(container.at_css('.form-errors').text).to eq("can't be blank")
    end
  end

  describe '#custom_field' do
    it 'wraps the yielded content in field_classes without a label, hint, or errors' do
      model = GravFormsTestModel.new
      model.errors.add(:name, "can't be blank")
      frag = render_grav_form(model: model, url: '/somewhere') do |f|
        f.custom_field(:name, align: :right) { f.plain 'content' }
      end

      container = frag.at_css('.field-container')
      expect(container['class']).to include('field-align-right')
      expect(container.text).to eq('content')
      expect(container.at_css('label')).to be_nil
    end
  end

  describe '#action_field' do
    it 'renders a non-breaking-space label followed by the yielded content' do
      frag = render_grav_form(url: '/somewhere') do |f|
        f.action_field { f.plain 'content' }
      end

      container = frag.at_css('.field-container')
      expect(container.at_css('label').inner_html).to eq('&nbsp;')
      expect(container.text).to include('content')
    end
  end

  describe '#field_in_label' do
    it 'nests the label text and the yielded content inside the same <label>' do
      model = GravFormsTestModel.new(name: 'Ada')
      frag = render_grav_form(model: model, url: '/somewhere') do |f|
        f.field_in_label(:name) { f.plain 'content' }
      end

      label = frag.at_css('label.field-in-label')
      expect(label.at_css('span').text).to eq('Name')
      expect(label.text).to include('content')
    end

    it 'adds the reverse class when label_first: false' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') do |f|
        f.field_in_label(:name, label_first: false) { f.plain 'content' }
      end
      expect(frag.at_css('label')['class']).to include('field-in-label-reverse')
    end
  end
end
