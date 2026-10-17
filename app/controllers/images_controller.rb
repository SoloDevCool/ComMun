class ImagesController < ApplicationController
  skip_forgery_protection only: [:create]
  before_action :authenticate_user!, only: [:create]

  def create
    uploaded = params[:file]
    unless uploaded.is_a?(ActionDispatch::Http::UploadedFile)
      render json: { error: "请选择要上传的图片" }, status: :unprocessable_entity
      return
    end

    file_data = uploaded.read
    content_type = uploaded.content_type

    if TencentCosService.upload_to_cos?
      url = TencentCosService.upload(
        generate_cos_path(uploaded.original_filename),
        file_data,
        content_type
      )
      if url
        @image = Image.create!(user: current_user, remote_url: url)
        render json: { url: "/images/#{@image.id}" }
      else
        render json: { error: "上传到对象存储失败" }, status: :internal_server_error
      end
    else
      @image = Image.new(user: current_user)
      @image.file.attach(io: StringIO.new(file_data), filename: uploaded.original_filename, content_type: content_type)

      if @image.save
        render json: { url: "/images/#{@image.id}" }
      else
        render json: { error: @image.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end
  rescue => e
    render json: { error: "上传失败：#{e.message}" }, status: :internal_server_error
  end

  def show
    image = Image.find(params[:id])

    if ImageWatermarkService.enabled? && ImageWatermarkService.cos_watermark_available?(image)
      # COS 图片：重定向到 COS 水印 URL，由 COS 服务端实时添加水印
      watermark_url = ImageWatermarkService.watermark_url(image)
      if watermark_url
        redirect_to watermark_url, allow_other_host: true
        return
      end
    end

    # 本地图片 或 COS 水印不可用：通过代理输出原图
    data, content_type = ImageWatermarkService.fetch_original(image)
    if data
      send_data data, type: content_type, disposition: "inline", cache_control: "public, max-age=86400"
    else
      redirect_to_fallback(image)
    end
  rescue => e
    Rails.logger.error "[ImagesController#show] Image ##{params[:id]} error: #{e.class} #{e.message}"
    image = Image.find_by(id: params[:id])
    redirect_to_fallback(image) if image
    head :not_found unless image
  end

  private

  # 降级：当 send_data 失败时回退到原始地址
  def redirect_to_fallback(image)
    if image&.remote_url?
      redirect_to image.remote_url, allow_other_host: true
    elsif image&.file&.attached?
      redirect_to rails_blob_path(image.file, only_path: true, disposition: "inline")
    else
      head :not_found
    end
  end

  def generate_cos_path(filename)
    ext = file_extension(filename)
    "images/#{Time.current.strftime('%Y%m%d')}/#{SecureRandom.hex(8)}.#{ext}"
  end

  def file_extension(filename)
    ext = File.extname(filename).downcase.delete(".")
    %w[jpeg jpg png gif webp].include?(ext) ? ext : "jpg"
  end
end
