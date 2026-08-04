# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::Errors do
  describe '#errors_on?' do
    it 'is false when the model has no errors on that attribute' do
      form = GravFormsTestForm.new(model: GravFormsTestModel.new)
      expect(form.errors_on?(:name)).to be_falsey
    end

    it 'is true when the model has an error on that attribute' do
      model = GravFormsTestModel.new
      model.errors.add(:name, "can't be blank")
      form = GravFormsTestForm.new(model: model)
      expect(form.errors_on?(:name)).to be true
    end

    it 'honors :errors_from to check a different attribute than it renders under' do
      model = GravFormsTestModel.new
      model.errors.add(:email, "is invalid")
      form = GravFormsTestForm.new(model: model)
      expect(form.errors_on?(:contact, errors_from: :email)).to be true
    end
  end

  describe '#errors_for / #error_messages' do
    it 'renders nothing when the attribute has no errors' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| f.errors_for(:name) }
      expect(frag.at_css('.form-errors')).to be_nil
    end

    it "renders the attribute's error messages joined together" do
      model = GravFormsTestModel.new
      model.errors.add(:name, "can't be blank")
      model.errors.add(:name, "is too short")
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.errors_for(:name) }
      expect(frag.at_css('.form-errors').text).to eq("can't be blank; is too short")
    end

    it 'renders nothing when the model has no errors at all' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| f.error_messages }
      expect(frag.at_css('.form-errors-summary')).to be_nil
    end

    it 'summarizes every error on the model, including :base errors' do
      model = GravFormsTestModel.new
      model.errors.add(:base, 'is somehow wrong overall')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.error_messages }
      summary = frag.at_css('.form-errors-summary')
      expect(summary.at_css('h4').text).to match(/could not be saved/)
      expect(summary.css('li').map(&:text)).to include('is somehow wrong overall')
    end
  end
end
