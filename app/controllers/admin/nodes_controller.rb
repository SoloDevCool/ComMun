class Admin::NodesController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_node, only: [ :edit, :update, :destroy ]

  def index
    @system_nodes = Node.system_ordered
    @interest_nodes = Node.interest_ordered
  end

  def new
    @node = Node.new
  end

  def create
    @node = Node.new(node_params)
    handle_icon_file_removal(@node)
    if @node.save
      redirect_to admin_nodes_path, notice: t("admin.flash.m097", name: @node.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    handle_icon_file_removal(@node)
    if @node.update(node_params)
      redirect_to admin_nodes_path, notice: t("admin.flash.m099", name: @node.name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @node.destroy
      redirect_to admin_nodes_path, notice: t("admin.flash.m098", name: @node.name)
    else
      redirect_to admin_nodes_path, alert: t("admin.flash.m029")
    end
  end

  def reorder
    params[:node_ids].each_with_index do |id, index|
      Node.where(id: id).update_all(position: index)
    end
    head :ok
  end

  private

  def handle_icon_file_removal(node)
    return unless params.dig(:node, :remove_icon_file) == "1"
    node.icon_file.purge if node.icon_file.attached?
    params[:node].delete(:icon_file)
  end

  def set_node
    @node = Node.find_by!(slug: params[:id])
  end

  def node_params
    params.require(:node).permit(:name, :slug, :icon, :description, :kind, :position, :tip, :icon_file)
  end

  def require_admin!
    unless current_user&.admin? || current_user&.operator?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end
end
