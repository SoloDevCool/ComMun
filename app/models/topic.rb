class Topic < ApplicationRecord
  include TextModeratable
  include PluginHookable

  belongs_to :node, counter_cache: true
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :cools, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :tips, dependent: :destroy
  has_many :topic_energy_unlocks, dependent: :destroy
  has_many :mentions, dependent: :destroy
  # has_one :poll 由 polls 插件挂载（plugins/polls/lib/setup.rb）
  belongs_to :last_reply_user, class_name: "User", optional: true

  validates :title, presence: true, length: { minimum: 4, maximum: 120 }
  validates :content, presence: true, length: { minimum: 10 }
  validates :node, presence: true
  validates :source_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "请输入有效的 URL 地址" }, if: :is_repost?

  scope :pinned_first, -> { order(Arel.sql("CASE WHEN pinned THEN 0 ELSE 1 END"), pinned_at: :desc, last_reply_at: :desc, created_at: :desc) }
  scope :pinned, -> { where(pinned: true) }
  scope :recent, -> { order(Arel.sql("CASE WHEN pinned THEN 0 ELSE 1 END"), last_reply_at: :desc, created_at: :desc) }
  scope :hot, -> { order(Arel.sql("CASE WHEN pinned THEN 0 ELSE 1 END"), comments_count: :desc, cools_count: :desc, created_at: :desc) }
  scope :for_node, ->(slug) { joins(:node).where(nodes: { slug: slug }) }
  scope :from_followed, ->(user) { where(user_id: user.active_follows.select(:followed_id)) }
  scope :not_blocked_by, ->(user) { where.not(user_id: user.active_blocks.select(:blocked_id)) }
  scope :search_by_keyword, ->(keyword) {
    where("topics.title ILIKE ? OR topics.content ILIKE ?", "%#{sanitize_sql_like(keyword)}%", "%#{sanitize_sql_like(keyword)}%")
  }
  scope :trending, -> {
    left_joins(:comments)
      .where(comments: { created_at: 1.day.ago.. })
      .group("topics.id")
      .select("topics.*, COUNT(comments.id) AS trending_score")
      .order(Arel.sql("COUNT(comments.id) DESC, topics.created_at DESC"))
  }
  scope :operational, -> { where(published_by_operational: true) }

  def vip_content_accessible_by?(user)
    return true unless vip_only?
    user&.vip? || user&.admin?
  end

  def energy_blocks
    @energy_blocks ||= begin
      blocks = []
      # 使用 \r?\n 兼容 LF 和 CRLF 换行符
      normalized = content.to_s.gsub(/\r\n/, "\n")
      normalized.scan(/:::energy-required\n(\d+)\n([\s\S]*?):::/).each_with_index do |match, index|
        blocks << { index: index, cost: match[0].to_i, content: match[1].strip }
      end
      blocks
    end
  end

  def energy_block_unlocked?(user, block_index)
    return false unless user
    topic_energy_unlocks.exists?(user: user, block_index: block_index)
  end

  def unlock_energy_block!(user, block_index, cost)
    return false unless user
    block = energy_blocks[block_index]
    if block.nil?
      errors.add(:base, "未找到对应的能量块 (索引: #{block_index})")
      return false
    end
    unless block[:cost] == cost
      errors.add(:base, "能量消耗不匹配，需要 #{block[:cost]} 酷能量")
      return false
    end
    return true if energy_block_unlocked?(user, block_index)

    if user.points < cost
      errors.add(:base, "酷能量不足，需要 #{cost} 酷能量")
      return false
    end

    ActiveRecord::Base.transaction do
      user.decrement!(:points, cost)
      topic_energy_unlocks.create!(user: user, block_index: block_index, energy_cost: cost)
    end
    true
  end

  after_create :process_mentions

  def cooled_by?(user)
    return false if user.nil?
    cools.exists?(user_id: user.id)
  end

  def favorited_by?(user)
    return false if user.nil?
    favorites.exists?(user_id: user.id)
  end

  # 投票关联由 polls 插件挂载（plugins/polls/lib/setup.rb）。
  # 所有访问 poll 关联的入口都以本方法做守卫——
  # 直接检查关联是否真的挂载（而不是仅看插件开关），
  # 避免开关与挂载状态意外不一致时抛 AssociationNotFoundError
  def self.polls_available?
    Plugin.enabled?("polls") && reflect_on_association(:poll).present?
  end

  def has_poll?
    return false unless self.class.polls_available?
    poll.present?
  end

  def voted_poll_by?(user)
    return false if user.nil?
    return false unless self.class.polls_available?
    poll&.voted_by?(user) || false
  end

  def to_param
    if slug.present?
      "#{id}-#{slug}"
    else
      "#{id}-#{title.parameterize}"
    end
  end

  # URL 中使用的 slug，与 ApplicationHelper#topic_path 保持一致：
  # 优先自定义 slug，其次标题 parameterize（中文标题会被剔除非 ASCII 字符），最后 topic-<id>
  def url_slug
    slug.presence || title.parameterize.presence || "topic-#{id}"
  end

  # 正文中的图片 URL 列表（图文列表模式用作缩略图）
  def image_urls
    @image_urls ||= content.to_s.scan(/!\[[^\]]*\]\(([^)\s]+)/).flatten
  end

  def first_image_url
    image_urls.first
  end

  # 正文中的图片数量（图文列表模式显示"图片数"标识）
  def images_count
    image_urls.size
  end

  # 去除 Markdown 语法后的纯文本摘要（图文列表模式显示在标题下方）
  def content_excerpt(length: 80)
    text = content.to_s
      .gsub(/:::energy-required\n\d+\n[\s\S]*?:::/, "")
      .gsub(/!\[[^\]]*\]\([^)]*\)/, "")
      .gsub(/\[([^\]]*)\]\([^)]*\)/, '\1')
      .gsub(/[#>*`~_]+/, "")
      .squish
    text.truncate(length)
  end

  def generate_slug!
    translated = BaiduTranslateService.translate(title)
    self.slug = if translated
      translated.parameterize[0, 80]
    else
      title.parameterize[0, 80]
    end
    self.slug = "topic-#{id}" if slug.blank?
    update_column(:slug, self.slug)
  end

  private

  def process_mentions
    Mention.parse_mentions("#{title} #{content}", user, topic: self)
  end
end
