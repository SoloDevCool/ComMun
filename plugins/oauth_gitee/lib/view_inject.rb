# view_inject.rb
# 向登录页注入 Gitee 登录按钮

register_view_injection(
  location: "login_oauth_buttons",
  partial: "_login_button.html.erb"
)
