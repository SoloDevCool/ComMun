class Admin::ShopItemsController < Admin::DashboardController
  before_action :set_shop_item, only: [:edit, :update, :destroy, :toggle_active]

  def index
    @shop_items = ShopItem.sorted
    @total_purchases = Purchase.completed.group(:shop_item_id).count
  end

  def new
    @shop_item = ShopItem.new
  end

  def create
    @shop_item = ShopItem.new(shop_item_params)

    if @shop_item.save
      redirect_to admin_shop_items_path, notice: t("admin.flash.m037")
    else
      flash.now[:alert] = "创建失败：#{@shop_item.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @shop_item.update(shop_item_params)
      redirect_to admin_shop_items_path, notice: t("admin.flash.m039")
    else
      flash.now[:alert] = "更新失败：#{@shop_item.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @shop_item.destroy
    redirect_to admin_shop_items_path, notice: t("admin.flash.m038")
  end

  def toggle_active
    if @shop_item.update(active: !@shop_item.active)
      notice = @shop_item.active? ? "商品已上架" : "商品已下架"
      redirect_to admin_shop_items_path, notice: notice
    end
  end

  private

  def set_shop_item
    @shop_item = ShopItem.find(params[:id])
  end

  def shop_item_params
    permitted = params.require(:shop_item).permit(:name, :description, :item_type, :price, :icon, :active, :stock, :sort_order)
    if params[:shop_item][:metadata].present?
      begin
        permitted[:metadata] = JSON.parse(params[:shop_item][:metadata])
      rescue JSON::ParserError
        permitted[:metadata] = {}
      end
    else
      permitted[:metadata] = {}
    end
    permitted
  end
end
