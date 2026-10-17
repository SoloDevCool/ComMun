class CourseLesson < ApplicationRecord
  belongs_to :course_chapter

  # 视频附件（本地存储）
  has_one_attached :video

  LESSON_TYPES = {
    "video" => "视频",
    "text"  => "图文",
    "quiz"  => "测验"
  }.freeze

  VIDEO_STORAGE_OPTIONS = {
    "local" => "本地服务器",
    "vod"   => "腾讯云点播"
  }.freeze

  validates :title, presence: true, length: { maximum: 200 }
  validates :lesson_type, presence: true, inclusion: { in: LESSON_TYPES.keys }
  validates :duration, length: { maximum: 20 }
  validates :video_storage, inclusion: { in: VIDEO_STORAGE_OPTIONS.keys }, allow_nil: true

  scope :ordered, -> { order(sort_order: :asc, id: :asc) }

  def lesson_type_label
    LESSON_TYPES[lesson_type] || lesson_type
  end

  def video_storage_label
    VIDEO_STORAGE_OPTIONS[video_storage] || video_storage
  end

  # 是否使用本地视频
  def local_video?
    video_storage == 'local' && video.attached?
  end

  # 是否使用腾讯云点播
  def vod_video?
    video_storage == 'vod' && video_url.present?
  end

  # 获取视频播放地址
  def video_playback_url
    if local_video?
      Rails.application.routes.url_helpers.url_for(video)
    elsif vod_video?
      video_url
    else
      nil
    end
  end
end
