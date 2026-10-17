class NodeFollowsController < ApplicationController
  before_action :authenticate_user!

  def create
    @node = Node.find_by!(slug: params[:node_id])
    return redirect_back fallback_location: topics_path, alert: "系统节点不支持关注" if @node.system?

    current_user.node_follows.create!(node: @node)
    redirect_back fallback_location: topics_path, notice: t("flash.node_follows.created", name: @node.name)
  end

  def destroy
    @node = Node.find_by!(slug: params[:node_id])
    return redirect_back fallback_location: topics_path, alert: "系统节点不支持关注" if @node.system?

    current_user.node_follows.find_by(node: @node)&.destroy
    redirect_back fallback_location: topics_path, notice: t("flash.node_follows.removed", name: @node.name)
  end
end
