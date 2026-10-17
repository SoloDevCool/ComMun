xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  base = request.base_url

  # 首页
  xml.url do
    xml.loc base
    xml.lastmod @last_topic_updated.iso8601 if @last_topic_updated
  end

  # KOL 达人页
  xml.url do
    xml.loc "#{base}/kols"
    xml.lastmod @kols.maximum(:updated_at)&.iso8601 if @kols.any?
  end

  <% if @chat_groups_enabled %>
  # 交流群页
  xml.url do
    xml.loc "#{base}/chat_groups"
    xml.lastmod @chat_groups.maximum(:updated_at)&.iso8601 if @chat_groups.any?
  end
  <% end %>

  # Topics
  @topics.each do |topic|
    xml.url do
      xml.loc "#{base}#{topic_path(topic)}"
      xml.lastmod topic.updated_at.iso8601
    end
  end
end
