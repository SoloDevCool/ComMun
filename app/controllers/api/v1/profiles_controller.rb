class Api::V1::ProfilesController < Api::V1::BaseController
  before_action :authenticate_user!

  def show
    render_success(
      data: {
        user: current_user_profile,
        stats: {
          topics_count: current_user.topics.size,
          comments_count: current_user.comments.size,
          followers_count: current_user.followers.count,
          following_count: current_user.following.count,
          blocks_count: current_user.blocked_users.count,
          favorites_count: current_user.favorites.count
        }
      }
    )
  end

  def favorites
    base = current_user.favorites.includes(:topic => [:user, :node, :poll])
      .order(created_at: :desc)
    favorites = pagy_results(base)
    render json: {
      code: 0,
      data: favorites.map { |f| topic_list_item(f.topic) }
    }
  end

  # GET /api/v1/profile/following
  def following
    users = pagy_results(current_user.following.order(username: :asc))
    render_success(data: users.map { |u| user_brief(u) })
  end

  # GET /api/v1/profile/followers
  def followers
    users = pagy_results(current_user.followers.order(username: :asc))
    render_success(data: users.map { |u| user_brief(u) })
  end

  # GET /api/v1/profile/blocked
  def blocked
    users = pagy_results(current_user.blocked_users.order(username: :asc))
    render_success(data: users.map { |u| user_brief(u) })
  end

  # PATCH /api/v1/profile/privacy
  # params: { profile_public: true/false }
  def privacy
    unless params.key?(:profile_public)
      return render_error(message: "没有可更新的内容")
    end

    current_user.update!(profile_public: ActiveModel::Type::Boolean.new.cast(params[:profile_public]))
    render_success(data: current_user_profile, message: "隐私设置已更新")
  end

  def update
    if params[:avatar].present?
      file = params[:avatar]
      if TencentCosService.upload_to_cos?
        ext = case file.content_type
              when "image/png" then "png"
              when "image/gif" then "gif"
              when "image/webp" then "webp"
              else "jpg"
              end
        cos_path = "avatars/#{Time.current.strftime('%Y%m%d')}/#{SecureRandom.hex(8)}.#{ext}"
        url = TencentCosService.upload(cos_path, file.read, file.content_type)
        if url
          current_user.avatar_file.purge_later
          current_user.update!(avatar_data: url)
        else
          render_error(message: "头像上传失败", code: 500, status: :internal_server_error)
          return
        end
      else
        current_user.update!(avatar_data: nil)
        current_user.avatar_file.attach(file)
      end
      render_success(data: current_user_profile, message: "头像更新成功")
    elsif params[:username].present?
      if current_user.update(username: params[:username])
        render_success(data: current_user_profile, message: "用户名修改成功")
      else
        errors = current_user.errors.transform_values { |v| v }
        render_error(message: "修改失败", code: 422, errors: errors, status: :unprocessable_entity)
      end
    else
      render_error(message: "没有可更新的内容")
    end
  end

  def password
    unless current_user.valid_password?(params[:current_password])
      return render_business_error("当前密码错误")
    end

    if params[:new_password].length < 6
      return render_error(message: "新密码至少需要 6 位")
    end

    if params[:new_password] != params[:new_password_confirmation]
      return render_error(message: "两次输入的密码不一致")
    end

    current_user.update!(password: params[:new_password], password_confirmation: params[:new_password_confirmation])
    render_success(message: "密码已修改")
  end

  private

  def current_user_profile
    {
      id: current_user.id,
      email: current_user.email,
      username: current_user.display_name,
      avatar_url: current_user.avatar_data_url,
      points: current_user.points,
      role: current_user.role,
      profile_public: current_user.profile_public?,
      created_at: current_user.created_at
    }
  end

  def user_brief(user)
    {
      id: user.id,
      username: user.display_name,
      avatar_url: user.avatar_data_url
    }
  end

  def topic_list_item(topic)
    {
      id: topic.id,
      title: topic.title,
      slug: topic.slug,
      excerpt: topic.content.truncate(100),
      node: { id: topic.node.id, name: topic.node.name, slug: topic.node.slug },
      author: user_brief(topic.user),
      comments_count: topic.comments.size,
      cools_count: topic.cools_count,
      views_count: topic.views_count,
      pinned: topic.pinned,
      ai_generated: topic.ai_generated?,
      is_cooled: topic.cooled_by?(current_user),
      is_favorited: topic.favorited_by?(current_user),
      has_poll: topic.has_poll?,
      created_at: topic.created_at
    }
  end
end
