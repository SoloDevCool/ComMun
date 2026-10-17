class Admin::KolsController < Admin::DashboardController
  before_action :check_plugin_enabled!

  def check_plugin_enabled!
    unless Plugin.enabled.where(identifier: "kols").exists?
      redirect_to admin_root_path, alert: t("admin.flash.m006")
    end
  end

  def index
    @kols = Kol.ordered
    @kol = Kol.new
  end

  def create
    @kol = Kol.new(kol_params)
    if @kol.save
      redirect_to admin_kols_path, notice: t("admin.flash.m003")
    else
      @kols = Kol.ordered
      flash.now[:alert] = "创建失败：#{@kol.errors.full_messages.join('，')}"
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @kol = Kol.find(params[:id])
    if @kol.update(kol_params)
      redirect_to admin_kols_path, notice: t("admin.flash.m005")
    else
      @kols = Kol.ordered
      flash.now[:alert] = "更新失败：#{@kol.errors.full_messages.join('，')}"
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @kol = Kol.find(params[:id])
    @kol.destroy
    redirect_to admin_kols_path, notice: t("admin.flash.m004")
  end

  def import
    file = params[:file]
    if file.blank?
      redirect_to admin_kols_path, alert: t("admin.flash.m135")
      return
    end

    unless file.content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" ||
           file.content_type == "application/vnd.ms-excel"
      redirect_to admin_kols_path, alert: t("admin.flash.m019")
      return
    end

    imported = 0
    skipped = 0
    errors = []

    begin
      workbook = Roo::Spreadsheet.open(file.path, extension: :xlsx)
      sheet = workbook.sheet(0)

      header_row = sheet.row(1).map { |v| v.to_s.strip }
      col_name = header_row.index("名称")
      col_bio = header_row.index("简介")
      col_email = header_row.index("邮箱")
      col_price = header_row.index("报价")
      col_avatar = header_row.index("头像")
      col_url = header_row.index("链接")
      col_platforms = header_row.index("媒体平台")
      col_sort_order = header_row.index("排序")
      col_is_active = header_row.index("状态")

      if col_name.nil?
        redirect_to admin_kols_path, alert: t("admin.flash.m045")
        return
      end

      (2..sheet.last_row).each do |row_idx|
        row = sheet.row(row_idx)
        name = row[col_name].to_s.strip

        next if name.blank?

        kol = Kol.new
        kol.name = name
        kol.bio = row[col_bio].to_s.strip if col_bio && row[col_bio].present?
        kol.email = row[col_email].to_s.strip if col_email && row[col_email].present?
        kol.price = row[col_price].to_s.strip if col_price && row[col_price].present?
        kol.avatar = row[col_avatar].to_s.strip if col_avatar && row[col_avatar].present?
        kol.url = row[col_url].to_s.strip if col_url && row[col_url].present?

        if col_platforms && row[col_platforms].present?
          kol.platforms = parse_platforms(row[col_platforms].to_s.strip)
        end

        if col_sort_order && row[col_sort_order].present?
          kol.sort_order = row[col_sort_order].to_i
        end

        if col_is_active && row[col_is_active].present?
          val = row[col_is_active].to_s.strip
          kol.is_active = %(是 启用 true 1).include?(val.downcase) ? true : false
        end

        if kol.save
          imported += 1
        else
          skipped += 1
          errors << "第#{row_idx}行「#{name}」：#{kol.errors.full_messages.join('，')}"
        end
      end
    rescue StandardError => e
      redirect_to admin_kols_path, alert: "导入失败：#{e.message}"
      return
    end

    msg = "成功导入 #{imported} 位 KOL 达人"
    msg += "，#{skipped} 条跳过" if skipped > 0
    msg += "，失败详情：#{errors.join('；')}" if errors.any?
    redirect_to admin_kols_path, notice: msg
  end

  def import_template
    pkg = Axlsx::Package.new
    wb = pkg.workbook
    ws = wb.add_worksheet(name: "KOL达人导入模板")

    header_style = wb.styles.add_style(b: true, font_name: "微软雅黑", sz: 11, alignment: { horizontal: :center, vertical: :center })
    example_style = wb.styles.add_style(font_name: "微软雅黑", sz: 10, fg_color: "4472C4", alignment: { horizontal: :center, vertical: :center })
    note_style = wb.styles.add_style(font_name: "微软雅黑", sz: 9, italic: true, fg_color: "808080", alignment: { horizontal: :left, vertical: :center, wrap_text: true })

    headers = ["名称", "简介", "邮箱", "报价", "头像", "链接", "媒体平台", "排序", "状态"]
    ws.add_row headers, style: header_style

    example = ["阮一峰", "知名技术博主", "ruanyf@example.com", "¥5000起/篇", "https://example.com/avatar.jpg", "https://ruanyifeng.com", "微信公众号|https://weixin.com, 哔哩哔哩|https://bilibili.com", 0, "是"]
    ws.add_row example, style: example_style

    notes = [
      "（必填）达人名称",
      "（选填）达人简介，最多80字",
      "（选填）联系邮箱，用于邀约发邮件",
      "（选填）例如：¥5000起/篇 或 面议",
      "（选填）头像图片URL地址（正方形）",
      "（选填）跳转链接，点击「达人介绍」按钮跳转",
      "（选填）多个平台用英文逗号分隔，格式：平台名|链接，例如：微信公众号|https://weixin.com, 哔哩哔哩|https://bilibili.com",
      "（选填）排序权重，数字越小越靠前，默认0",
      "（选填）启用状态：是/启用/true 或 否/禁用/false，默认启用"
    ]
    ws.add_row notes, style: note_style

    ws.column_widths 15, 30, 28, 18, 35, 35, 50, 8, 10

    send_data pkg.to_stream.read,
      filename: "KOL达人导入模板.xlsx",
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      disposition: "attachment"
  end

  def invite
    kol_ids = params[:kol_ids].to_s.split(",").map(&:strip).reject(&:blank?)
    subject = params[:subject].to_s.strip
    html_body = params[:html_body].to_s.strip

    if kol_ids.blank?
      redirect_back fallback_location: admin_kols_path, alert: t("admin.flash.m129")
      return
    end

    if subject.blank? || html_body.blank?
      redirect_back fallback_location: admin_kols_path, alert: t("admin.flash.m145")
      return
    end

    kols = Kol.where(id: kol_ids)
    success_count = 0
    error_details = []

    kols.each do |kol|
      if kol.email.blank?
        error_details << "#{kol.name}（无邮箱）"
        next
      end

      result = KolMailer.send_invitation(kol, subject, html_body)
      if result[:success]
        success_count += 1
      else
        error_details << "#{kol.name}（#{result[:message]}）"
      end
    end

    msg = "成功发送 #{success_count} 封邀约邮件"
    msg += "，以下达人发送失败：#{error_details.join('、')}" if error_details.any?

    redirect_to admin_kols_path, notice: msg
  end

  private

  def kol_params
    permitted = params.require(:kol).permit(:name, :bio, :email, :price, :url, :avatar, :sort_order, :is_active).to_h

    # Parse platforms from nested attributes
    raw = params[:kol][:platforms_attributes]
    if raw.present?
      permitted[:platforms] = raw.values.filter_map { |attr|
        name = attr[:name].to_s.strip
        url = attr[:url].to_s.strip
        { "name" => name, "url" => url } if name.present?
      }
    end

    permitted
  end

  def parse_platforms(text)
    text.split(/[,，]/).filter_map do |item|
      parts = item.split("|", 2).map(&:strip)
      next if parts[0].blank?
      { "name" => parts[0], "url" => (parts[1] || "").strip }
    end
  end
end
