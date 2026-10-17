class ShopItem < ApplicationRecord
  has_many :purchases, dependent: :destroy

  validates :name, presence: true
  validates :price, numericality: { greater_than: 0 }
  validates :item_type, presence: true

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order(sort_order: :asc, created_at: :desc) }

  ITEM_TYPES = %w[virtual license].freeze
  ITEM_TYPE_LABELS = { "virtual" => "虚拟商品", "license" => "授权许可" }.freeze

  def item_type_label
    ITEM_TYPE_LABELS[item_type] || item_type
  end

  def available?
    active? && (stock == -1 || stock > 0)
  end

  def deliver!(user, purchase, **options)
    case item_type
    when "license"
      deliver_license(user, purchase, domain: options[:domain])
    else
      purchase.update!(completed_at: Time.current, delivered_data: { note: "虚拟商品已发放" })
    end
  end

  private

  def deliver_license(user, purchase, domain: nil)
    plan = metadata["plan"] || "free"

    # commun 采用完全离线授权：授权方使用离线签发工具（license-server/bin/generate_license）
    # 绑定用户设备指纹签发许可证文件，用户在后台「系统设置」中粘贴许可证文件完成本地激活。
    purchase.update!(
      completed_at: Time.current,
      delivered_data: {
        license_key: nil,
        domain: domain || metadata["domain"].presence || "localhost",
        plan: plan,
        note: "请提供本机设备指纹（后台「系统设置 → License 授权」页面可查看）给授权方，获取许可证文件后在后台粘贴完成离线激活"
      }
    )
  end
end
