# AGENTS.md — Flutter Project Guidelines

This document governs how AI agents work on this Flutter project. We follow **Extreme Programming (XP)** as our primary development discipline. All work must align with XP values, principles, and practices while respecting Flutter/Dart conventions. Prefer the listed skills when applicable.

## XP Values (Non-Negotiable)

- **Communication**: Prefer clear, concise explanations and code that communicates intent. Face complexity with questions, not assumptions.
- **Simplicity**: Do the simplest thing that could possibly work. Avoid speculative design; solve today’s requirements, not tomorrow’s guesses.
- **Feedback**: Work in tiny cycles, run tests constantly, and validate assumptions early.
- **Courage**: Refactor mercilessly, delete dead code, and raise concerns about technical debt or process issues.
- **Respect**: Write code that others can read, maintain, and improve. Respect teammates’ time and the customer’s goals.

## XP Engineering Practices

### Test-First Development (TDD)

- **Always write a failing test before production code.**
- Cycle: write failing test → confirm it fails → write minimal code to pass → refactor → repeat.
- Prefer the `xpowers-test-driven-development` skill for every bug fix and feature.
- Keep tests fast, independent, and deterministic. Mock external dependencies; never test the real network or database in unit/widget tests.
- Run all tests before every commit. No commit should leave the suite red.

### Continuous Integration

- Integrate code frequently — multiple times per day.
- Keep the build under ten minutes: `flutter test`, `flutter analyze`, and `flutter format` must run quickly.
- Fix broken builds immediately; do not continue feature work on a red pipeline.

### Simple Design

- Follow the **Four Rules of Simple Design** (in priority order):
  1. Passes all tests.
  2. Reveals intention (clear names and structure).
  3. No duplication (DRY).
  4. Fewest elements (remove unused code, abstractions, and indirection).
- Avoid over-engineering; add abstraction only when duplication or pain demands it.
- Use the `xpowers-review-simplification` skill before introducing new patterns or abstractions.

### Refactoring / Design Improvement

- Refactor continuously, not in big batches.
- Refactoring is safe only with passing tests. Run tests after every small change.
- Use the `xpowers-refactoring-safely` skill for non-trivial refactors.
- Before large refactors, use `xpowers-refactoring-diagnosis` and `xpowers-refactoring-design`.

### Pair Programming

- Treat every change as if written in a pair: one person driving, one reviewing.
- As an AI pair partner, explain the “why” behind non-obvious decisions and invite alternatives.
- Rotate ideas and approaches; avoid heroics or single-person silos.

### Collective Code Ownership

- Any agent may improve any code anywhere in the project.
- Leave code cleaner than you found it.
- Do not tolerate “someone else’s code” as an excuse for poor quality.

### Coding Standard

- Follow the [Effective Dart](https://dart.dev/effective-dart) style guide.
- Prefer `final` and `const` where possible.
- Keep widgets small and composable; extract large build methods.
- Avoid nesting beyond 3–4 levels; extract private widgets or methods.
- Name files in `snake_case.dart` and classes in `PascalCase`.
- Use trailing commas for multi-line parameters and collections.
- Sort imports: Dart SDK, Flutter, third-party, project (relative last).
- Run `dart format --set-exit-if-changed lib test integration_test tool` before claiming work complete.

### Sustainable Pace

- Do not recommend death marches, heroic all-nighters, or shortcuts that create debt.
- Take small steps and keep the pace steady.

## XP Planning & Collaboration Practices

### Whole Team

- The team includes customer, developers, testers, and a coach when needed.
- Agents act as members of the whole team: ask clarifying questions, surface risks, and keep the customer’s goals visible.

### User Stories

- Work is expressed as small, user-visible stories.
- Stories are reminders for conversation, not specifications. Keep acceptance criteria concrete and testable.
- Break stories into the smallest slice that delivers value.

### Weekly / Quarterly Cycles

- Plan in weekly iterations (weekly cycle) aligned with quarterly goals (quarterly cycle).
- At the start of each week, know which stories are being delivered and what “done” looks like.
- Done means running, tested, integrated, and formatted — not “mostly done.”

### Small Releases

- Deliver working software in small, frequent increments.
- Prefer merging small, focused PRs over large batches.
- Each release/merge must leave `main` deployable.

### Slack

- Include low-priority cleanup or learning tasks in every plan that can be dropped if higher-priority work slips.
- This protects commitments and creates space for quality.

### Metaphor

- Maintain a shared system metaphor and consistent naming across the codebase.
- Names in code should reflect the domain. Avoid cryptic abbreviations.

## Architecture & SOLID Principles

We design code around **SOLID** principles so the codebase stays maintainable, testable, and open for extension without constant rewrites.

### Single Responsibility Principle (SRP)

- A class, function, or widget should have **only one reason to change**.
- Keep UI dumb; business logic belongs in controllers/blocs/notifiers.
- One file per responsibility: separate entities, repositories, data sources, use cases, providers, and screens.
- If a class does both parsing and storage, split it.

### Open/Closed Principle (OCP)

- Code should be **open for extension, closed for modification**.
- Add new exchanges, data sources, or UI variants by implementing existing interfaces, not by editing core logic.
- Prefer composition and interfaces over branching on concrete types.

### Liskov Substitution Principle (LSP)

- Implementations of an interface must be interchangeable without breaking callers.
- A `BinanceRestClient` and a `MockRestClient` must behave the same when used through `TickerSource`.
- Do not return surprising nulls, throw unexpected exceptions, or ignore interface contracts in subclasses.

### Interface Segregation Principle (ISP)

- Keep interfaces small and focused.
- Prefer several small contracts (`TickerSource`, `CandleSource`, `OrderBookSource`) over one giant `ExchangeApi` interface.
- A venue should only implement the contracts it actually supports.

### Dependency Inversion Principle (DIP)

- Depend on abstractions, not concrete implementations.
- Domain layers define repository and source interfaces; data layers implement them.
- Inject dependencies via constructor parameters and Riverpod providers; do not hard-wire concrete clients inside use cases or UI.

### Layer Rules

- **Domain** knows nothing about Flutter, HTTP, WebSocket, or JSON.
- **Data** knows about external APIs and maps them to domain entities.
- **Presentation** exposes state via Riverpod providers and notifiers.
- **UI** only renders state and forwards user events.

## Project Conventions

- Flutter SDK, Dart.
- State management: Riverpod (`flutter_riverpod`).
- Routing: declarative routing with `go_router`; use `flutter-setup-declarative-routing` to scaffold.
- Localization: use `flutter-setup-localization` to add ARB-based localization.
- Architecture: layered/clean architecture driven by SOLID; use `flutter-apply-architecture-best-practices` to audit or scaffold.

## State Management

- Keep UI dumb; business logic belongs in controllers/blocs/notifiers.
- Do not mutate state directly; always emit new state.
- Dispose streams, controllers, and notifiers correctly.

## Networking & Models

- Use the `http` package for HTTP; add it via `flutter-use-http-package`.
- Parse JSON safely with `json_serializable`; add it via `flutter-implement-json-serialization`.
- Never commit API keys or secrets; use environment configuration or `--dart-define`.

## UI / Layout

- Build responsive layouts with `LayoutBuilder`/`MediaQuery` or use `flutter-build-responsive-layout`.
- Fix overflow and layout issues with `flutter-fix-layout-issues`.
- Support light/dark themes and accessibility (contrast, labels, large fonts).

## Testing

- Add widget tests with `flutter-add-widget-test`.
- Add integration tests with `flutter-add-integration-test`.
- Maintain high test coverage; write tests before or alongside code (TDD required).
- Use `WidgetTester` for widget tests and mock dependencies, not real services.
- Use the `xpowers-testing-anti-patterns` skill when adding or changing tests.

### iOS Simulator End-to-End Testing

**iOS Simulator is the canonical runtime for verification.** Every screen-level feature must run and pass on a booted iOS Simulator before it is considered done.

#### Setup

Add the official integration test packages to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

Place e2e tests in `integration_test/`:

```
integration_test/
  app_test.dart              # smoke test: app launches and shows Portfolio
  auth_flow_test.dart        # local biometric/PIN gate flows
  markets_flow_test.dart     # screener flows
  offline_mode_test.dart     # offline/demo mode fallback
  compare_flow_test.dart     # compare screen flows
  exchange_detail_flow_test.dart # exchange detail flows
  options_flow_test.dart     # options chain flows
  orders_flow_test.dart      # orders & history flows
  settings_flow_test.dart    # account/settings flows
  helpers.dart               # shared integration-test utilities
```integration_test/
  app_test.dart              # smoke test: app launches and shows Portfolio
  auth_flow_test.dart        # local biometric/PIN gate flows
  markets_flow_test.dart     # screener flows
  offline_mode_test.dart     # offline/demo mode fallback
  helpers.dart               # shared integration-test utilities
```

#### Boot and run on iOS Simulator

List and boot a simulator:

```bash
xcrun simctl list devices available
xcrun simctl boot <UDID>
xcrun simctl bootstatus <UDID>
```

Run a single integration test:

```bash
flutter test integration_test/app_test.dart -d <device-id>
```

Run all integration tests:

```bash
flutter test integration_test -d <device-id>
```

For CI reporters:

```bash
flutter test integration_test -d <device-id> -r github
```

#### Required e2e coverage

At minimum, every screen-level task must add or update an integration test that verifies:

1. The screen renders without overflow or exceptions.
2. The primary user flow can be completed (tap, scroll, navigate, submit).
3. The screen responds correctly to theme/direction toggles if applicable.
4. Offline/demo mode shows the correct fallback state.

#### Writing stable iOS integration tests

- Initialize the binding first: `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`.
- Launch the app with `app.main()` and wait: `await tester.pumpAndSettle()`.
- Use `ValueKey` / `Key` finders for reliable widget lookup instead of text where possible.
- Pass an explicit timeout on slow simulators: `await tester.pumpAndSettle(const Duration(seconds: 30));`.
- Set per-test timeouts for slow builds: `timeout: const Timeout(Duration(minutes: 5))`.
- Reset app state between tests; uninstall the app or clear caches to avoid cascading failures.
- Do not test native platform UI (permission dialogs, system alerts) with `integration_test` alone; pre-grant permissions via `xcrun simctl privacy` or use `patrol` if native interaction is required.

#### Screenshots and logs

- Capture screenshots during tests with `binding.takeScreenshot('name')`.
- Pull screenshots from the device with an extended driver in `test_driver/integration_test.dart`.
- View logs with `flutter logs -d <device-id>` or `xcrun simctl spawn <UDID> log show --predicate 'process == "Runner"'`.

#### Common iOS Simulator issues

| Issue | Fix |
|---|---|
| No devices found | Boot simulator first: `xcrun simctl boot <UDID>` |
| App from previous run interferes | Uninstall: `xcrun simctl uninstall <UDID> <bundle-id>` |
| Permission dialog blocks test | Pre-grant permission or use `patrol` |
| Black screen | Ensure binding init, `app.main()`, and `pumpAndSettle()` |
| Timeout on slow simulator | Increase `pumpAndSettle` and test timeouts |

## Verification Commands

Run these before claiming work is complete:

```bash
flutter analyze
flutter test
dart format --set-exit-if-changed lib test integration_test tool
```

For unit/widget tests:

```bash
flutter test
```

For iOS Simulator integration tests (required for screen-level features):

```bash
xcrun simctl boot <UDID>
flutter test integration_test -d <device-id>
```

Use the `xpowers-verification-before-completion` skill to confirm outputs before claiming done.

## Skill Reference

| Task | Skill |
|------|-------|
| Add integration test | `flutter-add-integration-test` |
| Add widget preview | `flutter-add-widget-preview` |
| Add widget test | `flutter-add-widget-test` |
| Architecture review/scaffold | `flutter-apply-architecture-best-practices` |
| Responsive layout | `flutter-build-responsive-layout` |
| Fix layout issues | `flutter-fix-layout-issues` |
| JSON serialization | `flutter-implement-json-serialization` |
| Declarative routing | `flutter-setup-declarative-routing` |
| Localization | `flutter-setup-localization` |
| HTTP setup | `flutter-use-http-package` |
| iOS/macOS/Xcode work | `xcodebuildmcp-cli` |
| TDD enforcement | `xpowers-test-driven-development` |
| br / beads triage | `beads-triage` |
| Refactor safely | `xpowers-refactoring-safely` |
| Diagnose refactor needs | `xpowers-refactoring-diagnosis` |
| Design refactors | `xpowers-refactoring-design` |
| Review simplification | `xpowers-review-simplification` |
| Avoid testing anti-patterns | `xpowers-testing-anti-patterns` |
| Verify completion | `xpowers-verification-before-completion` |

## Security

- Do not log secrets, tokens, or PII.
- Validate all network input; never trust backend data blindly.
- Keep dependencies up to date; run `flutter pub outdated` regularly.

## Issue Tracking with `br` (beads_rust)

We use [`br`](https://github.com/Dicklesworthstone/beads_rust) — a local-first, dependency-aware issue tracker — as our agentic task tracker. `br` stores issues in `.beads/` (SQLite + JSONL). It is **non-invasive**: it never runs git commands automatically. Install it with:

```bash
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh?$(date +%s)" | bash
```

### Initialization

```bash
br init
br agents --add --force   # Optional: add br instructions to AGENTS.md
```

### Issue Lifecycle

| Command | Purpose |
|---------|---------|
| `br create "Title" --type task --priority 1` | Create a new issue |
| `br update <id> --status in_progress --assignee "$(git config user.email)"` | Claim work |
| `br close <id> --reason "Done"` | Complete work |
| `br sync --flush-only` | Export SQLite state to `.beads/issues.jsonl` |

### Priorities and Types

- **Priority:** `0` = critical, `1` = high, `2` = medium, `3` = low, `4` = backlog
- **Types:** `task`, `bug`, `feature`, `epic`, `question`, `docs`

### Dependencies

```bash
br dep add <issue> <depends-on>    # issue is blocked until depends-on is closed
br ready                           # Shows open, unblocked, not-deferred issues
```

### Agent Workflow

1. **Start:** `br ready --json` to find actionable work.
2. **Claim:** `br update <id> --status in_progress --assignee <agent>`.
3. **Work:** Implement the change using TDD and Flutter best practices.
4. **Close:** `br close <id> --reason "..."`.
5. **Sync:** `br sync --flush-only` then `git add .beads/` and commit together with code changes.

### Machine-Readable Output

Always use `--json` when parsing output programmatically:

```bash
br ready --json
br list --status open --json
br show <id> --json
```

### bv (beads_viewer) Integration

Use `bv` for graph-aware triage. **Always use `--robot-*` flags in automated sessions** — bare `bv` opens an interactive TUI.

```bash
bv --robot-triage      # Full triage report
bv --robot-next        # Single top recommendation
```

### Session Completion Checklist

Before ending any session:

1. Run verification commands (`flutter analyze`, `flutter test`, `flutter format`). If `.pre-commit-config.yaml` hooks are installed, `pre-commit` will run these automatically on commit.
2. Update `br` issue statuses (close completed work, update in-progress items).
3. `br sync --flush-only` to export state.
4. `git add .beads/` and commit together with code changes.
5. Push to remote if applicable.

## Agent Decision Checklist

Before proposing or committing any change, confirm:

1. Is the change the simplest thing that could work?
2. Is there a failing test (or user-story acceptance test) driving the change?
3. Is there a `br` issue tracking this change? If not, create one.
4. Does the full test suite pass?
5. Is the code formatted and free of analyzer warnings?
6. Is duplication removed and intent clear?
7. Could another team member understand and modify this code?
8. Does this keep the build under ten minutes and `main` deployable?

If the answer to any question is no, fix it before claiming completion.

## References

- [Extreme Programming: A Gentle Introduction](http://www.extremeprogramming.org/)
- [What is Extreme Programming? — Ron Jeffries](https://ronjeffries.com/xprog/what-is-extreme-programming/)
- [Extreme Programming — Agile Alliance](https://www.agilealliance.org/glossary/xp/)
- [Extreme Programming — Martin Fowler](https://martinfowler.com/bliki/ExtremeProgramming.html)
- [Effective Dart](https://dart.dev/effective-dart)
- [beads_rust (br) Repository](https://github.com/Dicklesworthstone/beads_rust)

<!-- bv-agent-instructions-v2 -->

---

## Beads Workflow Integration

This project uses [beads_rust](https://github.com/Dicklesworthstone/beads_rust) (`br`) for issue tracking and [beads_viewer](https://github.com/Dicklesworthstone/beads_viewer) (`bv`) for graph-aware triage. Issues are stored in `.beads/` and tracked in git.

### Using bv as an AI sidecar

bv is a graph-aware triage engine for Beads projects (.beads/beads.jsonl). Instead of parsing JSONL or hallucinating graph traversal, use robot flags for deterministic, dependency-aware outputs with precomputed metrics (PageRank, betweenness, critical path, cycles, HITS, eigenvector, k-core).

**Scope boundary:** bv handles *what to work on* (triage, priority, planning). `br` handles creating, modifying, and closing beads.

**CRITICAL: Use ONLY --robot-* flags. Bare bv launches an interactive TUI that blocks your session.**

#### The Workflow: Start With Triage

**`bv --robot-triage` is your single entry point.** It returns everything you need in one call:
- `quick_ref`: at-a-glance counts + top 3 picks
- `recommendations`: ranked actionable items with scores, reasons, unblock info
- `quick_wins`: low-effort high-impact items
- `blockers_to_clear`: items that unblock the most downstream work
- `project_health`: status/type/priority distributions, graph metrics
- `commands`: copy-paste shell commands for next steps

```bash
bv --robot-triage        # THE MEGA-COMMAND: start here
bv --robot-next          # Minimal: just the single top pick + claim command

# Token-optimized output (TOON) for lower LLM context usage:
bv --robot-triage --format toon
```

Before claiming, verify current state with `br show <id> --json` or `br ready --json`. `recommendations` can include graph-important blocked or assigned work; only `quick_ref.top_picks` and non-empty `claim_command` fields represent claimable work.

#### Other bv Commands

| Command | Returns |
|---------|---------|
| `--robot-plan` | Parallel execution tracks with unblocks lists |
| `--robot-priority` | Priority misalignment detection with confidence |
| `--robot-insights` | Full metrics: PageRank, betweenness, HITS, eigenvector, critical path, cycles, k-core |
| `--robot-alerts` | Stale issues, blocking cascades, priority mismatches |
| `--robot-suggest` | Hygiene: duplicates, missing deps, label suggestions, cycle breaks |
| `--robot-diff --diff-since <ref>` | Changes since ref: new/closed/modified issues |
| `--robot-graph [--graph-format=json\|dot\|mermaid]` | Dependency graph export |

#### Scoping & Filtering

```bash
bv --robot-plan --label backend              # Scope to label's subgraph
bv --robot-insights --as-of HEAD~30          # Historical point-in-time
bv --recipe actionable --robot-plan          # Pre-filter: ready to work (no blockers)
bv --recipe high-impact --robot-triage       # Pre-filter: top PageRank scores
```

### br Commands for Issue Management

```bash
br ready              # Show issues ready to work (no blockers)
br list --status=open # All open issues
br show <id>          # Full issue details with dependencies
br create --title="..." --type=task --priority=2
br update <id> --status=in_progress
br close <id> --reason="Completed"
br close <id1> <id2>  # Close multiple issues at once
br sync --flush-only  # Export DB to JSONL
```

### Workflow Pattern

1. **Triage**: Run `bv --robot-triage` to find the highest-impact actionable work
2. **Claim**: Use `br update <id> --status=in_progress`
3. **Work**: Implement the task
4. **Complete**: Use `br close <id>`
5. **Sync**: Always run `br sync --flush-only` at session end

### Key Concepts

- **Dependencies**: Issues can block other issues. `br ready` shows only unblocked work.
- **Priority**: P0=critical, P1=high, P2=medium, P3=low, P4=backlog (use numbers 0-4, not words)
- **Types**: task, bug, feature, epic, chore, docs, question
- **Blocking**: `br dep add <issue> <depends-on>` to add dependencies

### Session Protocol

```bash
git status              # Check what changed
git add <files>         # Stage code changes
br sync --flush-only    # Export beads changes to JSONL
git commit -m "..."     # Commit everything
git push                # Push to remote
```

<!-- end-bv-agent-instructions -->
