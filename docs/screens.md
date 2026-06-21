# YouTrade Screen Flows

This document describes every screen, its purpose, data requirements, states, transitions, and edge cases.

## Navigation Overview

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Home /    │─────▶│   Market    │─────▶│  Terminal   │
│  Portfolio  │      │  Screener   │      │             │
└─────────────┘      └─────────────┘      └──────┬──────┘
       │                                          │
       │                                          ▼
       │                                    ┌─────────────┐
       │                                    │   Compare   │
       │                                    └─────────────┘
       ▼
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│  Exchange   │◀────▶│   Orders    │      │   Options   │
│   Detail    │      │  & History  │      │    Chain    │
└─────────────┘      └─────────────┘      └─────────────┘
       ▲
       │
       ▼
┌─────────────┐      ┌─────────────────────┐
│   Account   │─────▶│ Exchange Management │
│  / Settings │      │    (API key input)  │
└─────────────┘      └─────────────────────┘
```

Bottom tab bar is always visible on main screens: Portfolio, Markets, Trade, Options, More.

---

## 1. Home / Aggregated Portfolio

**Purpose:** Show the user's total net worth across all connected venues, allocation, and open positions.

**Layout:**
- iOS status bar
- App header with logo, theme toggle, visual-direction toggle
- "Aggregated net worth · N venues" label
- Large total value with fractional cents
- 24h delta amount + percent
- Equity curve canvas with range selector (1H, 1D, 1W, 1M, 1Y)
- Allocation by venue progress bar
- Exchange cards list
- Open positions header + Orders link
- Open positions list
- Bottom tab bar

**Data:**
- `portfolioProvider`: total value, 24h delta, equity curve points
- `exchangeProvider`: list of connected venues with value and share
- `positionsProvider`: open positions per venue

**States:**
- Loading: skeleton placeholders for value, chart, lists
- Empty: no connected exchanges → prompt to add exchange
- Error: network/data failure → retry banner
- Offline: show cached/mock data with "Demo data" badge

**Interactions:**
- Tap exchange card → Exchange Detail
- Tap position row → Terminal for that symbol
- Tap range button → update equity curve range
- Tap Orders link → Orders & History

**Edge cases:**
- Total value may be negative in extreme short positions
- Single venue → allocation bar shows 100%
- No positions → show empty state with CTA to Markets

---

## 2. Trading Terminal

**Purpose:** Full trading interface for a selected symbol with chart, order book, trade ticket, and analysis.

**Layout:**
- Symbol switcher chips (BTC, ETH, SOL, AAPL, GOLD)
- Price header: symbol, class tag, name, venue, last price, 24h change
- 24h stat strip: High, Low, Vol, Funding
- Chart toolbar with timeframes + compare button
- Candlestick chart (OHLCV + MA7 + MA25 + volume + crosshair)
- Lower tabs: Trade / Book / Info / Signals

### Trade tab
- Buy/Long and Sell/Short toggle
- Order type chips: Limit / Market / Stop
- Price row
- Leverage slider (perps/futures only)
- Size-percent buttons (25/50/75/100%)
- Order size and cost estimate
- Submit CTA

### Book tab
- Asks list with depth bars
- Mid price + spread
- Bids list with depth bars

### Info tab
- Two tag cards (Analyst/Target or Trend/COT)
- 2-column stats grid
- About paragraph

### Signals tab
- Gauge with verdict (BUY/NEUTRAL/SELL)
- Oscillator list (RSI, MACD, Stoch, CCI, Williams %R)
- Moving averages list (MA7, MA25, MA50, MA99, MA200)
- Pivot levels grid (R2, R1, Pivot, S1, S2)

**Data:**
- `tickerProvider(symbol, venue)`: last price, change, stats
- `candlesProvider(symbol, venue, timeframe)`: OHLCV history
- `orderBookProvider(symbol, venue)`: asks/bids
- `tradesProvider(symbol, venue)`: recent trades tape
- `signalsProvider(symbol, venue)`: computed TA signals
- `fundamentalsProvider(symbol)`: about + stats + tags

**States:**
- Loading: chart placeholder, gray price
- Error: toast/banner with retry
- Offline: demo ticker + mock candles
- No connectivity: disable submit, show demo badge

**Interactions:**
- Tap symbol chip → switch symbol
- Tap timeframe → reload candles
- Tap compare button → Compare screen
- Tap lower tab → switch tab
- Drag leverage slider → update cost estimate
- Tap size-percent → update size
- Tap submit → validate then show confirmation dialog (demo in first build)

**Edge cases:**
- Symbol not tradable on active venue → show venue warning
- Negative leverage values rejected
- Price zero or null → disable submit
- Funding/OI not available for spot/equity → hide stat

---

## 3. Markets / Screener

**Purpose:** Browse symbols across venues and asset classes.

**Layout:**
- Search bar
- Asset-class filter chips: All, Crypto, Stocks, Futures, Options
- Market list header (Symbol | Last · 24h)
- Market rows with symbol, class badge, name, venue, sparkline, price, change

**Data:**
- `marketsProvider(filter)`: list of market rows
- Sparkline data per row (mini last-30 closes)

**States:**
- Loading: shimmer rows
- Empty search: no matches message
- Error: retry banner
- Offline: cached rows with demo badge

**Interactions:**
- Type in search → filter rows by symbol/name
- Tap filter chip → filter by asset class
- Tap row with sparkline → Terminal for that symbol
- Tap row without sparkline (options) → Options screen

**Edge cases:**
- Search returns zero results → suggest clearing filters
- Filter combination yields no rows → show empty state
- Options rows don't route to Terminal

---

## 4. Exchange Detail

**Purpose:** Drill into a single venue's balance, P&L, and asset allocation.

**Layout:**
- Back button to Home
- Venue selector chips (Binance, Bybit, OKX, Coinbase)
- Exchange name + "API LIVE" indicator
- Kinds label (Spot · Perp · Options)
- Balance card + 24h P&L card
- Balances header
- Asset rows: glyph, symbol, value, allocation bar

**Data:**
- `exchangeDetailProvider(venue)`: balance, P&L, assets
- Prices for each asset to compute value

**States:**
- Loading: skeleton cards and rows
- No API key → prompt to connect on Exchange Management screen
- Error: retry banner
- Offline: cached/demo data

**Interactions:**
- Tap venue chip → switch exchange
- Tap back → Home
- Tap asset row → Terminal for that asset

**Edge cases:**
- Venue has zero balances → show "No assets"
- API key missing or invalid → show locked state

---

## 5. Options Chain

**Purpose:** Display a synthetic BTC options chain for analysis.

**Layout:**
- BTC header + OPTIONS tag + spot price
- Expiration selector chips
- Calls / Strike / Puts header
- 7-column grid: IV, Δ, Mark, Strike, Mark, Δ, IV
- Rows with ATM highlighting
- Footer: ATM strike info

**Data:**
- `optionsProvider(expiration)`: strikes, calls, puts
- Spot price from ticker

**States:**
- Loading: skeleton grid
- Offline: synthetic data still available

**Interactions:**
- Tap expiration → reload chain
- Tap row → Terminal pre-filled with symbol (deferred trading)

**Edge cases:**
- Spot price unavailable → use last known or mock
- Only BTC options in first build

---

## 6. Compare

**Purpose:** Compare normalized returns of up to 4 symbols.

**Layout:**
- Title + count indicator
- Symbol chips to add/remove
- Normalized percentage chart
- Legend with symbol and change
- 30-period stats table (Symbol, Return, Volatility)

**Data:**
- `compareProvider(symbols)`: normalized returns and stats
- `candlesProvider` for each selected symbol

**States:**
- Loading: chart placeholder
- No symbols selected → prompt to select
- Error: retry

**Interactions:**
- Tap chip → toggle symbol (max 4)
- Long-press chip → reorder (optional)

**Edge cases:**
- Less than 2 symbols → hide chart, show helper
- Symbol missing data → show gap in chart

---

## 7. Orders & History

**Purpose:** Show open orders, filled/cancelled history, and current positions.

**Layout:**
- Title
- Tabs: Open / History / Positions
- Open tab: order cards with side badge, symbol, type, venue, cancel action
- History tab: list rows with status color
- Positions tab: position rows (same as Home)

**Data:**
- `openOrdersProvider`: mock open orders
- `orderHistoryProvider`: mock history
- `positionsProvider`: current positions

**States:**
- Loading: shimmer
- Empty: "No open orders" / "No history" / "No positions"
- Offline: cached data, disable cancel

**Interactions:**
- Tap tab → switch view
- Tap cancel → confirmation, then demo-remove
- Tap position row → Terminal

**Edge cases:**
- Cancel on offline → show error
- Real trading out of scope, so all orders are mock/demo

---

## 8. Account / Settings

**Purpose:** Manage connected exchanges, appearance, and app info.

**Layout:**
- Title "Account"
- Connected exchanges list with status indicators
- Appearance section: Theme toggle, Visual direction toggle
- Footer: app version + venue count

**Data:**
- `connectedExchangesProvider`: list and connection status
- `themeProvider`: current theme and direction

**States:**
- Loading: shimmer
- All exchanges connected → green indicators
- Some disconnected → amber/red indicators

**Interactions:**
- Tap exchange row → Exchange Management
- Tap Theme button → toggle dark/light
- Tap Visual direction button → toggle Flux/Carbon

---

## 9. Exchange Management (new)

**Purpose:** Add, edit, or remove exchange connections. First build supports read-only API keys for private balance/positions data.

**Layout:**
- Title + back button
- List of supported venues with current status
- Tap venue → detail screen/modal:
  - Exchange logo/name
  - Toggle: Enabled
  - Read-only API key input (obscured)
  - Read-only secret input (obscured)
  - Optional password/passphrase for exchanges that need it
  - Test connection button
  - Delete connection button
- Help text about API key permissions and security

**Data:**
- `exchangeCredentialsProvider`: secure storage of API keys
- `exchangeConnectionTester`: validates keys via public/private endpoint
- `exchangeCapabilityRepository`: tells UI what each venue needs

**States:**
- Loading: fetch saved credentials
- Connected: green indicator, show balance preview
- Invalid key: red error message
- Network error: retry
- No keys: prompt to enter

**Interactions:**
- Toggle enabled → save preference
- Enter key/secret → validate on blur or test tap
- Test connection → call private balance endpoint
- Save → encrypt and store in secure storage
- Delete → remove keys and disable venue

**Security:**
- Keys never logged or sent to analytics
- Stored in `flutter_secure_storage` (iOS Keychain / Android Keystore)
- UI defaults to obscured input with reveal toggle
- Read-only keys only: warn if key has trading/withdrawal permissions

**Edge cases:**
- User enters key with whitespace → trim
- Key rejected → show exchange-specific error hint
- No internet → queue save and retry later
- Biometric/PIN gate may re-prompt before revealing keys

---

## Global Behaviors

### Offline / Demo Mode
- Detect connectivity via `connectivity_plus`.
- When offline, show persistent "Demo data" banner.
- All screens fall back to mock data store.
- Disabled actions: submit order, cancel order, test connection, refresh real data.

### Local Auth Gate
- On cold start, require biometric/PIN before showing Portfolio, Terminal, Exchange Detail, Orders, or Exchange Management.
- Markets and Compare can be viewed without auth (public market data).
- Lock when app goes to background for > 2 minutes.
- Store auth state in `AuthGuardNotifier`.

### Theme
- System default = dark.
- Visual direction: Flux (dir:b) default, Carbon (dir:a) alternative.
- Theme tokens exposed via `ThemeExtension<YouTradeTheme>`.

### Error Handling
- Network errors → inline banner with retry
- Parse errors → log details, show generic retry
- Auth failures on exchange API → prompt to reconnect
- Unexpected errors → fallback screen with report option

### Accessibility
- Minimum touch target 44×44 logical pixels
- High-contrast up/down colors
- Screen reader labels on icon-only buttons
- Dynamic type support where feasible

---

## Open Questions

1. Should horizontal orientation be supported on any screen? (recommend portrait-only for first build)
2. Should pull-to-refresh be available on every screen or only selected screens?
3. Should the app remember last selected symbol and timeframe across sessions?
4. How many candles should be cached locally per symbol/timeframe?
5. Should Exchange Management be a full screen or a modal bottom sheet?
