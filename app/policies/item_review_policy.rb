# frozen-string-literal: true

# Root reviews items' kinds; AI accounts can read the lists (through the
# read-only API) and propose changes.
class ItemReviewPolicy < DefaultAdminPolicy

  def index?
    super || user.bot?
  end

end
