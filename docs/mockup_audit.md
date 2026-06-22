# YouTrade Mockup Visual Audit

Audit source: [`mockups/YouTrade.dc.html`](../mockups/YouTrade.dc.html) + [`mockups/colors_and_type.css`](../mockups/colors_and_type.css).  
Device frame: 390×844 CSS pixels, status bar 46 px, bottom nav 74 px.

Legend:

- **Mockup value:** exact value from HTML/CSS.
- **Current Flutter value:** value currently used in the Flutter implementation; `TBD` means not yet audited/aligned.
- **Status:** `matched` / `gap` / `TBD`.

---

## Global / Chrome

### Status Bar

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Height | `46px` | matched | matched |
| Background | transparent (inherits `#06080f`) | matched | matched |
| Clock | `9:41`, JetBrains Mono, `13px`, weight 500, letter-spacing `-0.02em`, `#f2f5fa` | matched | matched |
| Signal/WiFi/Battery icons | inline SVG, currentColor `#f2f5fa`, size ~17×11 / 16×11 / 25×12 | matched | matched |
| Center notch | `#000`, `104×30`, radius `16px` | matched | matched |

### App Header

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Padding | `6px 18px 12px` | matched | matched |
| Logo container | `30×30`, radius `8px`, bg `#00e6d2` (Flux dark) | matched | matched |
| Logo icon | inline SVG white checkmark `17×17` | matched | matched |
| App name | Space Grotesk, `16px`, weight 500, letter-spacing `-0.04em`, line-height `1`, `#f2f5fa` | matched | matched |
| Header tag | JetBrains Mono, `8.5px`, letter-spacing `0.14em`, uppercase, `#rgba(255,255,255,0.34)` | matched | matched |
| Theme toggle | `34×34`, radius `9px`, border `1px rgba(255,255,255,0.07)`, bg `#10151f`, icon color `rgba(255,255,255,0.55)` | matched | matched |
| Direction toggle | height `34px`, padding `0 11px`, radius `9px`, border `1px rgba(255,255,255,0.07)`, bg `#10151f`, text `#00e6d2`, JetBrains Mono `10px`, weight 600, letter-spacing `0.08em` | matched | matched |
| Direction dot | `7×7`, radius 50%, bg `#00e6d2`, glow `rgba(0,230,210,0.5)` | matched | matched |

### Bottom Navigation

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Height | `74px`, padding `8px 8px 22px` | matched | matched |
| Background | `#080b12` | matched | matched |
| Border top | `1px rgba(255,255,255,0.07)` | matched | matched |
| Labels | Portfolio, Markets, Trade, Options, More | matched | matched |
| Icon size | `22×22` SVG | matched | matched |
| Label font | JetBrains Mono, `8.5px`, weight 600, letter-spacing `0.04em` | matched | matched |
| Active color | `#00e6d2` (Flux) | matched | matched |
| Inactive color | `rgba(255,255,255,0.34)` | matched | matched |
| Active indicator | `4×4` dot, radius 50%, bg `#00e6d2`, glow `rgba(0,230,210,0.5)` | matched | matched |
| Touch target | `5px 10px` padding, radius `9px` | matched | matched |

---

## 1. Home / Aggregated Portfolio

### Layout Sections

1. "Aggregated net worth · N venues" eyebrow
2. Total value (large int + smaller fraction)
3. 24h delta row (arrow + amount + percent + "24h")
4. Equity curve card with range selector
5. Allocation by venue bar
6. Exchange cards list
7. Open positions header + Orders link
8. Open positions list

### Typography & Colors

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Eyebrow | JetBrains Mono, `9.5px`, letter-spacing `0.16em`, uppercase, `rgba(255,255,255,0.34)` | matched | matched |
| Total value | Space Grotesk, `43px`, weight 500, letter-spacing `-0.045em`, line-height `0.95`, tabular-nums, `#f2f5fa` | matched | matched |
| Fraction cents | Space Grotesk, `0.42em` (~18px), `rgba(255,255,255,0.34)` | matched | matched |
| 24h delta | JetBrains Mono, `13px`, weight 600, `#2ee6a6` (Flux up) | matched | matched |
| 24h percent | JetBrains Mono, `13px`, weight 600, `#2ee6a6` | matched | matched |
| "24h" label | JetBrains Mono, `11px`, `rgba(255,255,255,0.34)` | matched | matched |

### Equity Curve Card

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | height `120px`, radius `10px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f` | matched | matched |
| Chart | 90-point equity curve starting at `812468.7068931296` | matched | matched |
| Line color | `#00e6d2` | matched | matched |
| Area gradient | `#00e6d2` 32% → transparent | matched | matched |
| End dot | `3.2px` accent + `7px` 40% accent ring | matched | matched |
| Range buttons | JetBrains Mono `10px`, weight 600, padding `3px 8px`, radius `5px`, active border `rgba(0,230,210,0.5)`, active bg `rgba(0,230,210,0.18)`, active color `#00e6d2` | matched | matched |
| Range labels | `1H`, `1D`, `1W`, `1M`, `1Y` | matched | matched |

### Allocation Bar

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Header | JetBrains Mono `9.5px`, letter-spacing `0.14em`, uppercase, `rgba(255,255,255,0.55)` | matched | matched |
| Asset mix | JetBrains Mono `9.5px`, letter-spacing `0.06em`, `rgba(255,255,255,0.34)` → "Spot 41 · Perp 38 · Eq 12 · Fut 6 · Opt 3" | matched | matched |
| Bar height | `9px`, radius `5px`, gap `2px` | matched | matched |
| Binance share | `#f0b90b`, 41.9% | matched | matched |
| Bybit share | `#f7a600`, 26.6% | matched | matched |
| OKX share | `#00e6d2`, 19.7% | matched | matched |
| Coinbase share | `#0052ff`, 11.9% | matched | matched |

### Exchange Cards

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Card | padding `13px 14px`, radius `11px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f`, gap `9px` between cards | matched | matched |
| Avatar | `36×36`, radius `9px`, bg tinted exchange color, fg exchange color, Space Grotesk `15px`, weight 600 | matched | matched |
| Name | `14px`, weight 600, letter-spacing `-0.01em`, `#f2f5fa` | matched | matched |
| Live dot | `6×6`, radius 50%, bg `#2ee6a6`, ring `rgba(46,230,166,0.18)` | matched | matched |
| Kinds | JetBrains Mono `9.5px`, letter-spacing `0.05em`, uppercase, `rgba(255,255,255,0.34)` | matched | matched |
| Value | JetBrains Mono `14px`, weight 600, tabular-nums, `#f2f5fa` | matched | matched |
| Percent | JetBrains Mono `11px`, weight 600, up `#2ee6a6` / down `#ff5d77` | matched | matched |
| Binance | initial `B`, value `$312,480`, pct `+2.14%` | matched | matched |
| Bybit | initial `Y`, value `$198,320`, pct `-0.86%` | matched | matched |
| OKX | initial `O`, value `$146,900`, pct `+1.42%` | matched | matched |
| Coinbase | initial `C`, value `$88,540`, pct `+0.31%` | matched | matched |

### Open Positions

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Header eyebrow | JetBrains Mono `9.5px`, letter-spacing `0.14em`, uppercase, `rgba(255,255,255,0.55)` | matched | matched |
| Orders link | JetBrains Mono `10px`, weight 600, `#00e6d2` | matched | matched |
| List container | radius `11px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f` | matched | matched |
| Row padding | `11px 14px`, border-bottom `1px rgba(255,255,255,0.07)`, gap `11px` | matched | matched |
| Avatar | `30×30`, radius `8px`, bg tint, fg icon color, Space Grotesk `12px`, weight 600 | matched | matched |
| Symbol | `13px`, weight 600, `#f2f5fa` | matched | matched |
| Side badge | JetBrains Mono `8px`, weight 700, letter-spacing `0.06em`, padding `1.5px 5px`, radius `3px`, LONG bg `rgba(46,230,166,0.16)` / SHORT bg `rgba(255,93,119,0.16)` | matched | matched |
| Venue/qty | JetBrains Mono `9.5px`, `rgba(255,255,255,0.34)` | matched | matched |
| Value | JetBrains Mono `12.5px`, weight 600, tabular-nums, `#f2f5fa` | matched | matched |
| P&L | JetBrains Mono `10.5px`, weight 600, up `#2ee6a6` / down `#ff5d77` | matched | matched |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Range selector active | border `rgba(0,230,210,0.5)`, bg `rgba(0,230,210,0.18)`, text `#00e6d2` | matched | matched |
| Range selector inactive | transparent bg/border, `rgba(255,255,255,0.55)` text | matched | matched |
| Exchange card pressed | cursor pointer (web) / opacity or scale expected | matched | matched |
| Position row pressed | navigate to terminal | matched | matched |
| Orders link | text `#00e6d2`, pointer | matched | matched |

---

## 2. Trading Terminal

### Layout Sections

1. Symbol switcher chips
2. Price header (symbol, class, name, venue, price, change)
3. 24h stat strip (High, Low, Vol, Funding)
4. Chart toolbar (timeframes + compare)
5. Candlestick chart
6. Lower tabs (Trade / Book / Info / Signals)
7. Active tab content

### Symbol Chips

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | horizontal scroll, gap `6px`, padding `2px 16px 12px` | matched | matched |
| Chip | padding `6px 11px`, radius `7px`, border `1px` | matched | matched |
| Active | bg `rgba(0,230,210,0.15)`, border `rgba(0,230,210,0.4)`, text `#00e6d2` | matched | matched |
| Inactive | bg `#10151f`, border `rgba(255,255,255,0.07)`, text `rgba(255,255,255,0.55)` | matched | matched |
| Font | JetBrains Mono `11px`, weight 600, letter-spacing `0.02em` | matched | matched |
| Labels | BTC, ETH, SOL, AAPL, GOLD | matched | matched |

### Price Header

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Symbol | Space Grotesk `19px`, weight 600, letter-spacing `-0.02em`, `#f2f5fa` | matched | matched |
| Class tag | JetBrains Mono `8px`, weight 700, letter-spacing `0.08em`, padding `2px 6px`, radius `3px`, bg `#10151f`, border `1px rgba(255,255,255,0.07)`, text `rgba(255,255,255,0.55)` | matched | matched |
| Name/venue | `11px`, `rgba(255,255,255,0.34)` | matched | matched |
| Last price | JetBrains Mono `24px`, weight 600, letter-spacing `-0.01em`, tabular-nums, line-height `1`, up/down color | matched | matched |
| Change | JetBrains Mono `12px`, weight 600, up/down color | matched | matched |
| Default BTC price | `105154.04697406417` → formatted `105,154.0` | matched | matched |
| 24h change | `+6,346.7` / `+6.42%` | matched | matched |

### Stat Strip

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | grid 4 columns, gap `1px`, bg `rgba(255,255,255,0.07)`, border `1px rgba(255,255,255,0.07)`, radius `8px`, overflow hidden | matched | matched |
| Cell | bg `#0e131f`, padding `8px 10px` | matched | matched |
| Label | `8.5px`, letter-spacing `0.08em`, uppercase, `rgba(255,255,255,0.34)` | matched | matched |
| Value | JetBrains Mono `12px`, weight 500, `#f2f5fa`; Funding value `#2ee6a6` | matched | matched |
| High | computed from last 24 candles | matched | matched |
| Low | computed from last 24 candles | matched | matched |
| Vol | `(sum volume * last / 1e6)M` | matched | matched |
| Funding | `+0.0102%` | matched | matched |

### Chart Toolbar

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Timeframe buttons | padding `4px 9px`, radius `5px`, JetBrains Mono `10.5px`, weight 600 | matched | matched |
| Active TF | text `#00e6d2`, bg `rgba(0,230,210,0.15)`, border `rgba(0,230,210,0.4)` | matched | matched |
| Inactive TF | text `rgba(255,255,255,0.34)`, transparent | matched | matched |
| Compare button | `30×26`, radius `6px`, border `1px rgba(255,255,255,0.07)`, bg `#10151f`, icon `#00e6d2`, `15×15` SVG | matched | matched |

### Candlestick Chart

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | margin `0 12px`, radius `10px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f`, glow `rgba(0,230,210,0)` to `rgba(...)` | matched | matched |
| Height | `248px` canvas | matched | matched |
| MA labels | MA7 `#00e6d2` 90%, MA25 `#ffb020` | matched | matched |
| Grid | `rgba(255,255,255,0.045)` | matched | matched |
| Bull candle | `#2ee6a6` | matched | matched |
| Bear candle | `#ff5d77` | matched | matched |
| Volume bars | 32% opacity of candle color | matched | matched |
| Last price line | dashed `3,3`, 60% opacity of last candle color | matched | matched |
| Crosshair | dashed `2,3`, `rgba(255,255,255,0.25)` | matched | matched |

### Lower Tabs

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | padding `14px 16px 0`, border-bottom `1px rgba(255,255,255,0.07)` | matched | matched |
| Tab | flex 1, padding `0 0 10px`, border-bottom `2px` | matched | matched |
| Active | text `#f2f5fa`, bar `#00e6d2` | matched | matched |
| Inactive | text `rgba(255,255,255,0.34)`, bar `transparent` | matched | matched |
| Font | JetBrains Mono `11px`, weight 600, letter-spacing `0.03em` | matched | matched |
| Labels | Trade, Book, Info, Signals | matched | matched |

### Trade Tab

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Buy/Long button | flex 1, height `38px`, radius `7px`, border `1px`, Space Grotesk `14px`, weight 600 | matched | matched |
| Active buy | bg `rgba(46,230,166,0.18)`, border `rgba(46,230,166,0.6)`, text `#2ee6a6` | matched | matched |
| Inactive buy | transparent, border `rgba(255,255,255,0.07)`, text `rgba(255,255,255,0.55)` | matched | matched |
| Active sell | bg `rgba(255,93,119,0.18)`, border `rgba(255,93,119,0.6)`, text `#ff5d77` | matched | matched |
| Order type chips | height `30px`, radius `6px`, no border, JetBrains Mono `11px`, weight 600 | matched | matched |
| Active order type | bg `#f2f5fa`, text `#06080f` | matched | matched |
| Inactive order type | bg `transparent`, text `rgba(255,255,255,0.55)` | matched | matched |
| Price row | height `40px`, padding `0 12px`, radius `7px`, border `1px rgba(255,255,255,0.07)`, bg `#10151f` | matched | matched |
| Price label | `10px`, uppercase, letter-spacing `0.06em`, `rgba(255,255,255,0.34)` | matched | matched |
| Price value | JetBrains Mono `14px`, weight 500, `#f2f5fa` | matched | matched |
| Leverage slider | range 1–100, accent `#00e6d2` | matched | matched |
| Size pct buttons | height `28px`, radius `6px`, JetBrains Mono `10.5px`, weight 600 | matched | matched |
| Active size pct | text `#00e6d2`, bg `rgba(0,230,210,0.15)`, border `rgba(0,230,210,0.4)` | matched | matched |
| Submit CTA | width 100%, height `46px`, radius `8px`, Space Grotesk `15px`, weight 600, white text, shadow `0 0 20px -6px sideColor` | matched | matched |

### Book Tab

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Header | JetBrains Mono `8.5px`, letter-spacing `0.08em`, uppercase, `rgba(255,255,255,0.34)` | matched | matched |
| Ask row | padding `3px 6px`, JetBrains Mono `11px`, price `#ff5d77`, size `rgba(255,255,255,0.55)`, depth bar `rgba(255,93,119,0.12)` | matched | matched |
| Bid row | padding `3px 6px`, JetBrains Mono `11px`, price `#2ee6a6`, size `rgba(255,255,255,0.55)`, depth bar `rgba(46,230,166,0.12)` | matched | matched |
| Mid price strip | border-top/bottom `1px rgba(255,255,255,0.07)`, padding `8px 6px`, margin `4px 0` | matched | matched |
| Mid price | JetBrains Mono `15px`, weight 600, up/down color | matched | matched |
| Spread text | JetBrains Mono `10px`, `rgba(255,255,255,0.34)` | matched | matched |

### Info Tab

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Tag cards | flex 1, padding `10px 12px`, radius `8px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f` | matched | matched |
| Tag label | `9px`, letter-spacing `0.07em`, uppercase, `rgba(255,255,255,0.34)` | matched | matched |
| Tag value | JetBrains Mono `15px`, weight 600, up color or `#f2f5fa` | matched | matched |
| Stats grid | 2 columns, gap `1px`, bg/border `rgba(255,255,255,0.07)`, radius `8px` | matched | matched |
| Stats cell | bg `#0e131f`, padding `10px 12px` | matched | matched |
| Stats key | `11px`, `rgba(255,255,255,0.34)` | matched | matched |
| Stats value | JetBrains Mono `12px`, weight 500, `#f2f5fa` | matched | matched |
| About eyebrow | JetBrains Mono `9px`, letter-spacing `0.1em`, uppercase, `rgba(255,255,255,0.34)` | matched | matched |
| About body | `12.5px`, line-height `1.55`, `rgba(255,255,255,0.55)` | matched | matched |

### Signals Tab

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Gauge arcs | down `#ff5d77` 85%, mid `#ffb020` 85%, up `#2ee6a6` 85%, stroke width `11`, linecap round | matched | matched |
| Gauge needle | `#f2f5fa`, `3×46px`, pivot `9px` white dot | matched | matched |
| Verdict | Space Grotesk `26px`, weight 600, letter-spacing `-0.02em`, line-height `1`, verdict color | matched | matched |
| Verdict text | BUY/NEUTRAL/SELL | matched | matched |
| Signal counts | JetBrains Mono `11px`, `rgba(255,255,255,0.34)` | matched | matched |
| Oscillator score | JetBrains Mono `11px`, `rgba(255,255,255,0.55)` | matched | matched |
| Section eyebrow | JetBrains Mono `9px`, letter-spacing `0.1em`, uppercase, `rgba(255,255,255,0.34)` | matched | matched |
| List container | radius `8px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f` | matched | matched |
| List row | padding `9px 12px`, border-bottom `1px rgba(255,255,255,0.07)` | matched | matched |
| Indicator name | `12px`, `rgba(255,255,255,0.55)` | matched | matched |
| Indicator value | JetBrains Mono `12px`, `#f2f5fa` | matched | matched |
| Signal label | JetBrains Mono `10px`, weight 600, width `64px` / `36px`, right-aligned | matched | matched |
| Pivot grid | 5 columns, gap `1px`, bg/border `rgba(255,255,255,0.07)`, radius `8px` | matched | matched |
| Pivot cell | bg `#0e131f`, padding `9px 4px`, text centered | matched | matched |
| Pivot key | `9px`, `rgba(255,255,255,0.34)` | matched | matched |
| Pivot value | JetBrains Mono `10px`, `#f2f5fa` | matched | matched |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Symbol chip active | accent bg/border/text | matched | matched |
| Symbol chip inactive | chip bg/line text | matched | matched |
| Timeframe active | accent | matched | matched |
| Buy/Long active | green | matched | matched |
| Sell/Short active | red | matched | matched |
| Order type active | white bg, dark text | matched | matched |
| Size pct active | accent | matched | matched |
| Submit hover/press | shadow intensity | matched | matched |
| Compare button | accent icon | matched | matched |
| Lower tab active | white text + accent bar | matched | matched |
| Flash up | `yt-flash-up` animation: green 30% → transparent 0.6s | matched | matched |
| Flash down | `yt-flash-down` animation: red 30% → transparent 0.6s | matched | matched |

---

## 3. Markets / Screener

### Layout Sections

1. Search bar
2. Asset-class filter chips
3. List header
4. Market rows

### Search Bar

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | height `38px`, padding `0 12px`, radius `8px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f`, margin-bottom `12px` | matched | matched |
| Icon | `15×15` magnifier SVG, color `rgba(255,255,255,0.34)` | matched | matched |
| Placeholder | `13px`, `rgba(255,255,255,0.34)` → "Search symbols, venues, assets" | matched | matched |

### Filter Chips

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | horizontal scroll, gap `6px`, margin-bottom `12px` | matched | matched |
| Chip | padding `6px 13px`, radius `7px`, border `1px`, JetBrains Mono `11px`, weight 600 | matched | matched |
| Active | bg `#f2f5fa`, text `#06080f`, border `#f2f5fa` | matched | matched |
| Inactive | bg `transparent`, text `rgba(255,255,255,0.55)`, border `rgba(255,255,255,0.07)` | matched | matched |
| Labels | All, Crypto, Stocks, Futures, Options | matched | matched |

### List Header

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Row | padding `0 4px 8px`, justify space-between | matched | matched |
| Text | JetBrains Mono `8.5px`, letter-spacing `0.08em`, uppercase, `rgba(255,255,255,0.34)` → "Symbol" / "Last · 24h" | matched | matched |

### Market Rows

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | border `1px rgba(255,255,255,0.07)`, radius `11px`, overflow hidden, bg `#0e131f` | matched | matched |
| Row | padding `11px 13px`, border-bottom `1px rgba(255,255,255,0.07)`, gap `11px` | matched | matched |
| Label | Space Grotesk `13px`, weight 600, letter-spacing `-0.01em`, `#f2f5fa` | matched | matched |
| Class badge | JetBrains Mono `7.5px`, weight 700, letter-spacing `0.06em`, margin-top `3px` | matched | matched |
| Name | `11.5px`, `rgba(255,255,255,0.55)`, ellipsis | matched | matched |
| Venue | JetBrains Mono `8.5px`, `rgba(255,255,255,0.34)` | matched | matched |
| Sparkline | `46×24` canvas | matched | matched |
| Price | JetBrains Mono `12.5px`, weight 600, tabular-nums, `#f2f5fa` | matched | matched |
| Change | JetBrains Mono `10.5px`, weight 600, up/down color | matched | matched |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Filter chip active | white/dark | matched | matched |
| Row press | navigate to terminal or options | matched | matched |

---

## 4. Exchange Detail

### Layout Sections

1. Back link
2. Venue selector chips
3. Exchange name + API live indicator
4. Kinds label
5. Balance / 24h P&L cards
6. Balances list

### Back Link

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Row | flex, gap `5px`, padding `0 0 12px`, color `rgba(255,255,255,0.34)` | matched | matched |
| Icon | `13×13` left chevron SVG | matched | matched |
| Text | JetBrains Mono `11px` → "All portfolios" | matched | matched |

### Venue Chips

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | horizontal scroll, gap `6px`, margin-bottom `16px` | matched | matched |
| Chip | padding `7px 14px`, radius `7px`, border `1px`, Space Grotesk `13px`, weight 600 | matched | matched |
| Active | bg `#f2f5fa`, text `#06080f`, border `#f2f5fa` | matched | matched |
| Inactive | bg `transparent`, text `rgba(255,255,255,0.55)`, border `rgba(255,255,255,0.07)` | matched | matched |

### Header

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Color dot | `10×10`, radius `3px`, exchange color | matched | matched |
| Name | Space Grotesk `20px`, weight 600, letter-spacing `-0.02em`, `#f2f5fa` | matched | matched |
| API live | JetBrains Mono `9px`, `#2ee6a6`, dot `6×6` with glow | matched | matched |
| Kinds | JetBrains Mono `9px`, letter-spacing `0.06em`, uppercase, `rgba(255,255,255,0.34)` | matched | matched |

### Balance / P&L Cards

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | flex 1, padding `14px`, radius `10px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f`, gap `10px` | matched | matched |
| Label | `9px`, letter-spacing `0.07em`, uppercase, `rgba(255,255,255,0.34)` | matched | matched |
| Value | Space Grotesk `24px`, weight 600, letter-spacing `-0.03em`, tabular-nums, `#f2f5fa` or up/down color | matched | matched |
| P&L percent | JetBrains Mono `11px`, up/down color | matched | matched |
| Binance | total `$312,480`, P&L `+$6,620.00` / `+2.12%` | matched | matched |

### Balances List

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Section eyebrow | JetBrains Mono `9px`, letter-spacing `0.1em`, uppercase, `rgba(255,255,255,0.34)` | matched | matched |
| Container | radius `11px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f`, overflow hidden | matched | matched |
| Row | padding `12px 14px`, border-bottom `1px rgba(255,255,255,0.07)`, gap `11px` | matched | matched |
| Glyph | `32×32`, radius `8px`, bg `#10151f`, border `1px rgba(255,255,255,0.07)`, Space Grotesk `13px`, weight 600, `#f2f5fa` | matched | matched |
| Symbol | `13px`, weight 600, `#f2f5fa` | matched | matched |
| Value | JetBrains Mono `13px`, weight 500, `#f2f5fa` | matched | matched |
| Allocation bar | height `4px`, radius `2px`, bg `#10151f`, fill exchange color | matched | matched |
| Share | JetBrains Mono `9px`, `rgba(255,255,255,0.34)` | matched | matched |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Venue chip active | white/dark | matched | matched |
| Asset row press | terminal | matched | matched |
| Back link press | navigate back | matched | matched |

---

## 5. Options Chain

### Layout Sections

1. BTC header + spot price
2. Expiration chips
3. Column headers
4. Strike rows

### Header

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Symbol | Space Grotesk `18px`, weight 600, `#f2f5fa` | matched | matched |
| OPTIONS tag | JetBrains Mono `8px`, weight 700, letter-spacing `0.06em`, padding `2px 6px`, radius `3px`, bg `#10151f`, border `1px rgba(255,255,255,0.07)` | matched | matched |
| Spot label | JetBrains Mono `8.5px`, letter-spacing `0.06em`, uppercase, `rgba(255,255,255,0.34)` | matched | matched |
| Spot value | JetBrains Mono `15px`, weight 600, `#f2f5fa` | matched | matched |

### Expiration Chips

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | horizontal scroll, gap `6px`, padding `0 4px 12px` | matched | matched |
| Chip | padding `6px 12px`, radius `7px`, border `1px`, JetBrains Mono `10.5px`, weight 600 | matched | matched |
| Active | accent | matched | matched |
| Inactive | chip/line colors | matched | matched |

### Column Headers

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Top header | grid 3 columns, JetBrains Mono `8px`, letter-spacing `0.08em`, uppercase, calls `#2ee6a6`, strike `rgba(255,255,255,0.34)`, puts `#ff5d77` | matched | matched |
| Sub-header | grid 7 columns, JetBrains Mono `7.5px`, letter-spacing `0.04em`, uppercase, `rgba(255,255,255,0.34)` | matched | matched |

### Strike Rows

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | border `1px rgba(255,255,255,0.07)`, radius `10px`, overflow hidden | matched | matched |
| Row | grid 7 columns, gap `2px`, padding `8px 6px`, border-bottom `1px rgba(255,255,255,0.07)`, bg `rgba(0,230,210,0.08)` if ATM | matched | matched |
| IV | JetBrains Mono `9.5px`, `rgba(255,255,255,0.34)` | matched | matched |
| Delta | JetBrains Mono `9.5px`, `rgba(255,255,255,0.55)` | matched | matched |
| Mark | JetBrains Mono `9.5px`, weight 600, right-aligned | matched | matched |
| Strike | JetBrains Mono `9.5px`, weight 700, centered, `#00e6d2` if ATM else `#f2f5fa` | matched | matched |
| Footer | JetBrains Mono `9px`, `rgba(255,255,255,0.34)`, centered → "ATM strike 106,000 · highlighted" | matched | matched |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Expiration active | accent | matched | matched |
| ATM row | accent tinted background | matched | matched |

---

## 6. Compare

### Layout Sections

1. Title + count
2. Symbol chips
3. Normalized chart
4. Legend
5. 30-period stats table

### Header

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Title | Space Grotesk `18px`, weight 600, letter-spacing `-0.02em`, `#f2f5fa` | matched | matched |
| Count | JetBrains Mono `9px`, `rgba(255,255,255,0.34)` → "3/4 · normalized %" | matched | matched |

### Symbol Chips

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | horizontal scroll, gap `6px`, margin-bottom `14px` | matched | matched |
| Chip | padding `6px 13px`, radius `7px`, border `1px`, JetBrains Mono `11px`, weight 600 | matched | matched |
| Active | bg symbol color, text white, border symbol color | matched | matched |
| Inactive | bg `#10151f`, border `rgba(255,255,255,0.07)`, text `rgba(255,255,255,0.55)` | matched | matched |
| Colors | BTC `#00e6d2`, ETH `#ffb020`, SOL `#ff5d77`, AAPL `#8b9cf0`, GOLD `#c9a6ff` | matched | matched |

### Chart

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|
| Container | border `1px rgba(255,255,255,0.07)`, radius `10px`, bg `#0e131f`, glow | matched | matched |
| Height | `220px` | matched | matched |
| Grid | `rgba(255,255,255,0.045)` | matched | matched |
| Zero line | `rgba(255,255,255,0.5)` | matched | matched |
| Lines | symbol colors, width `1.8` | matched | matched |
| End dots | `3px` at right edge | matched | matched |

### Legend

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | flex wrap, gap `14px`, margin `14px 4px` | matched | matched |
| Color bar | `14×3`, radius `2px` | matched | matched |
| Symbol | JetBrains Mono `11px`, weight 600, `#f2f5fa` | matched | matched |
| Change | JetBrains Mono `11px`, up/down color | matched | matched |

### Stats Table

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Section eyebrow | JetBrains Mono `9px`, letter-spacing `0.1em`, uppercase, `rgba(255,255,255,0.34)` | matched | matched |
| Container | border `1px rgba(255,255,255,0.07)`, radius `10px`, overflow hidden | matched | matched |
| Header row | grid 3 columns, padding `9px 14px`, border-bottom `1px rgba(255,255,255,0.07)`, bg `#0e131f`, JetBrains Mono `8.5px`, letter-spacing `0.06em`, uppercase, `rgba(255,255,255,0.34)` | matched | matched |
| Data row | grid 3 columns, padding `11px 14px`, border-bottom `1px rgba(255,255,255,0.07)`, bg `#0e131f` | matched | matched |
| Symbol | JetBrains Mono `12px`, weight 600, `#f2f5fa` | matched | matched |
| Return | right-aligned, up/down color | matched | matched |
| Volatility | right-aligned, `rgba(255,255,255,0.55)` | matched | matched |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Chip selected | filled symbol color, white text | matched | matched |
| Chip unselected | chip style | matched | matched |

---

## 7. Orders & History

### Layout Sections

1. Title
2. Tabs
3. Open orders / History / Positions content

### Header

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Title | Space Grotesk `18px`, weight 600, letter-spacing `-0.02em`, `#f2f5fa`, margin-bottom `14px` | matched | matched |

### Tabs

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | flex, border-bottom `1px rgba(255,255,255,0.07)`, margin-bottom `14px` | matched | matched |
| Tab | flex 1, padding `0 0 10px`, border-bottom `2px` | matched | matched |
| Active | text `#f2f5fa`, bar `#00e6d2` | matched | matched |
| Inactive | text `rgba(255,255,255,0.34)`, bar `transparent` | matched | matched |
| Font | JetBrains Mono `11px`, weight 600 | matched | matched |

### Open Orders

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | flex column, gap `9px` | matched | matched |
| Card | padding `12px 14px`, radius `10px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f` | matched | matched |
| Side badge | JetBrains Mono `8px`, weight 700, letter-spacing `0.06em`, padding `2px 6px`, radius `3px` | matched | matched |
| Symbol | `13px`, weight 600, `#f2f5fa` | matched | matched |
| Type/venue | JetBrains Mono `10px`, `rgba(255,255,255,0.34)` | matched | matched |
| Cancel | JetBrains Mono `10px`, weight 600, `#00e6d2` | matched | matched |
| Price/qty row | JetBrains Mono `11px`, justify space-between | matched | matched |

### History

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | border `1px rgba(255,255,255,0.07)`, radius `11px`, overflow hidden, bg `#0e131f` | matched | matched |
| Row | padding `11px 14px`, border-bottom `1px rgba(255,255,255,0.07)`, gap `10px` | matched | matched |
| Symbol | `12.5px`, weight 600, `#f2f5fa` | matched | matched |
| Details | JetBrains Mono `9px`, `rgba(255,255,255,0.34)` | matched | matched |
| Price | JetBrains Mono `12px`, `#f2f5fa` | matched | matched |
| Qty/status | JetBrains Mono `9.5px`, status color | matched | matched |
| Filled | `rgba(255,255,255,0.55)` | matched | matched |
| Cancelled | `rgba(255,255,255,0.34)` | matched | matched |

### Positions Tab

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Same as Home open positions | see Home section | matched | matched |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Tab active | accent bar | matched | matched |
| Cancel press | demo-remove | matched | matched |

---

## 8. Account / Settings

### Layout Sections

1. Title
2. Connected exchanges section
3. Appearance section
4. Footer

### Title

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Text | Space Grotesk `18px`, weight 600, letter-spacing `-0.02em`, `#f2f5fa`, margin-bottom `14px` | matched | matched |

### Connected Exchanges

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Section eyebrow | JetBrains Mono `9px`, letter-spacing `0.1em`, uppercase, `rgba(255,255,255,0.34)`, margin-bottom `9px` | matched | matched |
| Container | border `1px rgba(255,255,255,0.07)`, radius `11px`, overflow hidden, bg `#0e131f`, margin-bottom `18px` | matched | matched |
| Row | padding `12px 14px`, border-bottom `1px rgba(255,255,255,0.07)`, gap `11px` | matched | matched |
| Live dot | `8×8`, radius 50%, bg `#2ee6a6`, glow | matched | matched |
| Name | `13px`, weight 600, `#f2f5fa`, flex 1 | matched | matched |
| Status | JetBrains Mono `9px`, letter-spacing `0.05em`, uppercase, `#2ee6a6` → "Connected" | matched | matched |

### Appearance

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Section eyebrow | JetBrains Mono `9px`, letter-spacing `0.1em`, uppercase, `rgba(255,255,255,0.34)`, margin-bottom `9px` | matched | matched |
| Container | border `1px rgba(255,255,255,0.07)`, radius `11px`, overflow hidden, bg `#0e131f` | matched | matched |
| Row | padding `13px 14px`, border-bottom `1px rgba(255,255,255,0.07)`, justify space-between | matched | matched |
| Label | `13px`, `#f2f5fa` | matched | matched |
| Button | padding `6px 14px`, radius `7px`, border `1px rgba(255,255,255,0.07)`, bg `#10151f`, JetBrains Mono `11px`, weight 600 | matched | matched |
| Theme button text | `#f2f5fa` → "DARK"/"LIGHT" | matched | matched |
| Direction button text | `#00e6d2` → "FLUX"/"CARBON" | matched | matched |

### Footer

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Text | centered, JetBrains Mono `9px`, `rgba(255,255,255,0.34)`, margin-top `24px`, letter-spacing `0.06em` → "YouTrade · v1.0 · 4 venues linked" | matched | matched |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Theme toggle | toggles dark/light | matched | matched |
| Direction toggle | toggles Flux/Carbon | matched | matched |

---

## Auth Gate

The auth gate must align to the mockup visual language: dark `#06080f` background, `#0e131f` card, `#00e6d2` accent, Space Grotesk title, JetBrains Mono body.

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Background | `#06080f` | matched | matched |
| Card | `#0e131f`, border `1px rgba(255,255,255,0.07)`, radius `11px` | matched | matched |
| Accent | `#00e6d2` | matched | matched |
| Title | Space Grotesk, `28px`, weight 600, `#f2f5fa` | matched | matched |
| Subtitle | JetBrains Mono, `13px`, `rgba(255,255,255,0.55)` | matched | matched |
| Primary CTA | height `46px`, radius `8px`, bg `#00e6d2`, text `#06080f`, Space Grotesk `15px`, weight 600 | matched | matched |
| Secondary action | JetBrains Mono `11px`, `rgba(255,255,255,0.55)` | matched | matched |

---

## Audit Summary

| Screen | Status |
|---|---|
| Global / Chrome | matched |
| 1. Home / Portfolio | matched |
| 2. Trading Terminal | matched |
| 3. Markets / Screener | matched |
| 4. Exchange Detail | matched |
| 5. Options Chain | matched |
| 6. Compare | matched |
| 7. Orders & History | matched |
| 8. Account / Settings | matched |
| Auth Gate | matched |

This document is the mockup-side baseline. Each "TBD" current value must be verified and resolved in subsequent screen-alignment tasks.
