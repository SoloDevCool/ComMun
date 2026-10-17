class Api::V1::TextModerationController < Api::V1::BaseController
  before_action :authenticate_user!

  # 客户端提交前预检测文本内容
  def check
    text = params[:text].to_s.strip

    if text.blank?
      return render_error(message: "请输入需要检测的文本", code: 422, status: :unprocessable_entity)
    end

    if text.bytesize > 30_000
      return render_error(message: "文本内容过长，请控制在 10000 个字符以内", code: 422, status: :unprocessable_entity)
    end

    result = TextModerationService.check_simple(text)

    render_success(data: result)
  end
end
