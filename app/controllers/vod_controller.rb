class VodController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_cors_headers
  before_action :require_valid_requester, only: [:psign, :play_url]

  # 获取视频播放地址（通过服务端 DescribeMediaInfos API，支持子应用）
  # 注意：此接口仅限管理后台使用，前台播放请使用 psign + FileID 模式
  def play_url
    file_id = params[:file_id].to_s.strip
    if file_id.blank?
      render json: { error: "缺少 file_id 参数" }, status: :bad_request
      return
    end

    # 仅允许管理员调用此接口
    unless user_signed_in? && current_user.admin?
      render json: { error: "无权访问" }, status: :forbidden
      return
    end

    begin
      result = TencentVodService.get_play_url(file_id)

      if result["Response"] && result["Response"]["Error"]
        code = result["Response"]["Error"]["Code"]
        msg = result["Response"]["Error"]["Message"]
        Rails.logger.error "[VOD] DescribeMediaInfos error: #{code} - #{msg}"
        render json: { error: "视频查询失败: #{msg} (#{code})" }, status: :not_found
        return
      end

      media_info_set = result.dig("Response", "MediaInfoSet")
      if media_info_set.blank? || media_info_set[0].blank?
        render json: { error: "视频不存在" }, status: :not_found
        return
      end

      media = media_info_set[0]
      video_url = nil

      # 优先取转码后的视频地址
      transcode_list = media.dig("TranscodeInfoSet", 0, "TranscodeSet")
      if transcode_list.present?
        # 优先 720P，其次按分辨率降级
        target = transcode_list.find { |t| t["Definition"] == 10 } ||
                 transcode_list.find { |t| t["Definition"] == 20 } ||
                 transcode_list.find { |t| t["Height"] && t["Height"].to_i >= 720 } ||
                 transcode_list[0]
        video_url = target&.dig("Url")
      end

      # 降级取原始视频
      if video_url.blank?
        video_url = media.dig("BasicInfo", "MediaUrl")
      end

      if video_url.blank?
        render json: { error: "视频无可用播放地址" }, status: :not_found
        return
      end

      render json: { video_url: video_url }
    rescue => e
      Rails.logger.error "[VOD] play_url 异常: #{e.class}: #{e.message}"
      render json: { error: "获取播放地址异常: #{e.message}" }, status: :internal_server_error
    end
  end

  def psign
    file_id = params[:file_id].to_s.strip
    if file_id.blank?
      render json: { error: "缺少 file_id 参数" }, status: :bad_request
      return
    end

    # 验证 file_id 合法性：必须属于某课时的视频（课程功能由 courses 插件提供）
    lesson = defined?(CourseLesson) ? CourseLesson.where(video_url: file_id).first : nil
    unless lesson.present?
      render json: { error: "无效的视频标识" }, status: :forbidden
      return
    end

    psign_key = SiteSetting.get("tencent_vod_psign_key", default: "")

    if psign_key.blank?
      render json: { psign: nil, need_psign: false }
      return
    end

    begin
      psign = TencentVodService.generate_psign(file_id, psign_key)
      render json: { psign: psign }
    rescue => e
      Rails.logger.error "[VOD] psign 生成失败: #{e.message}"
      render json: { error: "签名生成失败" }, status: :internal_server_error
    end
  end

  def upload_signature
    secret_id = SiteSetting.get("tencent_vod_secret_id", default: "")
    secret_key = SiteSetting.get("tencent_vod_secret_key", default: "")

    if secret_id.blank? || secret_key.blank?
      render json: { error: "腾讯云点播未配置 SecretId/SecretKey" }, status: :internal_server_error
      return
    end

    begin
      signature = TencentVodService.generate_upload_signature(secret_id, secret_key)
      render json: { signature: signature }
    rescue => e
      Rails.logger.error "[VOD] 上传签名生成失败: #{e.message}"
      render json: { error: "上传签名生成失败" }, status: :internal_server_error
    end
  end

  # 删除腾讯云点播媒体文件
  def delete_media
    file_id = params[:file_id].to_s.strip
    if file_id.blank?
      render json: { error: "缺少 file_id 参数" }, status: :bad_request
      return
    end

    begin
      result = TencentVodService.delete_media(file_id)

      if result["Response"] && result["Response"]["Error"]
        code = result["Response"]["Error"]["Code"]
        msg = result["Response"]["Error"]["Message"]
        render json: { error: "删除失败: #{msg} (#{code})" }, status: :internal_server_error
        return
      end

      render json: { success: true }
    rescue => e
      Rails.logger.error "[VOD] delete_media 异常: #{e.class}: #{e.message}"
      render json: { error: "删除失败: #{e.message}" }, status: :internal_server_error
    end
  end

  private

  def set_cors_headers
    # 限制 CORS 为当前站点域名，不使用通配符 *
    origin = request.headers["Origin"]
    allowed_origins = [request.protocol + request.host_with_port]
    if origin.present? && allowed_origins.include?(origin)
      response.headers["Access-Control-Allow-Origin"] = origin
    end
    response.headers["Access-Control-Allow-Methods"] = "GET, POST"
    response.headers["Access-Control-Allow-Credentials"] = "true"
    response.headers["Vary"] = "Origin"
  end

  # 验证请求来源合法性：检查 Referer / Origin
  def require_valid_requester
    referer = request.headers["Referer"].to_s
    origin = request.headers["Origin"].to_s
    host = request.host_with_port

    # 允许来自同域的请求
    return true if referer.include?(host) || origin.include?(host)

    # 允许管理后台无 Referer 的请求（如 curl）
    return true if referer.blank? && origin.blank? && request.format.json?

    render json: { error: "非法请求来源" }, status: :forbidden
  end
end
