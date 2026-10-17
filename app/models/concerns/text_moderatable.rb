module TextModeratable
  extend ActiveSupport::Concern

  included do
    before_save :moderate_text_content, if: :should_moderate?
    scope :moderation_pending, -> { where(moderation_status: "review") }
    scope :moderation_blocked, -> { where(moderation_status: "block") }
    scope :moderation_pass, -> { where(moderation_status: "pass") }
  end

  private

  def should_moderate?
    return false unless TextModerationService.enabled?
    has_text_change = new_record? || begin
      (respond_to?(:title_changed?) && title_changed?) || (respond_to?(:content_changed?) && content_changed?)
    end
    return false unless has_text_change
    return false if respond_to?(:published_by_operational?) && published_by_operational?

    text_to_check.present?
  end

  def text_to_check
    if respond_to?(:title) && respond_to?(:content)
      "#{title} #{content}"
    elsif respond_to?(:content)
      content
    else
      nil
    end
  end

  def moderate_text_content
    text = text_to_check
    return unless text.present?

    data_id = "#{self.class.name.downcase}-#{SecureRandom.hex(8)}"

    result = TextModerationService.check(text, data_id: data_id)

    if result
      assign_moderation_result(result)

      if result.suggestion == "Block"
        errors.add(:base, "内容包含违规信息（#{TextModerationService.label_name(result.label)}），禁止发布。如有疑问请联系管理员。")
      end
    else
      # API 调用失败时，标记为待人工审核，防止违规内容漏网
      Rails.logger.warn "[TextModeratable] #{self.class}##{id || 'new'} API 调用失败(#{TextModerationService.last_error})，标记为待审核"
      self.moderation_status = "review"
      self.moderation_label = "Unknown"
      self.moderation_checked_at = Time.current
    end
  rescue => e
    Rails.logger.error "[TextModeratable] #{self.class}##{id} 审核异常: #{e.message}"
  end

  def assign_moderation_result(result)
    self.moderation_status = case result.suggestion
                             when "Block" then "block"
                             when "Review" then "review"
                             else "pass"
                             end
    self.moderation_label = result.label
    self.moderation_sub_label = result.sub_label
    self.moderation_score = result.score
    self.moderation_keywords = result.keywords
    self.moderation_checked_at = Time.current
  end
end
