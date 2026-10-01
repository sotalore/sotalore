# frozen_string_literal: true

# Adds/removes concrete items to/from groups (abstract items). Each side may
# be given by id (from autocomplete) or by name.
class ItemMembershipsController < ApplicationController

  def create
    membership = ItemMembership.new(group: find_item(:group), member: find_item(:member))
    authorize membership.group || Item, :update?, policy_class: ItemPolicy
    if membership.save
      RevisionRecorder.membership(membership, Current.user, :added)
      flash.notice = "Added #{membership.member} to #{membership.group}."
    else
      flash.alert = membership.errors.full_messages.to_sentence
    end
    redirect_back_or_to(membership.group || items_path)
  end

  def destroy
    membership = ItemMembership.find(params[:id])
    authorize membership.group, :update?, policy_class: ItemPolicy
    membership.destroy!
    RevisionRecorder.membership(membership, Current.user, :removed)
    redirect_back_or_to membership.group, notice: "Removed #{membership.member} from #{membership.group}."
  end

  private

  def membership_params
    params.require(:item_membership).permit(:group_id, :group_name, :member_id, :member_name)
  end

  def find_item(side)
    attrs = membership_params
    if attrs["#{side}_id"].present?
      Item.find_by(id: attrs["#{side}_id"])
    elsif attrs["#{side}_name"].present?
      Item.find_by_name(attrs["#{side}_name"].strip).first
    end
  end
end
