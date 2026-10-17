# GitHub OAuth 登录插件

为站点提供 GitHub 第三方登录。

## 功能

- 启用后登录页自动显示「使用 GitHub 登录」按钮
- 新用户可通过 OAuth 直接注册（若开启邀请码要求，走邀请码验证流程）
- 在后台「系统设置 → GitHub OAuth」中配置 Client ID / Client Secret
- 在后台「插件管理」中可随时启用/停用

## 使用步骤

1. 在 [GitHub Developer Settings](https://github.com/settings/developers) 创建 OAuth App，
   回调地址填 `{站点地址}/users/auth/github/callback`
2. 后台「插件管理」中启用本插件
3. 后台「系统设置 → GitHub OAuth」填入 Client ID / Client Secret 并保存
4. 登录页即可看到 GitHub 登录按钮

## 实现说明

- 通过 `view_injection` 钩子向登录页 `login_oauth_buttons` 注入点注入按钮
- 按钮仅在后台已配置 `github_client_id` 时显示
- 停用插件后按钮消失，`/users/auth/github` 回调也会被拒绝
