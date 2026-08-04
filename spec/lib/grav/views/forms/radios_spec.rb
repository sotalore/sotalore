# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::Radios do
  describe '#radio' do
    it 'is checked when the value matches the current attribute' do
      model = GravFormsTestModel.new(role: 'admin')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.radio(:role, 'admin') }
      expect(frag.at_css('input[type="radio"]')['checked']).to eq('checked')
    end

    it 'is unchecked when the value does not match the current attribute' do
      model = GravFormsTestModel.new(role: 'admin')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.radio(:role, 'editor') }
      expect(frag.at_css('input[type="radio"]')['checked']).to be_nil
    end

    it 'renders the id as "<field id>_<sanitized value>"' do
      model = GravFormsTestModel.new(role: 'admin')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.radio(:role, 'Site Admin.x') }
      expect(frag.at_css('input[type="radio"]')['id']).to eq('grav_forms_test_model_role_site_admin_x')
    end

    it 'shares the plain (non-array) attribute name across the group' do
      model = GravFormsTestModel.new(role: 'admin')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.radio(:role, 'admin') }
      expect(frag.at_css('input[type="radio"]')['name']).to eq('grav_forms_test_model[role]')
    end

    it 'honors an explicit checked: true regardless of the current value' do
      model = GravFormsTestModel.new(role: 'admin')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.radio(:role, 'editor', checked: true) }
      expect(frag.at_css('input[type="radio"]')['checked']).to eq('checked')
    end

    it 'honors an explicit checked: false even when the value matches the current one' do
      model = GravFormsTestModel.new(role: 'admin')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.radio(:role, 'admin', checked: false) }
      expect(frag.at_css('input[type="radio"]')['checked']).to be_nil
    end

    it 'does not leak framework-only options onto the rendered radio' do
      model = GravFormsTestModel.new(role: 'admin')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.radio(:role, 'admin', hint: 'a hint') }
      expect(frag.at_css('input[type="radio"]').key?('hint')).to be false
    end
  end

  describe '#radio_field' do
    it 'wraps the radio in a field_in_label with the attribute label' do
      model = GravFormsTestModel.new(role: 'admin')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.radio_field(:role, 'admin') }
      label = frag.at_css('label.field-in-label')
      expect(label.at_css('span').text).to eq('Role')
      expect(label.at_css('input[type="radio"]')).to be_present
    end
  end
end
