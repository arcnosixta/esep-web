Привет! Посмотрел ветку feat/official-report-format. Идея с официальным форматом отчёта (Приказ МФ РК №501) — правильная, но ветка не компилируется: 33 ошибки. Вот что нужно починить (по порядку):

=== 1. Синтаксис файла (самое главное) ===
lib/services/openrouter_service.dart не закрыт: ошибка «Expected to find '}'» на последней строке (493). Допиши закрывающую скобку класса.

=== 2. Добавить импорт dart:math ===
Ты используешь Random() (строка 491), но импорта нет. Добавь в шапку файла:
    import 'dart:math';

=== 3. Класс RealEstateReportData не создан ===
В сигнатуре generateReportData (строки 303, 476) ты ссылаешься на RealEstateReportData, но сам класс нигде не объявлен. Создай его — лучше в lib/models/report_template.dart рядом со старым ReportData (а не внутри сервиса): поля по твоей JSON-схеме (report_number, report_date, object_name, customer_name, customer_bin, customer_address, owner_name, owner_iin, owner_location, contract_basis/encumbrance, wall_material, object_location, valuation_purpose, valuation_assignment, value_type, appraiser_*, legal_entity_*, comparables[], corrections{}, price_per_meter, final_value, final_value_words, inspection_date, inspection_result) + factory fromJson. Старый ReportData пока не удаляй — его использует report_screen.

=== 4. Сломан чат: _streamWithModel удалён, но вызывается ===
Ты удалил метод _streamWithModel, но streamCompletion (строка 264) продолжает вызывать yield* _streamWithModel(...). Верни метод обратно (он был в master, строки ~418-460) или перепиши streamCompletion без него. Без этого ИИ-чат падает.

=== 5. report_service.dart не обновлён под новую сигнатуру ===
generateReportData теперь требует 8 новых обязательных параметров (location, customerName, customerBin, customerAddress, ownerName, ownerIin, ownerLocation, contractBasis), а старые clientName/clientIin убраны. report_service.dart (строка 32) вызывает со старыми параметрами и ожидает ReportData?. Обнови вызов в report_service.dart: передай новые параметры (откуда брать — из профиля пользователя через SupabaseService._fetchUserProfile или из формы заявки) и приведи тип к тому, что ждёт report_screen. Либо сделай новые параметры опциональными (String?) с дефолтами.

=== 6. Ветка отстала от master на 3 коммита ===
Сделай git rebase origin/master (или merge). В openrouter_service.dart конфликтов почти не будет, но после ребейза проверь flutter analyze.

=== Проверка после правок ===
    flutter analyze  → должно быть 0 errors
    flutter build web --release  → зелёный

=== Ещё важно (отдельная задача, не про формат отчёта) ===
Нужно, чтобы после успешного ИИ-анализа создавалась заявка, которую увидят оценщики. Сейчас заявки не создаёт никто: в supabase_service есть метод createApplication(propertyId, source) — добавь в ai_chat_screen после успешного анализа (когда есть итоговая стоимость) вызов:
    SupabaseService.createApplication(propertyId: ..., source: 'ai')
и передавай в него property_id объекта (если объект ещё не сохранён — сначала addProperty). Список заявок у клиента и очередь оценщика показывают ТОЛЬКО source='ai' — это уже сделано в master.
