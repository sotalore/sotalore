# frozen-string-literal: true

# AI accounts and editors propose changes; editors review them, but never
# their own. Authors can see and withdraw their own proposals.
class ProposalPolicy < ApplicationPolicy

  def index?
    user.editor? || user.bot?
  end

  def show?
    user.editor? || own?
  end

  def create?
    user.editor? || user.bot?
  end

  def review?
    user.editor? && !own? && record.pending?
  end

  def accept?
    review?
  end

  def reject?
    review?
  end

  def withdraw?
    own? && record.pending?
  end

  class Scope < Scope
    def resolve
      user.editor? ? scope.all : scope.where(author: user)
    end
  end

  private

  def own?
    record.is_a?(Proposal) && record.author == user
  end

end
