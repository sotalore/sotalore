# frozen_string_literal: true

# A minimal ActiveModel-backed stand-in used only to exercise
# Grav::Views::Forms in isolation, independent of any real AR model.
# It supports everything Grav::Views::Forms::Base needs from a "model":
# #model_name (via ActiveModel::Naming), #persisted?, #errors, and plain
# attribute readers/writers.
class GravFormsTestModel
  include ActiveModel::Model

  attr_accessor :id, :name, :email, :count, :accepted, :role, :close_date, :tags

  def persisted?
    id.present?
  end
end
