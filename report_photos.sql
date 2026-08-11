-- ============================================================
-- ESEP: фото объекта в заявке (до 10) + ссылки аналогов
-- ============================================================
-- Фото объекта хранятся в storage (bucket user-docs, папка report_photos/),
-- в заявке — только пути (массив). Оценщик может удалять/добавлять фото
-- через экран редактирования отчёта.

ALTER TABLE applications
  ADD COLUMN IF NOT EXISTS photo_urls text[] DEFAULT '{}'::text[];

COMMENT ON COLUMN applications.photo_urls IS
  'Пути в storage (user-docs/report_photos/) к фото объекта оценки (до 10).';
