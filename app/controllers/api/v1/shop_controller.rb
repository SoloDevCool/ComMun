class Api::V1::ShopController < Api::V1::BaseController
  before_action :authenticate_user!, only: [:purchase, :purchases]

  # GET /api/v1/shop/items
  def index
    unless shop_enabled?
      return render_success(data: { enabled: false, items: [], balance: current_user&.points, purchases: [] })
    end

    items = ShopItem.active.sorted.map { |item| shop_item_json(item) }
    purchases = current_user ? current_user.purchases.recent.limit(20).map { |p| purchase_json(p) } : []

    render_success(
      data: {
        enabled: true,
        items: items,
        balance: current_user&.points,
        purchases: purchases
      }
    )
  end

  # POST /api/v1/shop/purchase
  # params: { id, domain? } (license 类型商品必须提供 domain)
  def purchase
    unless shop_enabled?
      return render_business_error("商店功能未开启")
    end

    item = ShopItem.active.find_by(id: params[:id])
    return render_not_found("商品不存在") unless item
    return render_business_error("商品暂时无法兑换") unless item.available?

    if item.item_type == "license" && params[:domain].blank?
      return render_business_error("license 类型商品必须填写域名")
    end

    if current_user.points < item.price
      return render_business_error("酷能量不足，还差 #{item.price - current_user.points}")
    end

    purchase = nil
    deliver_error = nil

    ActiveRecord::Base.transaction do
      purchase = current_user.purchases.create!(
        shop_item: item,
        points_cost: item.price,
        status: :completed
      )

      current_user.decrement!(:points, item.price)

      begin
        item.deliver!(current_user, purchase, domain: params[:domain] || request.host)
      rescue StandardError => e
        current_user.increment!(:points, item.price)
        purchase.update!(status: :failed, delivered_data: { error: e.message })
        deliver_error = e.message
      end
    end

    if deliver_error
      return render_error(message: "兑换失败: #{deliver_error}", code: 422)
    end

    render_success(
      data: { purchase: purchase_json(purchase), balance: current_user.reload.points },
      message: "兑换成功，消耗 #{item.price} 酷能量"
    )
  end

  # GET /api/v1/shop/purchases
  def purchases
    records = pagy_results(current_user.purchases.recent)
    render_success(data: records.map { |p| purchase_json(p) })
  end

  private

  def shop_enabled?
    @shop_enabled ||= Plugin.enabled.where(identifier: "shop").exists?
  end

  def shop_item_json(item)
    {
      id: item.id,
      name: item.name,
      item_type: item.item_type,
      price: item.price,
      stock: item.stock,
      icon: item.icon,
      description: item.description,
      available: item.available?
    }
  end

  def purchase_json(purchase)
    {
      id: purchase.id,
      item_name: purchase.shop_item&.name,
      points_cost: purchase.points_cost,
      status: purchase.status,
      delivered_data: purchase.delivered_data,
      created_at: purchase.created_at
    }
  end
end
