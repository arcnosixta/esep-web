# ESEP — Roadmap и архитектура (графы)

> Графическая версия роадмапа. Текстовые версии: [Roadmap.txt](Roadmap.txt), финансы — [Tools.txt](Tools.txt).
> Диаграммы в формате Mermaid — GitHub рендерит их автоматически (вкладка на странице файла).

---

## 1. Архитектура системы

```mermaid
flowchart TB
    subgraph Client["Клиенты — единый Flutter-код"]
        WEB["Flutter Web<br/>(браузер / PWA)"]
        MOB["Flutter app<br/>(iOS / Android)"]
    end

    subgraph CF["Cloudflare Pages"]
        EDGE["Edge-функция /api/chat<br/>(проверка JWT, ключи ИИ)"]
        STATIC["Статика: build/web"]
    end

    subgraph SB["Supabase"]
        AUTH["Auth (JWT)"]
        DB[("Postgres + RLS<br/>12 таблиц")]
        STO[("Storage<br/>reports/ — приватный<br/>user-docs/")]
    end

    subgraph AI["ИИ-провайдеры"]
        GEM["Gemini API<br/>(основной: текст, фото, поиск)"]
        OR["OpenRouter<br/>(фолбэк: Gemma free)"]
    end

    WEB -->|"HTTPS"| STATIC
    WEB -->|"REST + JWT"| EDGE
    MOB -->|"REST + JWT"| EDGE
    EDGE --> GEM
    EDGE -.->|"при лимитах"| OR
    WEB -->|"Supabase SDK"| AUTH
    MOB -->|"Supabase SDK"| AUTH
    AUTH --> DB
    WEB --> DB
    MOB --> DB
    WEB --> STO
    MOB --> STO
    EDGE -->|"проверка профиля"| DB

    style GEM fill:#1a73e8,color:#fff
    style OR fill:#f57c00,color:#fff
    style EDGE fill:#f38020,color:#fff
    style SB fill:#3ecf8e,color:#000
```

---

## 2. Путь клиента (пользовательский сценарий)

```mermaid
flowchart LR
    A["1. Регистрация<br/>email + пароль"] --> B["2. Онбординг<br/>(5 шагов-экскурсия)"]
    B --> C["3. Профиль<br/>ФИО + ИИН/БИН<br/>(1 ИИН = 1 аккаунт)"]
    C --> D["4. ИИ-чат<br/>описание текстом или фото"]
    D --> E["5. Оценка стоимости<br/>±10-15% #91;ESTIMATE#93;"]
    E --> F["6. Оплата<br/>15 000 ₸ (Kaspi / перевод)"]
    F --> G["7. Оценщик работает<br/>статус in_progress"]
    G --> H["8. Предпросмотр PDF<br/>с водяным знаком"]
    H --> I["9. ЭЦП-подпись оценщика<br/>(NCALayer / .cms)"]
    I --> J["10. Скачивание<br/>официального отчёта"]

    style F fill:#22c55e,color:#fff
    style I fill:#1a73e8,color:#fff
    style J fill:#16a34a,color:#fff
```

---

## 3. Жизненный цикл заявки (state diagram)

```mermaid
stateDiagram-v2
    [*] --> new: клиент создал заявку (manual или AI)
    new --> pending_payment: клиент нажал «Оплатить»
    pending_payment --> paid: админ подтвердил оплату
    paid --> in_progress: оценщик взял заявку
    in_progress --> signed: оценщик подписал ЭЦП
    signed --> completed: отчёт готов
    completed --> [*]

    new --> rejected: админ отклонил
    pending_payment --> new: клиент отменил оплату
    in_progress --> completed: отчёт готов (без ЭЦП)

    note right of paid: официальный PDF доступен только после paid
    note right of signed: подписывать может только оценщик/админ
```

---

## 4. Путь оценщика

```mermaid
flowchart TB
    L["Лента заявок"] --> M{"Доступные или мои?"}
    M -->|"доступные (new)"| T["Взять заявку<br/>→ in_progress"]
    M -->|"мои"| T
    T --> W["Работа: документы клиента,<br/>данные объекта, ИИ-помощь"]
    W --> G["Генерация PDF-отчёта<br/>(шаблон GaMa Group)"]
    G --> S{"Подпись ЭЦП"}
    S -->|"NCALayer (свой ключ)"| OK["Подписано + проверено"]
    S -->|"загрузка .cms (ezSigner)"| OK
    OK --> D["Заявка completed<br/>клиент видит отчёт"]
```

---

## 5. Этапы продукта (timeline)

```mermaid
timeline
    title ESEP — Roadmap 2026
    19.07 - 11.08.2026 : Этап 1 — MVP (готово)
                       : ИИ-оценка по тексту/фото
                       : Оплата (ручное подтверждение)
                       : PDF-отчёт + ЭЦП оценщика
                       : Security-аудит
    Август-сентябрь 2026 : Этап 2 — Продакшен (в работе)
                         : Kaspi Pay / PayBox
                         : Домен esep.kz
                         : eGov QR-подпись (Smart Bridge)
                         : Нативные iOS/Android
                         : Уведомления (push, WhatsApp)
```

---

## 6. План работ Этапа 2 (gantt)

```mermaid
gantt
    title Этап 2 — Продакшен-готовность (август-сентябрь 2026)
    dateFormat  YYYY-MM-DD
    section Платежи
    Kaspi Pay / PayBox (вебхук)      :p1, 2026-08-15, 30d
    section Домен и доверие
    Домен esep.kz + почта            :p2, 2026-08-15, 14d
    Юр. оформление (оферта, ПДн)     :p3, 2026-09-01, 30d
    section Интеграции
    eGov QR-подпись (NITEC-S-5096)   :p4, 2026-08-20, 25d
    SIGEX / TrustMe (массовое)       :p5, 2026-09-01, 20d
    section Мобильные
    Нативные сборки iOS/Android      :p6, 2026-09-01, 30d
    Push-уведомления                 :p7, 2026-09-15, 15d
    section Качество
    Автотесты + CI-гейты             :p8, 2026-08-15, 21d
    Мониторинг (Sentry) + аналитика  :p9, 2026-08-20, 14d
```

---

## 7. Роли и доступы

```mermaid
flowchart TB
    subgraph Roles["Роли"]
        CL["Клиент"]
        AP["Оценщик"]
        AD["Админ"]
    end

    subgraph Perms["Ключевые права"]
        P1["Заказать оценку, оплатить,<br/>скачать официальный PDF"]
        P2["Взять заявку, готовить отчёт,<br/>подписывать ЭЦП"]
        P3["Подтверждать оплаты,<br/>управлять пользователями"]
    end

    CL --> P1
    AP --> P2
    AD --> P3
    AD -->|"назначает роль"| AP
    AD -->|"блокировка"| CL
```

---

*Сгенерировано 11.08.2026. Файлы: [Roadmap.txt](Roadmap.txt) (текст), [Tools.txt](Tools.txt) (финансы и инструменты).*
