# frozen-string-literal: true

class CommentsController < ApplicationController
  include TurnstileHelper
  include CloudflareTurnstile

  before_action :find_parent

  def show
    @comment = find_comment
    authorize @comment
    respond_to do |format|
      format.html { redirect_to url_for_parent }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(@comment, partial: 'comments/comment', locals: { comment: @comment })
      }
    end
  end

  def index
    @comments = find_comments_index
    authorize @comments
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
    render action: :index
  end

  def new
    @comment = @parent.comments.build(author: current_user)
    authorize @comment
  end

  def create
    @comment = @parent.comments.build(permitted_params)
    @comment.author = Current.user
    @comment.comment_type = 'message'
    authorize @comment

    submit_allowed = !require_turnstile? || verify_turnstile(params)

    if submit_allowed
      if @comment.save
        respond_to do |format|
          format.html { redirect_to url_for_parent }
          format.turbo_stream { render }
        end
      else
        @comments = find_comments_index
        render :index, status: :unprocessable_entity
      end
    else
      @comments = find_comments_index
      render :index, status: :unprocessable_entity
    end
  end

  def edit
    @comment = find_comment
    authorize @comment
  end

  def update
    @comment = find_comment
    authorize @comment
    if @comment.update(permitted_params)
      respond_to do |format|
        format.html { redirect_back(fallback_location: url_for_parent) }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@comment, @comment) }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment = find_comment
    authorize @comment
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to url_for_parent }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@comment) }
    end
  end

  private

  def find_parent
    if params[:item_id]
      @parent = Item.find(params[:item_id])
    elsif params[:recipe_id]
      @parent = Recipe.find(params[:recipe_id])
    elsif params[:scene_id]
      @parent = Scene.find(params[:scene_id])
    elsif params[:top_post_id]
      @parent = TopPost.find(params[:top_post_id])
    end

    @scope = @parent ? @parent.comments : Comment.all
    if !current_user.moderator?
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

  def permitted_params
    params.require(:comment).permit(policy(@comment || Comment).permitted_attributes)
  end

  def url_for_parent
    case @parent
    when TopPost
      root_path
    else
      @parent
    end
  end
end
