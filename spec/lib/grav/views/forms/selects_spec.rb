# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::Selects do
  describe '#select_field' do
    it 'renders a select with the field id/name, and yields a SelectTag to build the options' do
      model = GravFormsTestModel.new(role: 'admin')
      frag = render_grav_form(model: model, url: '/somewhere') do |f|
        f.select_field(:role) do |select|
          select.options([ %w[Admin admin], %w[Editor editor] ], display: :first, value: :last)
        end
      end

      select = frag.at_css('select')
      expect(select['id']).to eq('grav_forms_test_model_role')
      expect(select['name']).to eq('grav_forms_test_model[role]')
      expect(select.css('option').map { |o| o['value'] }).to eq(%w[admin editor])
      expect(select.at_css('option[value="admin"]')['selected']).to eq('')
      expect(select.at_css('option[value="editor"]').key?('selected')).to be false
    end

    it 'appends [] to the name and renders a leading hidden empty-value input when multiple: true' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') do |f|
        f.select_field(:role, multiple: true) do |select|
          select.options([ %w[Admin admin] ], display: :first, value: :last)
        end
      end

      expect(frag.at_css('select')['name']).to eq('grav_forms_test_model[role][]')
      hidden = frag.at_css('input[type="hidden"][name="grav_forms_test_model[role][]"]')
      expect(hidden['value']).to eq('')
    end

    it 'forwards data/autocomplete/disabled options to the underlying select' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') do |f|
        f.select_field(:role, disabled: true, autocomplete: 'off', data: { controller: 'x' }) do |select|
          select.options([ %w[Admin admin] ], display: :first, value: :last)
        end
      end

      select = frag.at_css('select')
      expect(select.key?('disabled')).to be true
      expect(select['autocomplete']).to eq('off')
      expect(select['data-controller']).to eq('x')
    end
  end

  describe '#state_select_field' do
    it "is not defined at all when the (optional) iso3166 gem isn't installed" do
      # selects.rb only defines state_select_field when `require 'iso3166'`
      # succeeds. This project doesn't depend on iso3166, so the method
      # should never exist here, and calling it fails fast and clearly
      # (NoMethodError) rather than deep inside on a missing ISO3166 constant.
      expect(defined?(ISO3166)).to be_nil
      expect(Grav::Views::Forms::FormBuilder.new(url: '/somewhere')).not_to respond_to(:state_select_field)
      expect {
        render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| f.state_select_field(:role) }
      }.to raise_error(NoMethodError, /state_select_field/)
    end
  end
end
