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
        render turbo_stream: turbo_stream.replace(@comment, Components::Comments::Card.new(comment: @comment, parent: @parent))
      }
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
    @comment = build_comment(author: current_user)
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
        respond_to do |format|
          format.html { redirect_to url_for_parent }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.prepend('comments', Components::Comments::Card.new(comment: @comment, parent: @parent)),
              turbo_stream.replace('new_comment', Components::Comments::Form.new(subject: @parent, comment: Comment.new))
            ]
          end
        end
      else
        respond_to do |format|
          format.html { render Views::Comments::New.new(comment: @comment), status: :unprocessable_content }
          format.turbo_stream do
            render(status: :unprocessable_content, turbo_stream: turbo_stream.replace('new_comment', Components::Comments::Form.new(subject: @parent, comment: @comment)))
          end
        end
      end
    else
      @comments = find_comments_index
      render Views::Comments::Index.new(comments: @comments, parent: @parent), status: :unprocessable_content
    end
  end

  def edit
    @comment = find_comment
    authorize @comment
    respond_to do |format|
      format.html { render Views::Comments::Edit.new(comment: @comment) }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace([ @comment, :editable ], Components::Comments::Form.new(subject: @parent, comment: @comment))
        ]
      end
    end
  end

  def update
    @comment = find_comment
    authorize @comment
    if @comment.update(permitted_params)
      respond_to do |format|
        format.html { redirect_back(fallback_location: url_for_parent) }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@comment, Components::Comments::Card.new(comment: @comment, parent: @parent)) }
      end
    else
      render Views::Comments::Edit.new(comment: @comment), status: :unprocessable_content
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
    elsif params[:front_page]
      @parent = :front_page
    end

    @scope = Comment.for_subject(@parent)
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
