class PollsController < ApplicationController
  # 投票功能插件（plugins/polls）
  before_action :authenticate_user!
  before_action :require_plugin_enabled!
  before_action :set_topic
  before_action :set_poll, only: [:close, :open, :destroy]

  def create
    @poll = @topic.build_poll(poll_params)
    if @poll.save
      redirect_to_topic @topic, notice: t("flash.polls.created")
    else
      redirect_to_topic @topic, alert: t("flash.polls.failed", errors: @poll.errors.full_messages.join(t("flash.join_comma")))
    end
  end

  def vote
    unless @topic.poll
      render json: { error: "该主题没有投票" }, status: :unprocessable_entity
      return
    end

    poll = @topic.poll
    if poll.closed?
      render json: { error: "投票已结束" }, status: :unprocessable_entity
      return
    end

    if poll.topic.user == current_user
      render json: { error: "不能给自己的投票投票" }, status: :unprocessable_entity
      return
    end

    poll_option = poll.poll_options.find_by(id: params[:poll_option_id])
    unless poll_option
      render json: { error: "投票选项不存在" }, status: :not_found
      return
    end

    vote = poll_option.votes.build(user: current_user)
    if vote.save
      poll.reload
      options_data = poll.poll_options.map do |o|
        { id: o.id, title: o.title, votes_count: o.votes_count, percentage: o.vote_percentage }
      end
      Notification.notify!(user: poll.topic.user, actor: current_user, notifiable: poll_option, notify_type: :topic_vote)
      render json: {
        success: true,
        voted: true,
        total_votes: poll.total_votes,
        options: options_data
      }
    else
      render json: { error: vote.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def close
    authorize_poll!
    @poll.close!
    redirect_back fallback_location: topic_location(@topic), notice: t("flash.polls.closed")
  end

  def open
    authorize_poll!
    @poll.open!
    redirect_back fallback_location: topic_location(@topic), notice: t("flash.polls.reopened")
  end

  def destroy
    authorize_poll!
    @poll.destroy
    redirect_back fallback_location: topic_location(@topic), notice: t("flash.polls.deleted")
  end

  private

  def set_topic
    @topic = Topic.find(params[:topic_id])
  end

  def set_poll
    @poll = @topic.poll
  end

  def poll_params
    params.require(:poll).permit(
      poll_options_attributes: [:title]
    )
  end

  def authorize_poll!
    # 话题作者 / 管理员级角色 / 被授予 polls.manage 权限点的角色
    return if @poll.topic.user == current_user
    return if current_user&.can?("polls.manage")
    redirect_to_topic @topic, alert: t("flash.forbidden")
  end

  def require_plugin_enabled!
    unless Plugin.enabled?("polls")
      redirect_to_topic @topic, alert: "投票插件未启用"
    end
  end
end
