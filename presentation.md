# YouTrade + XPowers: Timeline of the Magic

## Главный тезис сессии

Весь код YouTrade написали агенты.

Моя работа заключалась не в ручной реализации Flutter-классов. Я:

* создал визуальную спецификацию;
* дал агентам инструменты;
* зафиксировал правила;
* принял архитектурные решения;
* превратил проект в граф задач;
* запускал автономные циклы;
* проверял приложение как пользователь;
* превращал каждую найденную проблему в следующий исполняемый epic.

Главный цикл выглядел так:

**артефакт → решение → задача → Ralph → проверка → новый факт → следующий Ralph.**

---

# Первый день: от мокапа до работающего приложения

## До начала OpenCode-сессии — интерактивный мокап

Сначала я создаю в Claude Design полностью интерактивный прототип YouTrade:

* Portfolio;
* Markets;
* Trading Terminal;
* Orders;
* Exchange Detail;
* Options Chain;
* Compare;
* Account;
* переходы, состояния, темы и дизайн-систему.

Экспортирую его в папку `mockups/`.

### Зачем

Я не хочу объяснять агенту интерфейс словами. Мокап становится visual source of truth.

### Что показать

Сначала открыть готовый YouTrade. Затем открыть исходный кликабельный прототип.

> «Вот приложение, полностью написанное агентами. А вот визуальный контракт, с которого они начали».

---

## T+00:00 — проверяю память

```text
check supermemory memories
```

### Зачем

Понять, знает ли агент что-нибудь о проекте до старта.

### Результат

SuperMemory полностью пустая. Это важный момент: весь контекст YouTrade сформировался внутри этой сессии.

---

## T+00:01 — устанавливаю Flutter skills

```bash
npx skills add flutter/skills --skill '*' --agent universal
```

### Зачем

До большой задачи дать агенту специализированные процедуры:

* integration tests;
* widget tests;
* responsive layout;
* routing;
* architecture best practices;
* JSON;
* localization;
* HTTP.

### Результат

Устанавливаются десять Flutter skills. Один skill получает High Risk warning от Snyk.

> «Даже skills нужно проверять: это тоже исполняемый код».

---

## T+00:02 — создаю `AGENTS.md`

```text
lets write AGENTS.md for flutter project
with all best practices
and to use these flutter skills
```

### Зачем

Не надеяться, что модель всегда сама вспомнит Flutter conventions. Правила должны попадать в каждый новый контекст.

### Результат

Появляется первая версия конституции проекта:

* Flutter conventions;
* структура;
* testing;
* verification commands;
* правила использования skills.

---

## T+00:04 — делаю XP основной дисциплиной

```text
lets research XP best practices
Xtreme Programming is our bible
write AGENTS.md rules for this
```

### Зачем

Заставить агента постоянно работать через:

* small steps;
* TDD;
* continuous feedback;
* simple design;
* refactoring;
* sustainable pace.

Модель знает XP, но после длинной работы, смен задач и compaction перестаёт удерживать его в attention.

### Результат

XP становится governing discipline проекта.

---

## T+00:06 — подключаю `br`

```text
write rules to AGENTS.md that we always use br
as agentic issue tracker
```

```text
set up for TM = br
```

### Зачем

Задачи не должны жить только в чате. У каждой появляются:

* ID;
* status;
* dependencies;
* acceptance criteria;
* priority;
* история исполнения.

### Результат

Инициализирован `.beads/`, а `br ready` становится механизмом восстановления работы после compaction.

> «Диалог исчезает. Граф задач остаётся».

---

## T+00:13 — запускаю XPowers Brainstorming

```text
Use the skills_xpowers_brainstorming skill exactly as written.
Research @mockups/.
Design architecture first.
Think up all cases.
Research CCXT protocol.
```

### Зачем

Не давать агенту сразу писать код. Сначала он должен:

1. исследовать прототип;
2. найти все экраны и flows;
3. исследовать интеграции;
4. задать вопросы;
5. предложить архитектурные варианты.

### Какие решения принимаю я

* сначала весь UI на mock data;
* реальные market data — следующей фазой;
* Riverpod;
* layered architecture;
* public REST/WebSocket прямо из Flutter;
* iOS first;
* local PIN и biometrics;
* offline/demo fallback;
* private trading пока вне scope.

### Результат

Из идеи появляется согласованный scope.

> «Агент предлагает варианты. Человек остаётся владельцем решений».

---

## T+00:28 — заставляю перепроектировать всё через SOLID

```text
lets rethink via SOLID principles first
```

Затем:

```text
write rules to AGENTS.md
that we are also fans of SOLID
```

### Зачем

Не позволить агенту смешать API, DTO, repository, state и UI в несколько огромных классов.

### Результат

Появляются:

* маленькие source interfaces;
* per-exchange adapters;
* repository contracts;
* capability registry;
* domain/data/presentation/UI layers;
* dependency inversion.

> «SOLID — это guardrail против агентных god classes».

---

## T+00:36 — проверяю, что продукт спроектирован полностью

```text
did we fully designed architecture of this app?
```

```text
have we designed all screens in each flow?
```

```text
but how we connect exchanges?
do we have screens for this?
```

### Зачем

Не принять красивую общую архитектуру за полноценный product specification.

### Результат

Создаются:

* `docs/architecture.md`;
* `docs/screens.md`;
* девять screen specifications;
* navigation flows;
* Exchange Management;
* ссылки на документы из `AGENTS.md`.

Теперь важные решения живут не в conversation context, а в versioned source of truth.

---

## T+00:43 — превращаю архитектуру в дерево исполнения

```text
lets review all br tasks
and connect them in the order of implementation
```

```text
create one big epic
and connect tasks with each other
```

### Результат

Появляется master epic:

```text
youtrade-n97
YouTrade Flutter app: multi-venue trading terminal
```

Внутри него:

1. scaffold и domain;
2. data layer;
3. state, theme и auth;
4. UI screens;
5. integration и verification.

### Зачем

Теперь приложение для агента — не большой промпт, а исполняемый граф.

---

## T+00:47 — добавляю simulator как обязательный gate

```text
research how to write and run e2e tests
for Flutter app on iOS simulator

write rules to AGENTS.md
that we always run what we have written
and check how it works
```

### Зачем

Не позволить агенту считать задачу выполненной только потому, что код компилируется.

Definition of Done теперь включает:

* tests;
* analyze;
* format;
* integration tests;
* iOS build;
* запуск в Simulator;
* runtime verification.

Именно это правило позже обнаружит проблему, которую не увидят сотни тестов.

---

## T+00:51 — отдаю первый участок агенту

```text
Continue
```

К этому моменту уже существуют:

* мокап;
* skills;
* `AGENTS.md`;
* XP и SOLID;
* architecture docs;
* task graph;
* verification gates.

### Что агент делает сам

* устанавливает Flutter SDK;
* создаёт проект;
* реализует entities;
* создаёт `Result<T>`;
* пишет source contracts;
* реализует repository;
* добавляет mock store;
* добавляет Drift cache;
* пишет Binance REST/WebSocket;
* пишет тесты.

### Результат к T+09:00

* готов архитектурный фундамент;
* 35 тестов;
* analyzer clean;
* следующий ready-task — Bybit.

Я не написал ни одного production-класса вручную.

---

## T+09:12 — главный запуск

```text
/xpowers:execute-ralph n97
```

### Почему запускаю Ralph только сейчас

Потому что до этого были подготовлены:

* immutable epic requirements;
* архитектура;
* граф;
* dependencies;
* acceptance criteria;
* testing harness;
* simulator rules.

### Что делает Ralph

1. Открывает epic.
2. Выбирает ready-task.
3. Claim-ит задачу.
4. Refine-ит её.
5. Запускает implementation subagent.
6. Проверяет diff.
7. Запускает tests и analyze.
8. Закрывает задачу.
9. Разблокирует следующую.
10. Повторяет.

### Что агенты создают

* Bybit REST/WebSocket;
* Riverpod state;
* Flux/Carbon theme;
* local auth;
* все девять экранов;
* navigation;
* Exchange Management;
* integration tests.

Примерно через час с небольшим уже более 163 тестов и все основные UI screens.

> «Ralph — не YOLO. Это обход графа маленькими проверяемыми шагами».

---

## T+10:24 — запускаются integration и reviews

После UI Ralph переходит к:

* `go_router`;
* bottom navigation;
* auth redirects;
* iOS integration tests;
* review и remediation.

Review находит:

* WebSocket leaks;
* hardcoded PIN;
* проблемы offline mode;
* cache wiring;
* navigation bugs;
* parse errors;
* неработающий timeframe selector.

Агенты сами исправляют findings.

### Результат

* 208 тестов;
* simulator integration tests;
* analyzer clean;
* критические проблемы устранены.

---

## T+13:27 — отдельный Ralph для качества тестов

Test-effectiveness agent обнаруживает:

* tautological tests;
* mock-only assertions;
* слабые проверки;
* отсутствующие error paths;
* false confidence.

Я запускаю:

```text
/xpowers:execute-ralph 7le
```

### Зачем отдельный epic

Чтобы задача «улучшить тесты» имела собственные критерии:

* удалить RED tests;
* усилить YELLOW tests;
* добавить corner cases;
* провести mutation-aware review.

### Результат

* слабые тесты удалены или переписаны;
* добавлены точные assertions;
* покрыты auth, parsing, repository и UI edge cases;
* 303 теста.

После этого reviewers снова возвращают `ISSUES_FOUND`.

> «Reviewer полезен только тогда, когда он способен остановить конвейер».

---

## T+14:06 — семь review agents критикуют проект

Ralph параллельно запускает:

* quality review;
* testing review;
* simplification review;
* documentation review;
* security scanner;
* DevOps review;
* test-effectiveness review.

Они находят:

* lifecycle leaks;
* auth concurrency;
* documentation drift;
* отсутствие CI;
* generated artifacts в Git;
* слабое PIN hashing;
* ненужные abstractions.

### Что происходит дальше

Findings автоматически превращаются в remediation tasks.

Агенты добавляют:

* CI;
* custom fonts;
* правильные design tokens;
* OKX;
* Coinbase;
* live endpoint smoke tests;
* hardened `.gitignore`;
* обновлённые docs.

Test suite растёт до 409, а позже до 523 тестов.

---

## T+16:48 — повторно запускаю parent epic

```text
/xpowers:execute-ralph youtrade-n97
```

### Зачем

Feature tasks выполнены, но весь epic должен заново пройти success criteria и end-of-epic gate.

Все семь reviewers сначала возвращают проблемы. Ralph не объявляет проект готовым, а создаёт новые remediation epics.

Первый рабочий фундамент приложения появился примерно за сутки wall-clock.

---

# Вторая фаза: проверяю магию реальным приложением

## 8 июля — открываю приложение в Simulator

```text
lets rebuild and run on ios simulator this
```

Перед запуском:

* autonomous reviewer APPROVED;
* 523 теста;
* analyzer clean;
* build проходит.

### Что происходит

Приложение запускается, но PIN невозможно сохранить.

Это одна из важнейших историй всей сессии:

**523 зелёных теста и APPROVED review не гарантировали рабочий пользовательский flow.**

---

## 8–12 июля — runtime debugging

Сначала агент предполагает, что PBKDF2 с 600 000 iterations слишком медленный, и уменьшает iterations.

Но приложение всё равно не работает.

Я продолжаю возвращать его к реальному Simulator:

```text
i enter and it says failed to store pin
```

```text
lets run full e2e tests for each screen now
```

Наконец runtime log показывает настоящую причину:

```text
PlatformException
Code: -34018
A required entitlement isn't present
```

`flutter_secure_storage` не может использовать Keychain в no-codesign simulator build.

Для demo flow создаётся временный workaround.

12 июля я пишу:

```text
hooray! it works!
```

### Результат

* рабочий PIN flow;
* 643 теста;
* simulator и integration tests зелёные.

Позже security review правильно возвращает workaround на переработку.

> «Simulator нашёл баг. Review не позволил временному исправлению стать постоянной архитектурой».

---

# Третья фаза: от моков к реальному Bybit

## 12 июля — запускаю новый brainstorming

Я вижу, что приложение всё ещё использует mock data:

```text
Use the skills_xpowers_brainstorming skill exactly as written.

Connect all these screens
to real demo Bybit API.
```

Уточняю:

* linear и spot;
* все доступные пары;
* реальные wallet и positions;
* реальные orders;
* credentials из `.env`.

Создаётся новый epic:

```text
youtrade-dpe
Wire all screens to real Bybit demo API
```

---

## Запускаю вертикальный Bybit slice

```text
/xpowers:execute-ralph youtrade-dpe
```

Агенты сами пишут:

* HMAC-SHA256 signing;
* account client;
* demo/mainnet configuration;
* wallet;
* positions;
* orders;
* tickers;
* candles;
* order book;
* public trades;
* dynamic linear и spot symbols.

После реализации я не спрашиваю отчёт. Я открываю продукт:

```text
lets check Portfolio, Markets, Trade screens.
it shows errors.
looks like you did bugs
```

Real runtime обнаруживает:

* Portfolio errors;
* Markets errors;
* Trade loading errors;
* пустые Futures;
* неверные category mappings.

Каждый найденный факт запускает следующий fix cycle.

---

# Четвёртая фаза: продукт начинает развивать сам себя

## 13 июля — dynamic instruments

Я понимаю, что predefined symbols недостаточно:

```text
On the Trade screen I have predefined instruments,
but I want to trade any on the exchange.
```

Выбираю:

```text
search bar + dropdown
```

Создаётся:

```text
youtrade-bzr
Dynamic symbol picker for Trading Terminal
```

Запускаю:

```text
/xpowers:execute-ralph bzr
```

Агенты добавляют dynamic search, metadata resolution и arbitrary Bybit symbols.

---

## 13 июля — систематические edge cases

```text
Generate all edge case scenarios for this app,
write e2e tests for them,
make it work.
```

Создаётся epic:

```text
youtrade-dsx
Comprehensive edge case e2e tests
```

Запускаю:

```text
/xpowers:execute-ralph youtrade-dsx
```

Покрываются:

* auth;
* re-auth;
* network failures;
* empty states;
* long symbols;
* navigation;
* validation;
* orders;
* connectivity.

---

## 14 июля — настоящие ордера

Я задаю продуктовый вопрос:

```text
do you have e2e test to make limit orders?
market orders?
is this working?!
have you checked?
```

Создаётся:

```text
youtrade-ote
Real order placement and cancellation
via Bybit demo API
```

Агенты реализуют:

* signed POST;
* limit orders;
* market orders;
* confirmation;
* cancellation;
* e2e tests.

### Результат

* настоящие операции в Bybit demo;
* 743 теста;
* analyzer clean.

---

## 14 июля — real data ломает красивый layout

Длинные symbol names не помещаются в Markets.

Я снова возвращаюсь к visual source of truth:

```text
Do screen parity of Markets screen with @mockups/.
Symbols names are not fully fit.
```

Создаётся:

```text
youtrade-yjf
Markets screen mockup parity
```

Запускаю:

```text
/xpowers:execute-ralph youtrade-yjf
```

Агенты исправляют layout и добавляют regression tests.

---

## 15 июля — Markets превращается в настоящий screener

Сначала я прошу сортировать symbols по volume и market cap.

Исследование показывает, что market cap у Bybit нет.

Я отвечаю:

```text
lets use only what bybit has
```

Затем запускаю research лучшей screening formula.

Агенты создают composite score из:

* liquidity;
* volatility;
* momentum;
* funding;
* open interest;
* spread.

Затем я прошу selector сортировки:

* score;
* volume;
* price;
* change;
* open interest;
* funding;
* volatility;
* spread.

После запуска я замечаю новую UX-проблему:

```text
when I select Open Interest
I do not see open interest.
The same with funding.
```

Агенты меняют правую колонку tile, чтобы она показывала выбранную metric.

---

## 15 июля — маленькие цены находят скрытый bug

Я открываю `AKEUSDT`:

```text
AKEUSDT is 0.00.
The price is smaller.
We need always show full price.
```

Фиксированные два decimal places были скрытым предположением, которое не проявлялось на BTC и ETH.

Агенты создают smart formatter на significant figures:

```text
0.0006789 → 0.000679
```

Форматирование обновляется на всех экранах.

### Результат

787 тестов.

> «Реальные данные обнаруживают assumptions, которых не видно на красивых моках».

---

# Финальная фаза: PR review и границы автономности

## 15–16 июля — автономная обработка GitHub review

```text
review all unresolved threads in open PR

if you agree — fix
if you disagree — explain why

close resolved threads first
ultrathink
```

Агент для каждого finding:

1. читает thread;
2. проверяет код;
3. восстанавливает контекст;
4. принимает agree/disagree decision;
5. исправляет или аргументированно отвечает;
6. запускает tests;
7. закрывает thread.

Review обнаруживает:

* initialization order;
* `.env` assumptions;
* position notional bug;
* candle selection;
* неправильный 24h change;
* ranking errors;
* PIN security regression.

---

## 16 июля — guardrail останавливает force-push

Я прошу:

```text
git pull
rebase on main
force push
```

XPowers не выполняет destructive action молча. Агент останавливается и требует явного человеческого разрешения.

Этим удобно завершить весь рассказ:

> «Хорошая agentic system умеет не только работать без человека. Она умеет остановиться там, где ответственность должен взять человек».

---

# Порядок live demo

1. Показать готовый YouTrade.
2. Показать интерактивный мокап.
3. Показать пустую SuperMemory в начале.
4. Открыть `AGENTS.md`.
5. Открыть `docs/architecture.md`.
6. Показать graph `youtrade-n97`.
7. Показать `/xpowers:execute-ralph n97`.
8. Перепрыгнуть по task claim → subagent → tests → close.
9. Показать review verdict `ISSUES_FOUND`.
10. Рассказать PIN story.
11. Показать mock data → real Bybit.
12. Сделать реальный demo order.
13. Показать несколько продуктовых iterations.
14. Завершить force-push guardrail.

# Финальная формулировка

> «Я не писал это приложение руками. Агенты полностью написали код, тесты, интеграции и большую часть документации. Но это не был one-shot prompt. Я создал для них визуальный контракт, правила, память, архитектуру, граф задач и verification harness. Затем запускал автономные циклы, возвращался к работающему продукту и формулировал следующий факт. Магия не в том, что модель умеет генерировать код. Магия в том, что правильно организованная команда агентов способна построить, проверить, раскритиковать и развивать настоящий продукт».
