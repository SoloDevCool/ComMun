class Admin::CommentOperationsController < ApplicationController
  layout "admin"
  include Pagy::Method

  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @scope = params[:scope].presence || "all"
    collection = Comment.joins(:topic).where(comments: { published_by_operational: true }).includes(:user, :topic)
    if @scope == "root"
      collection = collection.where(parent_id: nil)
    elsif @scope == "reply"
      collection = collection.where.not(parent_id: nil)
    end
    @pagy, @comments = pagy(:offset, collection.order(created_at: :desc), limit: 15)
    @operational_count = User.operational.count
  end

  def new
    @topics = Topic.includes(:user, :node, :comments).order(created_at: :desc).limit(100)
    @comment = Comment.new
  end

  def ai_generate
    task_id = SecureRandom.uuid

    AiGenerateJob.perform_later(
      task_id: task_id,
      type: "comment",
      topic_id: params[:topic_id],
      parent_id: params[:parent_id],
      system_prompt: params[:system_prompt],
      web_search: params[:web_search] == "true"
    )

    render json: { success: true, task_id: task_id }
  end

  def ai_status
    task_id = params[:task_id]
    cached = Rails.cache.read("ai_generate:#{task_id}")

    if cached.nil?
      render json: { status: "pending" }
    elsif cached[:status] == "running"
      render json: { status: "running" }
    else
      result = cached[:result]
      if result[:success]
        render json: { status: "completed", success: true, content: result[:content] }
      else
        render json: { status: "completed", success: false, error: result[:error] }
      end
    end
  end

  def create
    service = CommentOperationService.new(
      topic_id: params[:comment][:topic_id],
      content: params[:comment][:content],
      parent_id: params[:comment][:parent_id].presence
    )

    result = service.call

    @topics = Topic.includes(:user, :node, :comments).order(created_at: :desc).limit(100)
    @comment = Comment.new(comment_params)

    if result[:success]
      flash.now[:notice] = "评论已通过运营账号「#{result[:user].display_name}」发布到话题「#{result[:topic].title.truncate(20)}」"
    else
      flash.now[:alert] = result[:message]
    end

    render :new, status: result[:success] ? :ok : :unprocessable_entity
  end

  def destroy
    @comment = Comment.find(params[:id])
    if @comment.destroy
      redirect_to admin_comment_operations_path, notice: t("admin.flash.m122")
    else
      redirect_to admin_comment_operations_path, alert: t("admin.flash.m029")
    end
  end

  private

  def require_admin!
    unless current_user&.admin? || current_user&.operator?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end

  def comment_params
    params.require(:comment).permit(:topic_id, :content, :parent_id)
  end
end
