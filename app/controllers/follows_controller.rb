class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_followed_user

  def create
    current_user.active_follows.create!(followed: @followed_user)
    Notification.notify!(user: @followed_user, actor: current_user, notifiable: @followed_user, notify_type: :new_follower)
    redirect_back fallback_location: root_path, notice: t("flash.follows.created")
  end

  def destroy
    follow = current_user.active_follows.find_by!(followed: @followed_user)
    follow.destroy!
    redirect_back fallback_location: root_path, notice: t("flash.follows.removed")
  end

  private

  def set_followed_user
    @followed_user = User.find(params[:id])
  end
end
