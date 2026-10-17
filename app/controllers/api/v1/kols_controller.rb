class Api::V1::KolsController < Api::V1::BaseController
  # GET /api/v1/kols
  def index
    unless Plugin.enabled.where(identifier: "kols").exists?
      return render_success(data: { enabled: false, kols: [] })
    end

    kols = Kol.active.ordered
    render_success(
      data: {
        enabled: true,
        kols: kols.map do |kol|
          {
            id: kol.id,
            name: kol.name,
            avatar: kol.avatar,
            bio: kol.bio,
            platforms: kol.platforms_list,
            price: kol.price,
            url: kol.url,
            # 邮箱仅登录用户可见（与 web 端一致）
            email: current_user ? kol.email : nil
          }
        end
      }
    )
  end
end
