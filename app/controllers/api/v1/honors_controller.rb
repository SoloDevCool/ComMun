class Api::V1::HonorsController < Api::V1::BaseController
  # GET /api/v1/honors
  def index
    unless Plugin.enabled.where(identifier: "honors").exists?
      return render_success(data: { enabled: false, honors: [] })
    end

    honors = pagy_results(Honor.active.includes(:user).ordered)
    render_success(
      data: {
        enabled: true,
        honors: honors.map do |honor|
          {
            id: honor.id,
            title: honor.title,
            description: honor.description,
            awarded_at: honor.awarded_at,
            certificate_image: honor.certificate_image,
            user: {
              id: honor.user&.id,
              username: honor.display_name,
              avatar_url: honor.avatar_url
            }
          }
        end
      }
    )
  end
end
