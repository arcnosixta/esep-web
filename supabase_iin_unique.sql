-- ESEP: 1 ИИН = 1 аккаунт (2026-08-09)
-- Уникальный индекс на ИИН в profiles.
--
-- Исключение: '070312500527' — тестовый ИИН владельца проекта (тестирует
-- приложение с нескольких аккаунтов). Перед запуском продакшена исключение
-- можно убрать, удалив AND iin <> '070312500527' из условия индекса.
--
-- ВАЖНО: запускать ПОСЛЕ supabase_b2b_foundation.sql (там добавляется bin),
-- но скрипт трогает только колонку iin, так что порядок не критичен.

-- ---------- 0. Дедупликация ----------
-- Если один ИИН уже привязан к нескольким профилям, оставляем самый старый
-- профиль, остальным очищаем ИИН. Иначе CREATE UNIQUE INDEX упадёт на дублях.
-- (Тестовый ИИН владельца не трогаем — он исключён из индекса.)
WITH dup AS (
  SELECT iin, min(id) AS keep_id
  FROM profiles
  WHERE iin IS NOT NULL AND iin <> '' AND iin <> '070312500527'
  GROUP BY iin
  HAVING count(*) > 1
)
UPDATE profiles p
SET iin = ''
FROM dup d
WHERE p.iin = d.iin AND p.id <> d.keep_id;

-- ---------- 1. Уникальный индекс ----------
-- Частичный: не мешает пустым ИИН (ещё не заполнен) и тестовому ИИН.
DROP INDEX IF EXISTS profiles_iin_unique;
CREATE UNIQUE INDEX profiles_iin_unique
  ON profiles (iin)
  WHERE iin IS NOT NULL AND iin <> '' AND iin <> '070312500527';

-- Проверка после применения:
-- SELECT iin, count(*) FROM profiles WHERE iin <> '' GROUP BY iin HAVING count(*) > 1;
-- Ожидаем: пусто (0 строк) — дублей нет.
