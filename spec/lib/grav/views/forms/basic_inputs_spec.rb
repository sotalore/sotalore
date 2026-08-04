# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::BasicInputs do
  describe '#text_field' do
    it 'renders a labeled text input carrying the current value' do
      model = GravFormsTestModel.new(name: 'Ada')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.text_field(:name) }

      input = frag.at_css('input[type="text"]')
      expect(input['id']).to eq('grav_forms_test_model_name')
      expect(input['name']).to eq('grav_forms_test_model[name]')
      expect(input['value']).to eq('Ada')
      expect(input['class']).to eq('field-input')
    end

    it 'stringifies a nil attribute to an empty value' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| f.text_field(:name) }
      expect(frag.at_css('input[type="text"]')['value']).to eq('')
    end

    it 'passes extra HTML attributes straight through' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') do |f|
        f.text_field(:name, placeholder: 'Search...', autofocus: true)
      end
      input = frag.at_css('input[type="text"]')
      expect(input['placeholder']).to eq('Search...')
      expect(input.key?('autofocus')).to be true
    end
  end

  describe '#number_field / #email_field / #password_field' do
    { number_field: 'number', email_field: 'email', password_field: 'password' }.each do |method, type|
      it "renders a type=\"#{type}\" input" do
        frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| f.public_send(method, :name) }
        expect(frag.at_css("input[type=\"#{type}\"]")).to be_present
      end
    end
  end

  describe '#date_field' do
    it 'formats a Date value as YYYY-MM-DD, matching the HTML date input format' do
      model = GravFormsTestModel.new(close_date: Date.new(2024, 1, 5))
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.date_field(:close_date) }
      expect(frag.at_css('input[type="date"]')['value']).to eq('2024-01-05')
    end

    it 'leaves a blank attribute as an empty value' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| f.date_field(:close_date) }
      expect(frag.at_css('input[type="date"]')['value']).to eq('')
    end
  end

  describe '#color_field' do
    it 'renders the input nested inside the label, via field_in_label' do
      frag = render_grav_form(model: GravFormsTestModel.new(name: '#ff0000'), url: '/somewhere') do |f|
        f.color_field(:name)
      end
      label = frag.at_css('label.field-in-label')
      expect(label.at_css('input[type="color"]')['value']).to eq('#ff0000')
    end
  end

  describe '#text_area_field' do
    it "renders a textarea with the attribute's current value as its content" do
      model = GravFormsTestModel.new(name: "line one\nline two")
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.text_area_field(:name) }
      expect(frag.at_css('textarea').text).to eq("line one\nline two")
    end

    it 'excludes framework-only options (like :hint) from the rendered attributes' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') do |f|
        f.text_area_field(:name, hint: 'a hint')
      end
      textarea = frag.at_css('textarea')
      expect(textarea.key?('hint')).to be false
      expect(frag.at_css('.field-hint').text).to eq('a hint')
    end
  end

  describe '#file_field' do
    it 'always renders a nil value, regardless of the model attribute' do
      model = GravFormsTestModel.new(name: 'should-not-appear')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.file_field(:name) }
      expect(frag.at_css('input[type="file"]')['value']).to be_nil
    end

    it 'marks the form for multipart encoding, so uploads actually work' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| f.file_field(:name) }
      expect(frag.at_css('form')['enctype']).to eq('multipart/form-data')
    end
  end

  describe '#hidden_tag' do
    it 'renders a bare hidden input, not wrapped in a field/label' do
      frag = render_grav_form(model: GravFormsTestModel.new(id: 5), url: '/somewhere') { |f| f.hidden_tag(:id) }
      input = frag.at_css('input[type="hidden"][name="grav_forms_test_model[id]"]')
      expect(input['value']).to eq('5')
      expect(frag.at_css('.field-container')).to be_nil
    end
  end

  describe '#labelled_value_field' do
    it 'wraps the yielded content in a .labelled-value div, inside the normal field wrapper' do
      frag = render_grav_form(model: GravFormsTestModel.new(name: 'Ada'), url: '/somewhere') do |f|
        f.labelled_value_field(:name) { f.plain f.model.name }
      end
      expect(frag.at_css('.field-container label').text).to eq('Name')
      expect(frag.at_css('.labelled-value').text).to eq('Ada')
    end
  end

  describe '#input_of_type / NON_HTML_OPTIONS filtering' do
    it 'does not leak framework-only options onto the rendered tag' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') do |f|
        f.text_field(:name, hint: 'a hint', align: :right, skip_label: true)
      end
      input = frag.at_css('input[type="text"]')
      %w[hint align skip_label].each { |attr| expect(input.key?(attr)).to be false }
    end
  end
end
