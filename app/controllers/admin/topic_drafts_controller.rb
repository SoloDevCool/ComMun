class Admin::TopicDraftsController < ApplicationController
  layout "admin"

  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_draft, only: [ :edit, :update, :destroy, :publish ]

  def edit
    @nodes = Node.system_ordered + Node.interest_ordered
  end

  def update
    if @draft.update(draft_params)
      redirect_to admin_topic_operations_path, notice: t("admin.flash.m111", title: @draft.title)
    else
      @nodes = Node.system_ordered + Node.interest_ordered
      flash.now[:alert] = "更新失败：#{@draft.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @draft.destroy
      redirect_to admin_topic_operations_path, notice: t("admin.flash.m110", title: @draft.title)
    else
      redirect_to admin_topic_operations_path, alert: t("admin.flash.m029")
    end
  end

  def publish
    service = TopicOperationService.new(
      title: @draft.title,
      content: @draft.content,
      node_id: @draft.node_id,
      is_repost: @draft.is_repost,
      source_url: @draft.source_url
    )

    result = service.call

    if result[:success]
      @draft.destroy
      redirect_to admin_topic_operations_path, notice: t("admin.flash.m124", topic_title: result[:topic].title, user_name: result[:user].display_name)
    else
      @nodes = Node.system_ordered + Node.interest_ordered
      flash.now[:alert] = result[:message]
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_draft
    @draft = TopicDraft.find(params[:id])
  end

  def draft_params
    params.require(:topic_draft).permit(:title, :content, :node_id, :is_repost, :source_url)
  end

  def require_admin!
    unless current_user&.admin? || current_user&.operator?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end
end
