class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_topic

  def create
    favorite = @topic.favorites.build(user: current_user)
    if favorite.save
      redirect_back fallback_location: @topic, notice: t("flash.favorites.created")
    else
      redirect_back fallback_location: @topic, alert: favorite.errors.full_messages.join(", ")
    end
  end

  def destroy
    favorite = @topic.favorites.find_by(user: current_user)
    if favorite&.destroy
      redirect_back fallback_location: @topic, notice: t("flash.favorites.removed")
    else
      redirect_back fallback_location: @topic, alert: t("flash.favorites.not_found")
    end
  end

  private

  def set_topic
    @topic = Topic.find(params[:topic_id])
  end
end
