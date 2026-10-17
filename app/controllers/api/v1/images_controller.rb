class Api::V1::ImagesController < Api::V1::BaseController
  before_action :authenticate_user!

  def create
    uploaded = params[:file]
    unless uploaded.is_a?(ActionDispatch::Http::UploadedFile)
      render_business_error("请选择要上传的图片")
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
        render_success(data: { id: @image.id, url: "/images/#{@image.id}" }, message: "上传成功")
      else
        render_error(message: "上传到对象存储失败", code: 500, status: :internal_server_error)
      end
    else
      @image = Image.new(user: current_user)
      @image.file.attach(io: StringIO.new(file_data), filename: uploaded.original_filename, content_type: content_type)

      if @image.save
        render_success(
          data: { id: @image.id, url: image_url(@image) },
          message: "上传成功"
        )
      else
        render_business_error(@image.errors.full_messages.join(", "))
      end
    end
  rescue => e
    render_error(message: "上传失败：#{e.message}", code: 500, status: :internal_server_error)
  end

  private

  def image_url(image)
    "/images/#{image.id}"
  end

  def generate_cos_path(filename)
    ext = File.extname(filename).downcase.delete(".")
    ext = %w[jpeg jpg png gif webp].include?(ext) ? ext : "jpg"
    "images/#{Time.current.strftime('%Y%m%d')}/#{SecureRandom.hex(8)}.#{ext}"
  end
end
