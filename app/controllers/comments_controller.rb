class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_topic

  def create
    if current_user.student? && !current_user.student_of?(@topic.node)
      redirect_to_topic @topic, alert: t("flash.comments.no_permission")
      return
    end

    @comment = @topic.comments.build(comment_params)
    @comment.user = current_user
    if @comment.save
      if parent_comment?
        Notification.notify!(user: @comment.parent.user, actor: current_user, notifiable: @comment, notify_type: :new_reply)
      else
        Notification.notify!(user: @topic.user, actor: current_user, notifiable: @comment, notify_type: :new_comment)
      end
      redirect_to_topic @topic, notice: parent_comment? ? t("flash.comments.reply_success") : t("flash.comments.created")
    else
      redirect_to_topic @topic, alert: t("flash.comments.blank")
    end
  end

  def destroy
    @comment = @topic.comments.find(params[:id])
    if @comment.user == current_user || current_user.admin?
      @comment.destroy
      redirect_to_topic @topic, notice: t("flash.deleted")
    else
      redirect_to_topic @topic, alert: t("flash.forbidden")
    end
  end

  def toggle_login_only
    @comment = @topic.comments.find(params[:id])
    if @comment.user == current_user
      @comment.update!(login_only: !@comment.login_only)
      redirect_to_topic @topic, notice: @comment.login_only ? t("flash.comments.login_only_enabled") : t("flash.comments.login_only_disabled")
    else
      redirect_to_topic @topic, alert: t("flash.forbidden")
    end
  end

  private

  def set_topic
    @topic = Topic.find_by!(id: params[:topic_id])
  end

  def parent_comment?
    params[:comment][:parent_id].present?
  end

  def comment_params
    params.require(:comment).permit(:content, :parent_id, :login_only, :vip_only)
  end
end
