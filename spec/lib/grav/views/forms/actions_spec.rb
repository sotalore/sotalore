# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::Actions do
  describe '#form_actions, #cancel_button, #submit_button' do
    it 'wraps actions in a form-actions div' do
      frag = render_grav_form(url: '/somewhere') { |f| f.form_actions { f.plain 'x' } }
      expect(frag.at_css('.form-actions')).to be_present
    end

    it 'labels the submit button "Create" for a new record by default' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| f.submit_button }
      expect(frag.at_css('input[type="submit"]')['value']).to eq('Create')
    end

    it 'labels the submit button "Update" for a persisted record by default' do
      frag = render_grav_form(model: GravFormsTestModel.new(id: 1), url: '/somewhere') { |f| f.submit_button }
      expect(frag.at_css('input[type="submit"]')['value']).to eq('Update')
    end

    it 'labels the submit button "Submit" when there is no model' do
      frag = render_grav_form(url: '/somewhere') { |f| f.submit_button }
      expect(frag.at_css('input[type="submit"]')['value']).to eq('Submit')
    end

    it 'accepts an explicit submit button label' do
      frag = render_grav_form(url: '/somewhere') { |f| f.submit_button('Go') }
      expect(frag.at_css('input[type="submit"]')['value']).to eq('Go')
    end

    it "cancel_button links to the model's polymorphic path by default" do
      scene = create(:scene)
      frag = render_grav_form(model: scene) { |f| f.cancel_button }
      link = frag.at_css('a.form-cancel-button')
      expect(link['href']).to eq(Rails.application.routes.url_helpers.scene_path(scene))
      expect(link.text).to eq('Cancel')
    end

    it 'cancel_button prefers an explicit cancel_url over the polymorphic fallback' do
      scene = create(:scene)
      frag = render_grav_form(model: scene, cancel_url: '/elsewhere') { |f| f.cancel_button }
      expect(frag.at_css('a.form-cancel-button')['href']).to eq('/elsewhere')
    end
  end
end
