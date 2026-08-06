#!/usr/bin/env bash
# ESEP → Cloudflare Pages deploy script
# Usage:  ./deploy.sh   (сначала: cf login)
set -euo pipefail

cd "$(dirname "$0")"

# ── 1. Требуется .env (Supabase URL + anon key) ─────────────────────────
if [ ! -f .env ]; then
  echo "✗ Нет файла .env в каталоге проекта."
  echo "  Скопируй шаблон:  cp .env.example .env"
  echo "  И впиши свои SUPABASE_URL / SUPABASE_ANON_KEY из панели Supabase (Project Settings → API)."
  exit 1
fi

# ── 2. flutter build web --release ─────────────────────────────────────
echo "→ flutter pub get"
flutter pub get
echo "→ flutter build web --release"
flutter build web --release

# ── 3. Сборка: упаковать .env в веб-сборку (flutter_dotenv) ────────────
# Плагин flutter_dotenv не упаковывает .env автоматически — положим его в build/web.
# ВАЖНО: .env содержит публичные ключи (URL + anon). На вебе их видит любой —
# это норм для клиентского кода; секреты (типа OpenRouter) сюда НЕ кладём.
cp .env build/web/.env
echo "→ .env упакован в build/web/.env"

# ── 4. SPA-роутинг (если перейдёшь на path-роуты, без #) ───────────────
# Пока роутинг hash (#/) — не нужен. Файл создаём на будущее, он не мешает.
cat > build/web/_redirects <<'EOF'
/*    /index.html   200
EOF
echo "→ _redirects создан (запас на path-роутинг)"

# ── 5. wrangler (Cloudflare CLI) ────────────────────────────────────────
if ! command -v wrangler >/dev/null 2>&1; then
  echo "→ wrangler не найден, ставлю:  npm install -g wrangler"
  npm install -g wrangler
fi

# ── 6. Логин (только первый раз; откроет браузер) ──────────────────────
wrangler whoami >/dev/null 2>&1 || wrangler login

# ── 7. Публикация ───────────────────────────────────────────────────────
echo "→ Публикую build/web в Cloudflare Pages (проект: esep)..."
wrangler pages deploy build/web --project-name esep

echo ""
echo "✓ Готово! Сайт: https://esep.pages.dev"
echo "  (название проекта можно сменить; URL поменяется, но SSL и CDN — бесплатно)"
