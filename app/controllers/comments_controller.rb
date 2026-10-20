# frozen-string-literal: true

class CommentsController < ApplicationController
  include Views::TurnstileHelper
  include CloudflareTurnstile

  before_action :find_parent

  def show
    @comment = find_comment
    authorize @comment
    if turbo_frame_request?
      render_card # Cancelling an edit in place.
    else
      redirect_to url_for_parent
    end
  end

  def index
    @comments = find_comments_index
    authorize @comments
    render Views::Comments::Index.new(comments: @comments, parent: @parent)
  end

  def moderate
    @comments = find_comments_index.message

    unless params[:user_owned].present?
      @comments = @comments.where(author_id: nil)
    end

    unless params[:revealed].present?
      @comments = @comments.where(visible: false)
    end

    authorize @comments
    render Views::Comments::Index.new(comments: @comments, parent: @parent, moderating: true)
  end

  def new
    @comment = build_comment(author: Current.user)
    authorize @comment
    render Views::Comments::New.new(comment: @comment)
  end

  def create
    @comment = build_comment(permitted_params)
    @comment.author = Current.user
    @comment.comment_type = 'message'
    authorize @comment

    submit_allowed = !require_turnstile? || verify_turnstile(params)

    if submit_allowed
      if @comment.save
        # Usually the page the comment was posted from, so Turbo morphs it.
        redirect_to url_for_parent
      else
        render Views::Comments::New.new(comment: @comment), status: :unprocessable_content
      end
    else
      @comments = find_comments_index
      render Views::Comments::Index.new(comments: @comments, parent: @parent), status: :unprocessable_content
    end
  end

  def edit
    @comment = find_comment
    authorize @comment
    render Views::Comments::Edit.new(comment: @comment)
  end

  def update
    @comment = find_comment
    authorize @comment
    if @comment.update(permitted_params)
      if turbo_frame_request?
        render_card # Edited in place.
      elsif params[:comment].key?(:body)
        redirect_to url_for_parent, status: :see_other
      else
        # Hiding or showing it, from wherever it's listed.
        redirect_back fallback_location: url_for_parent, status: :see_other
      end
    else
      render Views::Comments::Edit.new(comment: @comment), status: :unprocessable_content
    end
  end

  def destroy
    @comment = find_comment
    authorize @comment
    @comment.destroy
    redirect_back fallback_location: url_for_parent, status: :see_other
  end

  private

  # For a request from the comment's frame, which takes its body from this.
  def render_card
    render Components::Comments::Card.new(comment: @comment, parent: @parent), layout: false
  end

  def find_parent
    if params[:item_id]
      @parent = Item.find(params[:item_id])
    elsif params[:recipe_id]
      @parent = Recipe.find(params[:recipe_id])
    elsif params[:scene_id]
      @parent = Scene.find(params[:scene_id])
    elsif params[:front_page]
      @parent = :front_page
    end

    @scope = Comment.for_subject(@parent)
    if !Current.user.moderator?
      @scope = @scope.where(visible: true)
    end
  end

  def find_comments_index
    @comments = @scope.order(id: :desc)
      .includes(:subject, :actual_author)
      .page(params[:page])
  end

  def find_comment
    @comment = Comment.find(params[:id])
    @parent  ||= @comment.subject
    @comment
  end

  def build_comment(params)
    if @parent == :front_page
      @comment = Comment.new(params)
    else
      @comment = @parent.comments.build(params)
    end
  end

  def permitted_params
    params.require(:comment).permit(policy(@comment || Comment).permitted_attributes)
  end

  def url_for_parent
    case @parent
    when :front_page, nil
      root_path
    else
      @parent
    end
  end
end
