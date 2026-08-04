# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::Radios do
  describe '#radio' do
    it 'raises for the common case: an unselected radio rendered with no explicit :checked option' do
      # radio's trailing (post-render) checked/unchecked block references a bare
      # NOT_CHECKED_VALUES constant, but that constant is defined in CheckBoxes,
      # a sibling module -- not an ancestor of Radios and not in its lexical
      # scope, so Ruby can't resolve it there. It only avoids the crash when
      # :checked is passed explicitly, or the value happens to match the
      # current one (both make `options.key?(:checked)` true by the time that
      # second block runs). This spec pins the crash down for the ordinary
      # "render the other options in the group" case.
      model = GravFormsTestModel.new(role: 'admin')
      expect {
        render_grav_form(model: model, url: '/somewhere') { |f| f.radio(:role, 'editor') }
      }.to raise_error(NameError, /NOT_CHECKED_VALUES/)
    end

    it 'is checked when the value matches the current attribute (this path does not hit the bug above)' do
      model = GravFormsTestModel.new(role: 'admin')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.radio(:role, 'admin') }
      expect(frag.at_css('input[type="radio"]')['checked']).to eq('checked')
    end

    it 'renders the id as "<field id>_<sanitized value>"' do
      model = GravFormsTestModel.new(role: 'admin')
      # checked: false sidesteps the bug above -- this example is only about id formatting.
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.radio(:role, 'Site Admin.x', checked: false) }
      expect(frag.at_css('input[type="radio"]')['id']).to eq('grav_forms_test_model_role_site_admin_x')
    end

    it 'shares the plain (non-array) attribute name across the group' do
      model = GravFormsTestModel.new(role: 'admin')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.radio(:role, 'admin') }
      expect(frag.at_css('input[type="radio"]')['name']).to eq('grav_forms_test_model[role]')
    end

    it 'honors an explicit checked: true regardless of the current value (and avoids the bug above)' do
      model = GravFormsTestModel.new(role: 'admin')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.radio(:role, 'editor', checked: true) }
      expect(frag.at_css('input[type="radio"]')['checked']).to eq('checked')
    end

    it 'honors an explicit checked: false even when the value matches the current one' do
      model = GravFormsTestModel.new(role: 'admin')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.radio(:role, 'admin', checked: false) }
      expect(frag.at_css('input[type="radio"]')['checked']).to be_nil
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
