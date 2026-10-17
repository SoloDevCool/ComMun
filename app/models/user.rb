class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:github, :google_oauth2, :gitee]

  has_one_attached :avatar_file

  after_create :generate_default_avatar

  has_many :topics, dependent: :nullify
  has_many :comments, dependent: :nullify
  has_many :active_follows, class_name: "Follow", foreign_key: :follower_id, dependent: :destroy, inverse_of: :follower
  has_many :following, through: :active_follows, source: :followed
  has_many :reverse_follows, class_name: "Follow", foreign_key: :followed_id, dependent: :destroy, inverse_of: :follower
  has_many :followers, through: :reverse_follows, source: :follower
  has_many :node_follows, dependent: :destroy
  has_many :followed_nodes, through: :node_follows, source: :node
  has_many :check_ins, dependent: :destroy
  has_many :cools, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :active_blocks, class_name: "Block", foreign_key: :blocker_id, dependent: :destroy, inverse_of: :blocker
  has_many :blocked_users, through: :active_blocks, source: :blocked
  has_many :reverse_blocks, class_name: "Block", foreign_key: :blocked_id, dependent: :destroy, inverse_of: :blocked
  has_many :blockers, through: :reverse_blocks, source: :blocker
  has_many :notifications, dependent: :destroy
  has_many :topic_energy_unlocks, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :login_logs, class_name: "UserLoginLog", dependent: :destroy
  has_many :qb_practices, dependent: :destroy
  has_many :qb_questions, dependent: :nullify
  belongs_to :invitation_code, optional: true

  # 版块学员关联
  has_many :user_node_memberships, dependent: :destroy
  has_many :member_nodes, through: :user_node_memberships, source: :node

  # 课程观看权限
  has_many :course_permissions, dependent: :destroy
  has_many :authorized_courses, through: :course_permissions, source: :course

  belongs_to :banned_by, class_name: "User", optional: true

  # 角色支持自定义（见 Role 模型）：users.role 存储角色 key（字符串）。
  # 内置角色 key：user / vip / student / operator / admin
  # 兼容性说明：保留原 enum 的 roles 哈希与 admin?/operator?/vip?/student? 谓词；
  # 自定义角色通过 level 权限等级获得对应能力（>=50 运营级，>=100 管理员级）。
  validates :role, presence: true,
                   inclusion: { in: proc { Role.any? ? Role.roles.keys : %w[user] } }
  scope :real_users, -> { where(is_operational: false) }
  scope :operational, -> { where(is_operational: true) }
  scope :online, -> { where.not(last_seen_at: nil).where("last_seen_at > ?", 5.minutes.ago) }
  scope :banned, -> { where.not(banned_at: nil).where("ban_expires_at IS NULL OR ban_expires_at > ?", Time.current) }
  scope :not_banned, -> { where(banned_at: nil).or(where(ban_expires_at: ...Time.current)) }

  validates :username,
    presence: true,
    length: { minimum: 2, maximum: 20 },
    format: { with: /\A[a-zA-Z0-9_\u4e00-\u9fa5]+\z/, message: "只能包含字母、数字、下划线和中文" },
    uniqueness: { case_sensitive: false },
    allow_nil: true

  # 允许通过用户名或邮箱登录
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:email)
    if login.present?
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { value: login.downcase }]).first
    else
      find_by(conditions)
    end
  end

  # ---------- 角色相关（支持自定义角色） ----------

  # 兼容原 enum 提供的 User.roles 哈希
  def self.roles
    Role.any? ? Role.roles : { "user" => "user", "vip" => "vip", "student" => "student", "operator" => "operator", "admin" => "admin" }
  end

  # 兼容原 enum 自动生成的查询 scope（User.real_users.admin 等）
  scope :with_role, ->(key) { where(role: key) }
  scope :admin, -> { with_role("admin") }
  scope :vip, -> { with_role("vip") }
  scope :student, -> { with_role("student") }
  scope :operator, -> { with_role("operator") }
  scope :user, -> { with_role("user") }

  # 当前角色对应的 Role 记录（含内置角色，实例级缓存）
  def role_record
    return @role_record if defined?(@role_record) && @role_record&.key == role
    @role_record = Role.cached_find(role)
  end

  # 权限等级：内置/自定义角色统一从 Role 表读取
  def role_level
    role_record&.level.to_i
  end

  def admin?
    role == "admin" || role_level >= 100
  end

  # 细粒度权限点检查（权限点目录见 Permission，插件可动态注册）：
  #   - 管理员级角色（内置 admin 或 level>=100）拥有全部权限
  #   - 其他角色按角色配置的权限点列表判断
  def can?(key)
    return true if admin?
    return false if role_record.nil?
    role_record.has_permission?(key)
  end

  def operator?
    return true if role == "operator"
    return false if role == "admin" # admin 本身不算 operator，但 admin? 已覆盖全部后台入口
    role_level >= 50
  end

  def vip?
    role == "vip"
  end

  def user?
    role == "user"
  end

  def role_label
    return role_record.name if role_record
    case role
    when "admin" then "管理员"
    when "operator" then "运营"
    when "vip" then "付费会员"
    when "student" then "版块学员"
    else "普通用户"
    end
  end

  def role_badge_class
    return role_record.badge_class if role_record
    case role
    when "admin" then "bg-warning text-dark"
    when "operator" then "bg-primary text-white"
    when "vip" then "bg-danger text-white"
    when "student" then "bg-success text-white"
    else "bg-info"
    end
  end

  def display_name
    username.presence || email.split("@").first
  end

  def avatar_data_url
    if avatar_file.attached?
      Rails.application.routes.url_helpers.rails_blob_path(avatar_file, only_path: true, disposition: "inline")
    elsif avatar_data.present?
      avatar_data
    else
      nil
    end
  end

  def has_avatar?
    avatar_file.attached? || avatar_data.present?
  end

  def followed_by?(user)
    return false if user.nil?
    reverse_follows.exists?(follower_id: user.id)
  end

  def blocked_by?(user)
    return false if user.nil?
    reverse_blocks.exists?(blocker_id: user.id)
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid.to_s).first
  end

  def self.build_from_omniauth(auth)
    placeholder_domain = auth.provider == "google_oauth2" ? "google" : auth.provider
    user = new(
      provider: auth.provider,
      uid: auth.uid.to_s,
      email: auth.info.email || "#{auth.uid}@#{placeholder_domain}.placeholder",
      password: Devise.friendly_token[0, 20]
    )
    user
  end

  def blocked?(user)
    return false if user.nil?
    active_blocks.exists?(blocked_id: user.id)
  end

  def banned?
    return false if banned_at.nil?
    ban_expires_at.nil? || ban_expires_at > Time.current
  end

  def permanently_banned?
    banned? && ban_expires_at.nil?
  end

  def ban!(duration:, reason:, banned_by: nil)
    self.banned_at = Time.current
    self.ban_expires_at = duration == :permanent ? nil : (Time.current + duration)
    self.ban_reason = reason.to_s.strip.presence
    self.banned_by = banned_by
    save!
  end

  def unban!(unbanned_by: nil)
    self.banned_at = nil
    self.ban_expires_at = nil
    self.ban_reason = nil
    self.banned_by = nil
    save!
  end

  def ban_remaining_time
    return nil unless banned?
    return "永久" if ban_expires_at.nil?
    remaining = ((ban_expires_at - Time.current) / 1.day).ceil
    "#{remaining} 天"
  end

  def active_for_authentication?
    super && !banned?
  end

  def inactive_message
    banned? ? :account_banned : super
  end

  # 检查是否为版块学员
  def student?
    role == "student"
  end

  # 检查用户是否为指定版块的学员
  def student_of?(node)
    return false if node.nil?
    user_node_memberships.where(node_id: node.id).where("expires_at IS NULL OR expires_at > ?", Time.current).exists?
  end

  # 获取用户可发帖的版块列表
  def accessible_nodes
    if student?
      member_nodes
    else
      Node.all
    end
  end

  # 检查是否可以发帖到指定版块
  def can_post_to_node?(node)
    return true unless student?
    student_of?(node)
  end

  # 加入版块学员
  def join_node_as_student!(node, expires_at: nil, notes: nil)
    return false unless node.present?

    membership = user_node_memberships.find_or_initialize_by(node: node)
    membership.update!(
      joined_at: Time.current,
      expires_at: expires_at,
      notes: notes
    )
  end

  # 离开版块学员
  def leave_node_as_student!(node)
    membership = user_node_memberships.find_by(node: node)
    membership&.destroy
  end

  # 检查是否可以观看课程视频
  def can_watch_course?(course)
    return true if admin? || operator?
    course_permissions.where(course_id: course.id).exists?
  end

  private

  # 用户名注册时跳过邮箱验证
  def email_required?
    email.present?
  end

  def generate_default_avatar
    MultiavatarService.generate_avatar_for(self)
  rescue StandardError
    nil
  end
end
