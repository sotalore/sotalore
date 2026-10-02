# frozen_string_literal: true

# Reviews items' kinds (concrete, group, archetype, category), with the
# evidence for each, and changes them in place.
class Adm::ItemReviewsController < AdmController

  def index
    authorize(:item_review)
    review = ItemReview.new(filter: params[:filter], issues_only: params[:issues].present?,
                            query: params[:q])
    rows = Kaminari.paginate_array(review.rows).page(params[:page]).per(50)
    page_title 'Item Review'
    render Views::Adm::ItemReviews::Index.new(review: review, rows: rows, counts: ItemReview.counts)
  end

  def update
    authorize(:item_review)
    item = Item.find(params[:id])
    kind = params.require(:kind).presence_in(Item.kinds.keys) or
      raise ActionController::BadRequest, 'unknown kind'

    item.kind = kind
    cleared_price = item.abstract? && item.price
    item.price = nil if cleared_price
    if item.save
      RevisionRecorder.call(item, Current.user)
      notice = "#{item.name} is now #{item.kind_label}."
      notice += ' Its price was cleared.' if cleared_price
      redirect_back_or_to adm_item_reviews_path, notice: notice
    else
      redirect_back_or_to adm_item_reviews_path,
                          alert: "Couldn't change #{item.name}: #{item.errors.full_messages.to_sentence}"
    end
  end

end
