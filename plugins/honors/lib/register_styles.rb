# register_styles.rb - 注入前台荣誉榜样式
css = <<'CSS'
<style>
/* ========== Honor Board 荣誉榜 ========== */
.honor-card{background:var(--bg-card);border-radius:.75rem;border:1px solid var(--border-color);transition:all .25s ease;overflow:hidden}
.honor-card:hover{border-color:var(--border-node-card-hover);background:var(--bg-card-hover);box-shadow:0 8px 24px var(--shadow-card);transform:translateY(-3px)}
[data-bs-theme="dark"] .honor-card:hover{border-color:rgba(255,255,255,.15);box-shadow:0 8px 24px rgba(0,0,0,.4)}
.honor-card-body{padding:1.25rem}
.honor-card-footer{padding:1rem 1.25rem;border-top:1px solid var(--border-color)}
.honor-user-info{display:flex;align-items:center;gap:.75rem;margin-bottom:1rem}
.honor-user-avatar-wrap{width:48px;height:48px;flex-shrink:0;border-radius:8px;padding:2.5px;background:linear-gradient(135deg,#f59e0b,#f97316,#ef4444)}
.honor-user-avatar-wrap img,.honor-user-avatar-wrap div{width:100%;height:100%;border-radius:8px;object-fit:cover}
.honor-user-name{font-size:.95rem;font-weight:700;color:var(--text-primary);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.honor-date{font-size:.78rem;color:var(--text-muted)}
.honor-certificate-link{display:block;text-decoration:none;border-radius:.6rem;overflow:hidden;transition:opacity .2s;cursor:zoom-in}
.honor-certificate-link:hover{opacity:.9}
.honor-certificate-img{width:100%;aspect-ratio:4/3;object-fit:cover;border-radius:.6rem;border:1px solid var(--border-color)}
.honor-certificate-placeholder{width:100%;aspect-ratio:4/3;border-radius:.6rem;background:var(--bg-input);border:2px dashed var(--border-color-stronger);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:8px;color:var(--text-faint);font-size:.82rem}
.honor-certificate-placeholder i{font-size:1.5rem;opacity:.5}
.honor-title{font-size:.92rem;font-weight:700;color:var(--text-primary)}
.honor-desc{font-size:.8rem;color:var(--text-muted);line-height:1.55;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
</style>
CSS

Myapp::PluginManager.instance.add_view_injection(
  location: 'head',
  content: css,
  plugin: plugin
)
