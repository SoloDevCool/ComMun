# 自定义角色：管理员可在后台「角色管理」中增删改，
# users.role 存储角色的 key（字符串）。
#
# level 权限等级约定：
#   0      普通用户（默认）
#   1-49   自定义展示型角色（仅徽章/名称不同，无后台权限）
#   50-99  运营级（可进入后台进行内容管理）
#   100+   管理员级（拥有后台全部权限）
class Role < ApplicationRecord
  # 徽章样式预设（完整 Bootstrap class）
  BADGE_PRESETS = [
    ["灰色", "bg-secondary text-white"],
    ["蓝色", "bg-primary text-white"],
    ["绿色", "bg-success text-white"],
    ["红色", "bg-danger text-white"],
    ["黄色", "bg-warning text-dark"],
    ["浅蓝", "bg-info text-dark"],
    ["深色", "bg-dark text-white"],
    ["浅灰", "bg-light text-dark"]
  ].freeze

  has_many :users, primary_key: :key, foreign_key: :role, inverse_of: :role_record

  validates :key, presence: true,
                  uniqueness: true,
                  format: { with: /\A[a-z0-9_]+\z/, message: "只允许小写字母、数字和下划线" },
                  length: { maximum: 30 }
  validates :name, presence: true, length: { maximum: 20 }
  validates :badge_class,
            presence: true,
            format: { with: /\Abg-[a-z]+( text-(dark|white))?\z/, message: "格式不正确" }
  validates :level, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  after_commit :clear_cache

  # 兼容原 enum 的 User.roles 哈希（key => key）
  def self.roles
    all_scope = cached_all
    all_scope.each_with_object({}) { |r, h| h[r.key] = r.key }
  end

  def self.exists_with_key?(key)
    cached_all.any? { |r| r.key == key }
  end

  def self.cached_find(key)
    cached_all.find { |r| r.key == key }
  end

  def self.cached_all
    Rails.cache.fetch("roles/all") do
      order(:level, :id).to_a
    end
  end

  def built_in?
    built_in
  end

  # ---------- 权限点 ----------

  def permissions_array
    Array(permissions).map(&:to_s)
  end

  # 是否拥有全部权限（通配符）
  def all_permissions?
    permissions_array.include?("*")
  end

  # 检查角色是否拥有某权限点
  def has_permission?(key)
    return all_permissions? if key.to_s == "*"
    permissions_array.include?(key.to_s)
  end

  # 设置权限点列表（过滤掉未注册的 key）
  def permissions=(keys)
    if keys.is_a?(Array)
      valid = keys.map(&:to_s).select { |k| k == "*" || Permission.valid_key?(k) }.uniq
      super(valid)
    else
      super
    end
  end

  def in_use?
    User.where(role: key).exists?
  end

  def destroyable?
    !built_in? && !in_use?
  end

  private

  def clear_cache
    Rails.cache.delete("roles/all")
  end
end
