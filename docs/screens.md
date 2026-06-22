# YouTrade Screen Flows

This document describes every screen, its purpose, data requirements, states, transitions, and edge cases.

## Navigation Overview

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Home /    │─────▶│   Market    │─────▶│  Terminal   │      │   Options   │
│  Portfolio  │      │  Screener   │      │  /trading   │      │    Chain    │
└─────────────┘      └──────┬──────┘      └─────────────┘      └─────────────┘
                            │                                         ▲
                            │                                         │
                            ▼                                         │
                     ┌─────────────┐      ┌─────────────┐            │
                     │   Compare   │      │  Exchange   │            │
                     │ /markets/   │      │   Detail    │            │
                     │  compare    │      │/markets/ex- │            │
                     └─────────────┘      │ change/:id  │            │
                                          └─────────────┘            │
                                                                       │
                                                                       │
                                          ┌─────────────┐      ┌─────────────┐
                                          │   Orders    │      │   Account   │
                                          │  & History  │      │  / Settings │
                                          └─────────────┘      └─────────────┘
```

Bottom tab bar is always visible on main screens: Portfolio, Markets, Trade, Options, More.

Public (non-auth) routes are `/markets` and `/markets/compare`; all other routes require authentication. Compare and Exchange Detail are nested under `/markets`; Options Chain is at `/markets/options/:symbol`. Orders & History is nested under Portfolio at `/orders`. The Trading Terminal route is `/trading?symbol=<symbol>`.

---

## 1. Home / Aggregated Portfolio

**Purpose:** Show the user's total net worth across selected venues, allocation, and open positions.

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
- `marketScreenerItemsProvider`: list of market rows used for portfolio composition
- Synthetic positions and balances from `DeterministicMarketDataStore`

**States:**
- Loading: skeleton placeholders for value, chart, lists
- Empty: no positions → prompt to explore Markets
- Error: network/data failure → retry banner
- Offline: show cached/mock data with "Demo data" badge

**Interactions:**
- Tap exchange card → Exchange Detail (`/markets/exchange/:id`)
- Tap position row → Terminal (`/trading?symbol=...`)
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
- `tickerStreamProvider(symbol)`: last price, change, stats
- `candlesProvider(symbol, timeframe)`: OHLCV history
- `orderBookStreamProvider(symbol)`: asks/bids
- `tradesStreamProvider(symbol)`: recent trades tape
- `tradingTerminalProvider(symbol)`: order ticket state

**States:**
- Loading: chart placeholder, gray price
- Error: toast/banner with retry
- Offline: demo ticker + mock candles
- No connectivity: disable submit, show demo badge

**Interactions:**
- Tap symbol chip → switch symbol
- Tap timeframe → reload candles
- Tap compare button → Compare screen (`/markets/compare`)
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
- `marketScreenerItemsProvider`: list of market rows
- `filteredMarketScreenerItemsProvider(filter)`: filtered rows
- Sparkline data per row (mini last-30 closes)

**States:**
- Loading: shimmer rows
- Empty search: no matches message
- Error: retry banner
- Offline: cached rows with demo badge

**Interactions:**
- Type in search → filter rows by symbol/name
- Tap filter chip → filter by asset class
- Tap row with sparkline → Terminal (`/trading?symbol=...`)
- Tap row without sparkline (options) → Options Chain (`/markets/options/:symbol`)

**Edge cases:**
- Search returns zero results → suggest clearing filters
- Filter combination yields no rows → show empty state
- Options rows don't route to Terminal

---

## 4. Exchange Detail

**Purpose:** Drill into a single venue's capabilities and show public market data highlights.

**Layout:**
- Back button to Markets (`/markets`)
- Venue selector chips (Binance, Bybit, OKX, Coinbase)
- Exchange name + supported features indicator
- Kinds label (Spot · Perp · Options)
- Balance card + 24h P&L card (demo data)
- Balances header
- Asset rows: glyph, symbol, value, allocation bar

**Data:**
- `exchangeCapabilityRegistryProvider`: supported features per venue
- Synthetic balances and P&L from `DeterministicMarketDataStore`

**States:**
- Loading: skeleton cards and rows
- Error: retry banner
- Offline: cached/demo data

**Interactions:**
- Tap venue chip → switch exchange
- Tap back → Markets (`/markets`)
- Tap asset row → Terminal (`/trading?symbol=...`)

**Edge cases:**
- Venue has zero balances → show "No assets"

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
- Synthetic options chain from `DeterministicMarketDataStore`
- Spot price from ticker

**States:**
- Loading: skeleton grid
- Offline: synthetic data still available

**Interactions:**
- Tap expiration → reload chain
- Tap row → Terminal pre-filled with symbol (`/trading?symbol=...`)

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
- `candlesProvider` for each selected symbol
- Computed normalized returns and volatility

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
- Mock open orders from `DeterministicMarketDataStore`
- Mock order history from `DeterministicMarketDataStore`
- Current positions from `DeterministicMarketDataStore`

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

## 8. Account / Settings (More tab)

**Purpose:** Manage appearance, connected exchanges, security, and app info.

**Layout:**
- Title "Account"
- Appearance section: Theme toggle, Visual direction toggle
- Connected exchanges section: read-only list of venue capabilities
- Security section (TODO: not yet implemented — Biometric/PIN toggle, Sign out action)
- Footer: app version + venue count

**Data:**
- `themeSettingsProvider`: current theme and direction
- `authNotifierProvider`: auth state for biometric/PIN and sign-out
- `exchangeCapabilityRegistryProvider`: supported features per venue

**States:**
- Standard settings screen

**Interactions:**
- Tap Theme button → toggle dark/light
- Tap Visual direction button → toggle Flux/Carbon
- Tap Biometric/PIN toggle → enable/disable local auth gate (TODO: not yet implemented)
- Tap Sign out → clear local auth and return to Auth Gate (TODO: not yet implemented)

---

## Global Behaviors

### Offline / Demo Mode
- Detect connectivity via `connectivity_plus`.
- When offline, show persistent "Demo data" banner.
- All screens fall back to mock data store.
- Disabled actions: submit order, cancel order, refresh real data.

### Local Auth Gate
- On cold start, require biometric/PIN before showing Portfolio, Terminal, Exchange Detail, Orders, or Account.
- Markets and Compare can be viewed without auth (public market data).
- TBD: Lock when app goes to background for > 2 minutes.
- Store auth state in `AuthNotifier`.

### Theme
- System default = dark.
- Visual direction: Flux (dir:b) default, Carbon (dir:a) alternative.
- Theme tokens exposed via `AppColorTheme` (`ThemeExtension`).

### Error Handling
- Network errors → inline banner with retry
- Parse errors → log details, show generic retry
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
5. Should Account settings be a full screen or a modal bottom sheet?
