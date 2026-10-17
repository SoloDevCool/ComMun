# register_styles.rb - 注入前台KOL达 人样式
css = <<'CSS'
<style>
/* ========== KOL Card ========== */
.kol-card:hover{border-color:var(--border-node-card-hover);background:var(--bg-card-hover);box-shadow:0 4px 12px var(--shadow-card);transform:translateY(-1px)}
.kol-card{background:var(--bg-card);border-radius:.75rem;border:1px solid var(--border-color);transition:all .2s ease;overflow:hidden}
.kol-card-body{padding:1.25rem}
.kol-avatar{width:56px;height:56px;border-radius:.4rem;object-fit:cover;flex-shrink:0;border:2px solid var(--border-color)}
.kol-name{font-size:.95rem;font-weight:700;color:var(--text-primary);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.kol-platform{display:inline-flex;align-items:center;font-size:.75rem;color:var(--text-muted);background:var(--bg-badge-node);padding:.15rem .5rem;border-radius:.3rem;white-space:nowrap}
.kol-platform i{font-size:.8rem}
.kol-platform-link{text-decoration:none;cursor:pointer;transition:all .15s}
.kol-platform-link:hover{color:#f59e0b;background:rgba(245,158,11,.1)}
.kol-bio{font-size:.84rem;color:var(--text-secondary);line-height:1.6;display:-webkit-box;-webkit-line-clamp:3;-webkit-box-orient:vertical;overflow:hidden}
.kol-card-footer{padding:.75rem 1.25rem;border-top:1px solid var(--border-color)}
.kol-price{font-size:.92rem;font-weight:700;color:#e11d48}
[data-bs-theme="dark"] .kol-price{color:#fb7185}
.kol-price-negotiable{color:var(--text-muted);font-weight:500}
[data-bs-theme="dark"] .kol-price-negotiable{color:var(--text-muted)}
.kol-email{font-size:.78rem;color:var(--text-muted);text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:160px;transition:color .15s}
.kol-email:hover{color:var(--text-link)}
.kol-btn-view{font-size:.78rem;color:#f59e0b;border-color:rgba(245,158,11,.4);background:rgba(245,158,11,.08);padding:.15rem .55rem;border-radius:.35rem;white-space:nowrap;transition:all .15s}
.kol-btn-view:hover{color:#fff;background:#f59e0b;border-color:#f59e0b}
</style>
CSS

Myapp::PluginManager.instance.add_view_injection(
  location: 'head',
  content: css,
  plugin: plugin
)
