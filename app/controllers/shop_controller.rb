class ShopController < ApplicationController
  before_action :authenticate_user!
  before_action :check_shop_enabled

  def index
    @shop_items = ShopItem.active.sorted
    @purchases = current_user.purchases.recent.limit(20)
  end

  def purchase
    @shop_item = ShopItem.active.find_by(id: params[:id])

    unless @shop_item
      redirect_to "/shop", alert: t("flash.shop.item_not_found")
      return
    end

    unless @shop_item.available?
      redirect_to "/shop", alert: t("flash.shop.item_unavailable")
      return
    end

    if @shop_item.item_type == "license" && params[:domain].blank?
      redirect_to "/shop", alert: t("flash.shop.domain_required")
      return
    end

    if current_user.points < @shop_item.price
      redirect_to "/shop", alert: t("flash.shop.insufficient_points", price: @shop_item.price, balance: current_user.points)
      return
    end

    ActiveRecord::Base.transaction do
      purchase = current_user.purchases.create!(
        shop_item: @shop_item,
        points_cost: @shop_item.price,
        status: :completed
      )

      current_user.decrement!(:points, @shop_item.price)

      begin
        @shop_item.deliver!(current_user, purchase, domain: params[:domain] || request.host)
      rescue StandardError => e
        current_user.increment!(:points, @shop_item.price)
        purchase.update!(status: :failed, delivered_data: { error: e.message })
        redirect_to "/shop", alert: t("flash.shop.purchase_failed", message: e.message)
        return
      end

      @purchase = purchase
      redirect_to "/shop", notice: t("flash.shop.purchased", price: @shop_item.price)
    end
  end

  private

  def check_shop_enabled
    unless Plugin.enabled.where(identifier: "shop").exists?
      redirect_to root_path, alert: t("flash.shop.disabled")
    end
  end
end
