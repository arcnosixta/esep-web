#!/usr/bin/env bash
# ESEP → Cloudflare Pages deploy script
# Usage:  ./deploy.sh   (сначала: cf login)
set -euo pipefail

cd "$(dirname "$0")"

# ── 1. flutter build web --release ─────────────────────────────────────
echo "→ flutter pub get"
flutter pub get
echo "→ flutter build web --release"
flutter build web --release

# ── 2. SPA-роутинг (если перейдёшь на path-роуты, без #) ───────────────
# Пока роутинг hash (#/) — не нужен. Файл создаём на будущее, он не мешает.
cat > build/web/_redirects <<'EOF'
/*    /index.html   200
EOF
echo "→ _redirects создан (запас на path-роутинг)"

# ── 3. wrangler (Cloudflare CLI) ────────────────────────────────────────
if ! command -v wrangler >/dev/null 2>&1; then
  echo "→ wrangler не найден, ставлю:  npm install -g wrangler"
  npm install -g wrangler
fi

# ── 4. Логин (только первый раз; откроет браузер) ──────────────────────
wrangler whoami >/dev/null 2>&1 || wrangler login

# ── 5. Публикация ───────────────────────────────────────────────────────
# functions/ (Pages Function /api/chat — прокси OpenRouter) подхватывается
# автоматически. Секрет OPENROUTER_API_KEY задаётся ОДИН РАЗ в дашборде:
# Pages → esep → Settings → Environment variables → Production secret.
echo "→ Публикую build/web в Cloudflare Pages (проект: esep)..."
wrangler pages deploy build/web --project-name esep

echo ""
echo "✓ Готово! Сайт: https://esep.pages.dev"
echo "  (название проекта можно сменить; URL поменяется, но SSL и CDN — бесплатно)"
