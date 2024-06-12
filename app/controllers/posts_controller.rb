class PostsController < ApplicationController

  before_action :find_parent

  def index
    @posts = Post.order(id: :desc).page(params[:page])
    authorize Post
  end

  def show
    @post = Post.find(params[:id])
    authorize @post
  end

  def new
    @post = (@parent&.posts || Post).new
    authorize @post
  end

  def create
    @post = (@parent&.posts || Post).new(post_params)
    @post.author = current_user
    authorize @post
    if @post.save
      redirect_to polymorphic_path([@parent, @post])
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @post = Post.find(params[:id])
    authorize @post
  end

  def update
    @post = Post.find(params[:id])
    authorize @post
    if @post.update(post_params)
      redirect_to posts_path
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @post = Post.find(params[:id])
    authorize @post
    @post.destroy
    redirect_to posts_path
  end

  protected
  def post_params
    params.require(:post).permit(:title, :content, :status)
  end

  def find_parent
    if params[:scene_id]
      @parent = Scene.find(params[:scene_id])
    end
  end
end
