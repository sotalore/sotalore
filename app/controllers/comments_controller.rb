# frozen-string-literal: true

class CommentsController < ApplicationController
  include RecaptchaHelper

  before_action :find_parent

  def index
    @comments = find_comments_index
    authorize @comments
  end

  def new
    @comment = @parent.comments.build(author: current_user)
    authorize @comment
  end

  def create
    @comment = @parent.comments.build(permitted_params)
    @comment.author = current_user
    @comment.comment_type = 'message'
    authorize @comment

    action = [ "new-comment", @parent.class.name ].compact.join('-')
    success = !require_recaptcha? || verify_recaptcha(action: action, minimum_score: 0.5)
    checkbox_success = verify_recaptcha unless success

    if success || checkbox_success
      if @comment.save
        redirect_to url_for_parent
      else
        @comments = find_comments_index
        render :index
      end
    else
      if !success
        @show_checkbox_recaptcha = true
      end
      @comments = find_comments_index
      render :index
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
      redirect_to url_for_parent
    else
      render :edit
    end
  end

  def destroy
    @comment = find_comment
    authorize @comment
    @comment.destroy
    redirect_to url_for_parent
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
