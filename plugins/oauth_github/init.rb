# init.rb - GitHub OAuth 登录插件入口
#
# 登录页按钮通过视图注入点 login_oauth_buttons 注入（见 lib/view_inject.rb）。
# Client ID / Client Secret 在后台「系统设置 → GitHub OAuth」卡片中配置，
# OAuth 回调地址为：{站点地址}/users/auth/github/callback
#
# 本插件未启用时，登录页不显示 GitHub 登录按钮，
# 且 /users/auth/github 回调会被拒绝。
