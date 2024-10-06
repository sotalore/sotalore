# frozen_string_literal: true

class VerificationsController < ApplicationController

  def index
    authorize :verification
    @verifiables = verifiable_scope
      .all
      .page(params[:page])
  end

  def update
    authorize :verification

    verifiable = find_verifiable
    verifiable.verify!(current_user)

    redirect_to verifiable
  end


  private

  def verifiable_scope
    case params[:collection]
    when 'items'
      Item.for_verification
    when 'recipes'
      Recipe.for_verification
    else
      raise ArgumentError, "Unknown collection: #{params[:collection]}"
    end
  end

  def find_verifiable
    if params[:item_id]
      Item.find(params[:item_id])
    elsif params[:recipe_id]
      Recipe.find(params[:recipe_id])
    else
      raise ArgumentError, "Unknown verifiable: #{params}"
    end
  end

end
