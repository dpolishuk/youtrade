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
| Height | `46px` | TBD | TBD |
| Background | transparent (inherits `#06080f`) | TBD | TBD |
| Clock | `9:41`, JetBrains Mono, `13px`, weight 500, letter-spacing `-0.02em`, `#f2f5fa` | TBD | TBD |
| Signal/WiFi/Battery icons | inline SVG, currentColor `#f2f5fa`, size ~17×11 / 16×11 / 25×12 | TBD | TBD |
| Center notch | `#000`, `104×30`, radius `16px` | TBD | TBD |

### App Header

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Padding | `6px 18px 12px` | TBD | TBD |
| Logo container | `30×30`, radius `8px`, bg `#00e6d2` (Flux dark) | TBD | TBD |
| Logo icon | inline SVG white checkmark `17×17` | TBD | TBD |
| App name | Space Grotesk, `16px`, weight 500, letter-spacing `-0.04em`, line-height `1`, `#f2f5fa` | TBD | TBD |
| Header tag | JetBrains Mono, `8.5px`, letter-spacing `0.14em`, uppercase, `#rgba(255,255,255,0.34)` | TBD | TBD |
| Theme toggle | `34×34`, radius `9px`, border `1px rgba(255,255,255,0.07)`, bg `#10151f`, icon color `rgba(255,255,255,0.55)` | TBD | TBD |
| Direction toggle | height `34px`, padding `0 11px`, radius `9px`, border `1px rgba(255,255,255,0.07)`, bg `#10151f`, text `#00e6d2`, JetBrains Mono `10px`, weight 600, letter-spacing `0.08em` | TBD | TBD |
| Direction dot | `7×7`, radius 50%, bg `#00e6d2`, glow `rgba(0,230,210,0.5)` | TBD | TBD |

### Bottom Navigation

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Height | `74px`, padding `8px 8px 22px` | TBD | TBD |
| Background | `#080b12` | TBD | TBD |
| Border top | `1px rgba(255,255,255,0.07)` | TBD | TBD |
| Labels | Portfolio, Markets, Trade, Options, More | TBD | TBD |
| Icon size | `22×22` SVG | TBD | TBD |
| Label font | JetBrains Mono, `8.5px`, weight 600, letter-spacing `0.04em` | TBD | TBD |
| Active color | `#00e6d2` (Flux) | TBD | TBD |
| Inactive color | `rgba(255,255,255,0.34)` | TBD | TBD |
| Active indicator | `4×4` dot, radius 50%, bg `#00e6d2`, glow `rgba(0,230,210,0.5)` | TBD | TBD |
| Touch target | `5px 10px` padding, radius `9px` | TBD | TBD |

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
| Eyebrow | JetBrains Mono, `9.5px`, letter-spacing `0.16em`, uppercase, `rgba(255,255,255,0.34)` | TBD | TBD |
| Total value | Space Grotesk, `43px`, weight 500, letter-spacing `-0.045em`, line-height `0.95`, tabular-nums, `#f2f5fa` | TBD | TBD |
| Fraction cents | Space Grotesk, `0.42em` (~18px), `rgba(255,255,255,0.34)` | TBD | TBD |
| 24h delta | JetBrains Mono, `13px`, weight 600, `#2ee6a6` (Flux up) | TBD | TBD |
| 24h percent | JetBrains Mono, `13px`, weight 600, `#2ee6a6` | TBD | TBD |
| "24h" label | JetBrains Mono, `11px`, `rgba(255,255,255,0.34)` | TBD | TBD |

### Equity Curve Card

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | height `120px`, radius `10px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f` | TBD | TBD |
| Chart | 90-point equity curve starting at `812468.7068931296` | TBD | TBD |
| Line color | `#00e6d2` | TBD | TBD |
| Area gradient | `#00e6d2` 32% → transparent | TBD | TBD |
| End dot | `3.2px` accent + `7px` 40% accent ring | TBD | TBD |
| Range buttons | JetBrains Mono `10px`, weight 600, padding `3px 8px`, radius `5px`, active border `rgba(0,230,210,0.5)`, active bg `rgba(0,230,210,0.18)`, active color `#00e6d2` | TBD | TBD |
| Range labels | `1H`, `1D`, `1W`, `1M`, `1Y` | TBD | TBD |

### Allocation Bar

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Header | JetBrains Mono `9.5px`, letter-spacing `0.14em`, uppercase, `rgba(255,255,255,0.55)` | TBD | TBD |
| Asset mix | JetBrains Mono `9.5px`, letter-spacing `0.06em`, `rgba(255,255,255,0.34)` → "Spot 41 · Perp 38 · Eq 12 · Fut 6 · Opt 3" | TBD | TBD |
| Bar height | `9px`, radius `5px`, gap `2px` | TBD | TBD |
| Binance share | `#f0b90b`, 41.9% | TBD | TBD |
| Bybit share | `#f7a600`, 26.6% | TBD | TBD |
| OKX share | `#00e6d2`, 19.7% | TBD | TBD |
| Coinbase share | `#0052ff`, 11.9% | TBD | TBD |

### Exchange Cards

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Card | padding `13px 14px`, radius `11px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f`, gap `9px` between cards | TBD | TBD |
| Avatar | `36×36`, radius `9px`, bg tinted exchange color, fg exchange color, Space Grotesk `15px`, weight 600 | TBD | TBD |
| Name | `14px`, weight 600, letter-spacing `-0.01em`, `#f2f5fa` | TBD | TBD |
| Live dot | `6×6`, radius 50%, bg `#2ee6a6`, ring `rgba(46,230,166,0.18)` | TBD | TBD |
| Kinds | JetBrains Mono `9.5px`, letter-spacing `0.05em`, uppercase, `rgba(255,255,255,0.34)` | TBD | TBD |
| Value | JetBrains Mono `14px`, weight 600, tabular-nums, `#f2f5fa` | TBD | TBD |
| Percent | JetBrains Mono `11px`, weight 600, up `#2ee6a6` / down `#ff5d77` | TBD | TBD |
| Binance | initial `B`, value `$312,480`, pct `+2.14%` | TBD | TBD |
| Bybit | initial `Y`, value `$198,320`, pct `-0.86%` | TBD | TBD |
| OKX | initial `O`, value `$146,900`, pct `+1.42%` | TBD | TBD |
| Coinbase | initial `C`, value `$88,540`, pct `+0.31%` | TBD | TBD |

### Open Positions

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Header eyebrow | JetBrains Mono `9.5px`, letter-spacing `0.14em`, uppercase, `rgba(255,255,255,0.55)` | TBD | TBD |
| Orders link | JetBrains Mono `10px`, weight 600, `#00e6d2` | TBD | TBD |
| List container | radius `11px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f` | TBD | TBD |
| Row padding | `11px 14px`, border-bottom `1px rgba(255,255,255,0.07)`, gap `11px` | TBD | TBD |
| Avatar | `30×30`, radius `8px`, bg tint, fg icon color, Space Grotesk `12px`, weight 600 | TBD | TBD |
| Symbol | `13px`, weight 600, `#f2f5fa` | TBD | TBD |
| Side badge | JetBrains Mono `8px`, weight 700, letter-spacing `0.06em`, padding `1.5px 5px`, radius `3px`, LONG bg `rgba(46,230,166,0.16)` / SHORT bg `rgba(255,93,119,0.16)` | TBD | TBD |
| Venue/qty | JetBrains Mono `9.5px`, `rgba(255,255,255,0.34)` | TBD | TBD |
| Value | JetBrains Mono `12.5px`, weight 600, tabular-nums, `#f2f5fa` | TBD | TBD |
| P&L | JetBrains Mono `10.5px`, weight 600, up `#2ee6a6` / down `#ff5d77` | TBD | TBD |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Range selector active | border `rgba(0,230,210,0.5)`, bg `rgba(0,230,210,0.18)`, text `#00e6d2` | TBD | TBD |
| Range selector inactive | transparent bg/border, `rgba(255,255,255,0.55)` text | TBD | TBD |
| Exchange card pressed | cursor pointer (web) / opacity or scale expected | TBD | TBD |
| Position row pressed | navigate to terminal | TBD | TBD |
| Orders link | text `#00e6d2`, pointer | TBD | TBD |

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
| Container | horizontal scroll, gap `6px`, padding `2px 16px 12px` | TBD | TBD |
| Chip | padding `6px 11px`, radius `7px`, border `1px` | TBD | TBD |
| Active | bg `rgba(0,230,210,0.15)`, border `rgba(0,230,210,0.4)`, text `#00e6d2` | TBD | TBD |
| Inactive | bg `#10151f`, border `rgba(255,255,255,0.07)`, text `rgba(255,255,255,0.55)` | TBD | TBD |
| Font | JetBrains Mono `11px`, weight 600, letter-spacing `0.02em` | TBD | TBD |
| Labels | BTC, ETH, SOL, AAPL, GOLD | TBD | TBD |

### Price Header

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Symbol | Space Grotesk `19px`, weight 600, letter-spacing `-0.02em`, `#f2f5fa` | TBD | TBD |
| Class tag | JetBrains Mono `8px`, weight 700, letter-spacing `0.08em`, padding `2px 6px`, radius `3px`, bg `#10151f`, border `1px rgba(255,255,255,0.07)`, text `rgba(255,255,255,0.55)` | TBD | TBD |
| Name/venue | `11px`, `rgba(255,255,255,0.34)` | TBD | TBD |
| Last price | JetBrains Mono `24px`, weight 600, letter-spacing `-0.01em`, tabular-nums, line-height `1`, up/down color | TBD | TBD |
| Change | JetBrains Mono `12px`, weight 600, up/down color | TBD | TBD |
| Default BTC price | `105154.04697406417` → formatted `105,154.0` | TBD | TBD |
| 24h change | `+6,346.7` / `+6.42%` | TBD | TBD |

### Stat Strip

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | grid 4 columns, gap `1px`, bg `rgba(255,255,255,0.07)`, border `1px rgba(255,255,255,0.07)`, radius `8px`, overflow hidden | TBD | TBD |
| Cell | bg `#0e131f`, padding `8px 10px` | TBD | TBD |
| Label | `8.5px`, letter-spacing `0.08em`, uppercase, `rgba(255,255,255,0.34)` | TBD | TBD |
| Value | JetBrains Mono `12px`, weight 500, `#f2f5fa`; Funding value `#2ee6a6` | TBD | TBD |
| High | computed from last 24 candles | TBD | TBD |
| Low | computed from last 24 candles | TBD | TBD |
| Vol | `(sum volume * last / 1e6)M` | TBD | TBD |
| Funding | `+0.0102%` | TBD | TBD |

### Chart Toolbar

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Timeframe buttons | padding `4px 9px`, radius `5px`, JetBrains Mono `10.5px`, weight 600 | TBD | TBD |
| Active TF | text `#00e6d2`, bg `rgba(0,230,210,0.15)`, border `rgba(0,230,210,0.4)` | TBD | TBD |
| Inactive TF | text `rgba(255,255,255,0.34)`, transparent | TBD | TBD |
| Compare button | `30×26`, radius `6px`, border `1px rgba(255,255,255,0.07)`, bg `#10151f`, icon `#00e6d2`, `15×15` SVG | TBD | TBD |

### Candlestick Chart

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | margin `0 12px`, radius `10px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f`, glow `rgba(0,230,210,0)` to `rgba(...)` | TBD | TBD |
| Height | `248px` canvas | TBD | TBD |
| MA labels | MA7 `#00e6d2` 90%, MA25 `#ffb020` | TBD | TBD |
| Grid | `rgba(255,255,255,0.045)` | TBD | TBD |
| Bull candle | `#2ee6a6` | TBD | TBD |
| Bear candle | `#ff5d77` | TBD | TBD |
| Volume bars | 32% opacity of candle color | TBD | TBD |
| Last price line | dashed `3,3`, 60% opacity of last candle color | TBD | TBD |
| Crosshair | dashed `2,3`, `rgba(255,255,255,0.25)` | TBD | TBD |

### Lower Tabs

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | padding `14px 16px 0`, border-bottom `1px rgba(255,255,255,0.07)` | TBD | TBD |
| Tab | flex 1, padding `0 0 10px`, border-bottom `2px` | TBD | TBD |
| Active | text `#f2f5fa`, bar `#00e6d2` | TBD | TBD |
| Inactive | text `rgba(255,255,255,0.34)`, bar `transparent` | TBD | TBD |
| Font | JetBrains Mono `11px`, weight 600, letter-spacing `0.03em` | TBD | TBD |
| Labels | Trade, Book, Info, Signals | TBD | TBD |

### Trade Tab

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Buy/Long button | flex 1, height `38px`, radius `7px`, border `1px`, Space Grotesk `14px`, weight 600 | TBD | TBD |
| Active buy | bg `rgba(46,230,166,0.18)`, border `rgba(46,230,166,0.6)`, text `#2ee6a6` | TBD | TBD |
| Inactive buy | transparent, border `rgba(255,255,255,0.07)`, text `rgba(255,255,255,0.55)` | TBD | TBD |
| Active sell | bg `rgba(255,93,119,0.18)`, border `rgba(255,93,119,0.6)`, text `#ff5d77` | TBD | TBD |
| Order type chips | height `30px`, radius `6px`, no border, JetBrains Mono `11px`, weight 600 | TBD | TBD |
| Active order type | bg `#f2f5fa`, text `#06080f` | TBD | TBD |
| Inactive order type | bg `transparent`, text `rgba(255,255,255,0.55)` | TBD | TBD |
| Price row | height `40px`, padding `0 12px`, radius `7px`, border `1px rgba(255,255,255,0.07)`, bg `#10151f` | TBD | TBD |
| Price label | `10px`, uppercase, letter-spacing `0.06em`, `rgba(255,255,255,0.34)` | TBD | TBD |
| Price value | JetBrains Mono `14px`, weight 500, `#f2f5fa` | TBD | TBD |
| Leverage slider | range 1–100, accent `#00e6d2` | TBD | TBD |
| Size pct buttons | height `28px`, radius `6px`, JetBrains Mono `10.5px`, weight 600 | TBD | TBD |
| Active size pct | text `#00e6d2`, bg `rgba(0,230,210,0.15)`, border `rgba(0,230,210,0.4)` | TBD | TBD |
| Submit CTA | width 100%, height `46px`, radius `8px`, Space Grotesk `15px`, weight 600, white text, shadow `0 0 20px -6px sideColor` | TBD | TBD |

### Book Tab

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Header | JetBrains Mono `8.5px`, letter-spacing `0.08em`, uppercase, `rgba(255,255,255,0.34)` | TBD | TBD |
| Ask row | padding `3px 6px`, JetBrains Mono `11px`, price `#ff5d77`, size `rgba(255,255,255,0.55)`, depth bar `rgba(255,93,119,0.12)` | TBD | TBD |
| Bid row | padding `3px 6px`, JetBrains Mono `11px`, price `#2ee6a6`, size `rgba(255,255,255,0.55)`, depth bar `rgba(46,230,166,0.12)` | TBD | TBD |
| Mid price strip | border-top/bottom `1px rgba(255,255,255,0.07)`, padding `8px 6px`, margin `4px 0` | TBD | TBD |
| Mid price | JetBrains Mono `15px`, weight 600, up/down color | TBD | TBD |
| Spread text | JetBrains Mono `10px`, `rgba(255,255,255,0.34)` | TBD | TBD |

### Info Tab

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Tag cards | flex 1, padding `10px 12px`, radius `8px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f` | TBD | TBD |
| Tag label | `9px`, letter-spacing `0.07em`, uppercase, `rgba(255,255,255,0.34)` | TBD | TBD |
| Tag value | JetBrains Mono `15px`, weight 600, up color or `#f2f5fa` | TBD | TBD |
| Stats grid | 2 columns, gap `1px`, bg/border `rgba(255,255,255,0.07)`, radius `8px` | TBD | TBD |
| Stats cell | bg `#0e131f`, padding `10px 12px` | TBD | TBD |
| Stats key | `11px`, `rgba(255,255,255,0.34)` | TBD | TBD |
| Stats value | JetBrains Mono `12px`, weight 500, `#f2f5fa` | TBD | TBD |
| About eyebrow | JetBrains Mono `9px`, letter-spacing `0.1em`, uppercase, `rgba(255,255,255,0.34)` | TBD | TBD |
| About body | `12.5px`, line-height `1.55`, `rgba(255,255,255,0.55)` | TBD | TBD |

### Signals Tab

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Gauge arcs | down `#ff5d77` 85%, mid `#ffb020` 85%, up `#2ee6a6` 85%, stroke width `11`, linecap round | TBD | TBD |
| Gauge needle | `#f2f5fa`, `3×46px`, pivot `9px` white dot | TBD | TBD |
| Verdict | Space Grotesk `26px`, weight 600, letter-spacing `-0.02em`, line-height `1`, verdict color | TBD | TBD |
| Verdict text | BUY/NEUTRAL/SELL | TBD | TBD |
| Signal counts | JetBrains Mono `11px`, `rgba(255,255,255,0.34)` | TBD | TBD |
| Oscillator score | JetBrains Mono `11px`, `rgba(255,255,255,0.55)` | TBD | TBD |
| Section eyebrow | JetBrains Mono `9px`, letter-spacing `0.1em`, uppercase, `rgba(255,255,255,0.34)` | TBD | TBD |
| List container | radius `8px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f` | TBD | TBD |
| List row | padding `9px 12px`, border-bottom `1px rgba(255,255,255,0.07)` | TBD | TBD |
| Indicator name | `12px`, `rgba(255,255,255,0.55)` | TBD | TBD |
| Indicator value | JetBrains Mono `12px`, `#f2f5fa` | TBD | TBD |
| Signal label | JetBrains Mono `10px`, weight 600, width `64px` / `36px`, right-aligned | TBD | TBD |
| Pivot grid | 5 columns, gap `1px`, bg/border `rgba(255,255,255,0.07)`, radius `8px` | TBD | TBD |
| Pivot cell | bg `#0e131f`, padding `9px 4px`, text centered | TBD | TBD |
| Pivot key | `9px`, `rgba(255,255,255,0.34)` | TBD | TBD |
| Pivot value | JetBrains Mono `10px`, `#f2f5fa` | TBD | TBD |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Symbol chip active | accent bg/border/text | TBD | TBD |
| Symbol chip inactive | chip bg/line text | TBD | TBD |
| Timeframe active | accent | TBD | TBD |
| Buy/Long active | green | TBD | TBD |
| Sell/Short active | red | TBD | TBD |
| Order type active | white bg, dark text | TBD | TBD |
| Size pct active | accent | TBD | TBD |
| Submit hover/press | shadow intensity | TBD | TBD |
| Compare button | accent icon | TBD | TBD |
| Lower tab active | white text + accent bar | TBD | TBD |
| Flash up | `yt-flash-up` animation: green 30% → transparent 0.6s | TBD | TBD |
| Flash down | `yt-flash-down` animation: red 30% → transparent 0.6s | TBD | TBD |

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
| Container | height `38px`, padding `0 12px`, radius `8px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f`, margin-bottom `12px` | TBD | TBD |
| Icon | `15×15` magnifier SVG, color `rgba(255,255,255,0.34)` | TBD | TBD |
| Placeholder | `13px`, `rgba(255,255,255,0.34)` → "Search symbols, venues, assets" | TBD | TBD |

### Filter Chips

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | horizontal scroll, gap `6px`, margin-bottom `12px` | TBD | TBD |
| Chip | padding `6px 13px`, radius `7px`, border `1px`, JetBrains Mono `11px`, weight 600 | TBD | TBD |
| Active | bg `#f2f5fa`, text `#06080f`, border `#f2f5fa` | TBD | TBD |
| Inactive | bg `transparent`, text `rgba(255,255,255,0.55)`, border `rgba(255,255,255,0.07)` | TBD | TBD |
| Labels | All, Crypto, Stocks, Futures, Options | TBD | TBD |

### List Header

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Row | padding `0 4px 8px`, justify space-between | TBD | TBD |
| Text | JetBrains Mono `8.5px`, letter-spacing `0.08em`, uppercase, `rgba(255,255,255,0.34)` → "Symbol" / "Last · 24h" | TBD | TBD |

### Market Rows

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | border `1px rgba(255,255,255,0.07)`, radius `11px`, overflow hidden, bg `#0e131f` | TBD | TBD |
| Row | padding `11px 13px`, border-bottom `1px rgba(255,255,255,0.07)`, gap `11px` | TBD | TBD |
| Label | Space Grotesk `13px`, weight 600, letter-spacing `-0.01em`, `#f2f5fa` | TBD | TBD |
| Class badge | JetBrains Mono `7.5px`, weight 700, letter-spacing `0.06em`, margin-top `3px` | TBD | TBD |
| Name | `11.5px`, `rgba(255,255,255,0.55)`, ellipsis | TBD | TBD |
| Venue | JetBrains Mono `8.5px`, `rgba(255,255,255,0.34)` | TBD | TBD |
| Sparkline | `46×24` canvas | TBD | TBD |
| Price | JetBrains Mono `12.5px`, weight 600, tabular-nums, `#f2f5fa` | TBD | TBD |
| Change | JetBrains Mono `10.5px`, weight 600, up/down color | TBD | TBD |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Filter chip active | white/dark | TBD | TBD |
| Row press | navigate to terminal or options | TBD | TBD |

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
| Row | flex, gap `5px`, padding `0 0 12px`, color `rgba(255,255,255,0.34)` | TBD | TBD |
| Icon | `13×13` left chevron SVG | TBD | TBD |
| Text | JetBrains Mono `11px` → "All portfolios" | TBD | TBD |

### Venue Chips

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | horizontal scroll, gap `6px`, margin-bottom `16px` | TBD | TBD |
| Chip | padding `7px 14px`, radius `7px`, border `1px`, Space Grotesk `13px`, weight 600 | TBD | TBD |
| Active | bg `#f2f5fa`, text `#06080f`, border `#f2f5fa` | TBD | TBD |
| Inactive | bg `transparent`, text `rgba(255,255,255,0.55)`, border `rgba(255,255,255,0.07)` | TBD | TBD |

### Header

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Color dot | `10×10`, radius `3px`, exchange color | TBD | TBD |
| Name | Space Grotesk `20px`, weight 600, letter-spacing `-0.02em`, `#f2f5fa` | TBD | TBD |
| API live | JetBrains Mono `9px`, `#2ee6a6`, dot `6×6` with glow | TBD | TBD |
| Kinds | JetBrains Mono `9px`, letter-spacing `0.06em`, uppercase, `rgba(255,255,255,0.34)` | TBD | TBD |

### Balance / P&L Cards

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | flex 1, padding `14px`, radius `10px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f`, gap `10px` | TBD | TBD |
| Label | `9px`, letter-spacing `0.07em`, uppercase, `rgba(255,255,255,0.34)` | TBD | TBD |
| Value | Space Grotesk `24px`, weight 600, letter-spacing `-0.03em`, tabular-nums, `#f2f5fa` or up/down color | TBD | TBD |
| P&L percent | JetBrains Mono `11px`, up/down color | TBD | TBD |
| Binance | total `$312,480`, P&L `+$6,620.00` / `+2.12%` | TBD | TBD |

### Balances List

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Section eyebrow | JetBrains Mono `9px`, letter-spacing `0.1em`, uppercase, `rgba(255,255,255,0.34)` | TBD | TBD |
| Container | radius `11px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f`, overflow hidden | TBD | TBD |
| Row | padding `12px 14px`, border-bottom `1px rgba(255,255,255,0.07)`, gap `11px` | TBD | TBD |
| Glyph | `32×32`, radius `8px`, bg `#10151f`, border `1px rgba(255,255,255,0.07)`, Space Grotesk `13px`, weight 600, `#f2f5fa` | TBD | TBD |
| Symbol | `13px`, weight 600, `#f2f5fa` | TBD | TBD |
| Value | JetBrains Mono `13px`, weight 500, `#f2f5fa` | TBD | TBD |
| Allocation bar | height `4px`, radius `2px`, bg `#10151f`, fill exchange color | TBD | TBD |
| Share | JetBrains Mono `9px`, `rgba(255,255,255,0.34)` | TBD | TBD |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Venue chip active | white/dark | TBD | TBD |
| Asset row press | terminal | TBD | TBD |
| Back link press | navigate back | TBD | TBD |

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
| Symbol | Space Grotesk `18px`, weight 600, `#f2f5fa` | TBD | TBD |
| OPTIONS tag | JetBrains Mono `8px`, weight 700, letter-spacing `0.06em`, padding `2px 6px`, radius `3px`, bg `#10151f`, border `1px rgba(255,255,255,0.07)` | TBD | TBD |
| Spot label | JetBrains Mono `8.5px`, letter-spacing `0.06em`, uppercase, `rgba(255,255,255,0.34)` | TBD | TBD |
| Spot value | JetBrains Mono `15px`, weight 600, `#f2f5fa` | TBD | TBD |

### Expiration Chips

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | horizontal scroll, gap `6px`, padding `0 4px 12px` | TBD | TBD |
| Chip | padding `6px 12px`, radius `7px`, border `1px`, JetBrains Mono `10.5px`, weight 600 | TBD | TBD |
| Active | accent | TBD | TBD |
| Inactive | chip/line colors | TBD | TBD |

### Column Headers

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Top header | grid 3 columns, JetBrains Mono `8px`, letter-spacing `0.08em`, uppercase, calls `#2ee6a6`, strike `rgba(255,255,255,0.34)`, puts `#ff5d77` | TBD | TBD |
| Sub-header | grid 7 columns, JetBrains Mono `7.5px`, letter-spacing `0.04em`, uppercase, `rgba(255,255,255,0.34)` | TBD | TBD |

### Strike Rows

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | border `1px rgba(255,255,255,0.07)`, radius `10px`, overflow hidden | TBD | TBD |
| Row | grid 7 columns, gap `2px`, padding `8px 6px`, border-bottom `1px rgba(255,255,255,0.07)`, bg `rgba(0,230,210,0.08)` if ATM | TBD | TBD |
| IV | JetBrains Mono `9.5px`, `rgba(255,255,255,0.34)` | TBD | TBD |
| Delta | JetBrains Mono `9.5px`, `rgba(255,255,255,0.55)` | TBD | TBD |
| Mark | JetBrains Mono `9.5px`, weight 600, right-aligned | TBD | TBD |
| Strike | JetBrains Mono `9.5px`, weight 700, centered, `#00e6d2` if ATM else `#f2f5fa` | TBD | TBD |
| Footer | JetBrains Mono `9px`, `rgba(255,255,255,0.34)`, centered → "ATM strike 106,000 · highlighted" | TBD | TBD |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Expiration active | accent | TBD | TBD |
| ATM row | accent tinted background | TBD | TBD |

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
| Title | Space Grotesk `18px`, weight 600, letter-spacing `-0.02em`, `#f2f5fa` | TBD | TBD |
| Count | JetBrains Mono `9px`, `rgba(255,255,255,0.34)` → "3/4 · normalized %" | TBD | TBD |

### Symbol Chips

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | horizontal scroll, gap `6px`, margin-bottom `14px` | TBD | TBD |
| Chip | padding `6px 13px`, radius `7px`, border `1px`, JetBrains Mono `11px`, weight 600 | TBD | TBD |
| Active | bg symbol color, text white, border symbol color | TBD | TBD |
| Inactive | bg `#10151f`, border `rgba(255,255,255,0.07)`, text `rgba(255,255,255,0.55)` | TBD | TBD |
| Colors | BTC `#00e6d2`, ETH `#ffb020`, SOL `#ff5d77`, AAPL `#8b9cf0`, GOLD `#c9a6ff` | TBD | TBD |

### Chart

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|
| Container | border `1px rgba(255,255,255,0.07)`, radius `10px`, bg `#0e131f`, glow | TBD | TBD |
| Height | `220px` | TBD | TBD |
| Grid | `rgba(255,255,255,0.045)` | TBD | TBD |
| Zero line | `rgba(255,255,255,0.5)` | TBD | TBD |
| Lines | symbol colors, width `1.8` | TBD | TBD |
| End dots | `3px` at right edge | TBD | TBD |

### Legend

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | flex wrap, gap `14px`, margin `14px 4px` | TBD | TBD |
| Color bar | `14×3`, radius `2px` | TBD | TBD |
| Symbol | JetBrains Mono `11px`, weight 600, `#f2f5fa` | TBD | TBD |
| Change | JetBrains Mono `11px`, up/down color | TBD | TBD |

### Stats Table

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Section eyebrow | JetBrains Mono `9px`, letter-spacing `0.1em`, uppercase, `rgba(255,255,255,0.34)` | TBD | TBD |
| Container | border `1px rgba(255,255,255,0.07)`, radius `10px`, overflow hidden | TBD | TBD |
| Header row | grid 3 columns, padding `9px 14px`, border-bottom `1px rgba(255,255,255,0.07)`, bg `#0e131f`, JetBrains Mono `8.5px`, letter-spacing `0.06em`, uppercase, `rgba(255,255,255,0.34)` | TBD | TBD |
| Data row | grid 3 columns, padding `11px 14px`, border-bottom `1px rgba(255,255,255,0.07)`, bg `#0e131f` | TBD | TBD |
| Symbol | JetBrains Mono `12px`, weight 600, `#f2f5fa` | TBD | TBD |
| Return | right-aligned, up/down color | TBD | TBD |
| Volatility | right-aligned, `rgba(255,255,255,0.55)` | TBD | TBD |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Chip selected | filled symbol color, white text | TBD | TBD |
| Chip unselected | chip style | TBD | TBD |

---

## 7. Orders & History

### Layout Sections

1. Title
2. Tabs
3. Open orders / History / Positions content

### Header

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Title | Space Grotesk `18px`, weight 600, letter-spacing `-0.02em`, `#f2f5fa`, margin-bottom `14px` | TBD | TBD |

### Tabs

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | flex, border-bottom `1px rgba(255,255,255,0.07)`, margin-bottom `14px` | TBD | TBD |
| Tab | flex 1, padding `0 0 10px`, border-bottom `2px` | TBD | TBD |
| Active | text `#f2f5fa`, bar `#00e6d2` | TBD | TBD |
| Inactive | text `rgba(255,255,255,0.34)`, bar `transparent` | TBD | TBD |
| Font | JetBrains Mono `11px`, weight 600 | TBD | TBD |

### Open Orders

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | flex column, gap `9px` | TBD | TBD |
| Card | padding `12px 14px`, radius `10px`, border `1px rgba(255,255,255,0.07)`, bg `#0e131f` | TBD | TBD |
| Side badge | JetBrains Mono `8px`, weight 700, letter-spacing `0.06em`, padding `2px 6px`, radius `3px` | TBD | TBD |
| Symbol | `13px`, weight 600, `#f2f5fa` | TBD | TBD |
| Type/venue | JetBrains Mono `10px`, `rgba(255,255,255,0.34)` | TBD | TBD |
| Cancel | JetBrains Mono `10px`, weight 600, `#00e6d2` | TBD | TBD |
| Price/qty row | JetBrains Mono `11px`, justify space-between | TBD | TBD |

### History

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Container | border `1px rgba(255,255,255,0.07)`, radius `11px`, overflow hidden, bg `#0e131f` | TBD | TBD |
| Row | padding `11px 14px`, border-bottom `1px rgba(255,255,255,0.07)`, gap `10px` | TBD | TBD |
| Symbol | `12.5px`, weight 600, `#f2f5fa` | TBD | TBD |
| Details | JetBrains Mono `9px`, `rgba(255,255,255,0.34)` | TBD | TBD |
| Price | JetBrains Mono `12px`, `#f2f5fa` | TBD | TBD |
| Qty/status | JetBrains Mono `9.5px`, status color | TBD | TBD |
| Filled | `rgba(255,255,255,0.55)` | TBD | TBD |
| Cancelled | `rgba(255,255,255,0.34)` | TBD | TBD |

### Positions Tab

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Same as Home open positions | see Home section | TBD | TBD |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Tab active | accent bar | TBD | TBD |
| Cancel press | demo-remove | TBD | TBD |

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
| Text | Space Grotesk `18px`, weight 600, letter-spacing `-0.02em`, `#f2f5fa`, margin-bottom `14px` | TBD | TBD |

### Connected Exchanges

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Section eyebrow | JetBrains Mono `9px`, letter-spacing `0.1em`, uppercase, `rgba(255,255,255,0.34)`, margin-bottom `9px` | TBD | TBD |
| Container | border `1px rgba(255,255,255,0.07)`, radius `11px`, overflow hidden, bg `#0e131f`, margin-bottom `18px` | TBD | TBD |
| Row | padding `12px 14px`, border-bottom `1px rgba(255,255,255,0.07)`, gap `11px` | TBD | TBD |
| Live dot | `8×8`, radius 50%, bg `#2ee6a6`, glow | TBD | TBD |
| Name | `13px`, weight 600, `#f2f5fa`, flex 1 | TBD | TBD |
| Status | JetBrains Mono `9px`, letter-spacing `0.05em`, uppercase, `#2ee6a6` → "Connected" | TBD | TBD |

### Appearance

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Section eyebrow | JetBrains Mono `9px`, letter-spacing `0.1em`, uppercase, `rgba(255,255,255,0.34)`, margin-bottom `9px` | TBD | TBD |
| Container | border `1px rgba(255,255,255,0.07)`, radius `11px`, overflow hidden, bg `#0e131f` | TBD | TBD |
| Row | padding `13px 14px`, border-bottom `1px rgba(255,255,255,0.07)`, justify space-between | TBD | TBD |
| Label | `13px`, `#f2f5fa` | TBD | TBD |
| Button | padding `6px 14px`, radius `7px`, border `1px rgba(255,255,255,0.07)`, bg `#10151f`, JetBrains Mono `11px`, weight 600 | TBD | TBD |
| Theme button text | `#f2f5fa` → "DARK"/"LIGHT" | TBD | TBD |
| Direction button text | `#00e6d2` → "FLUX"/"CARBON" | TBD | TBD |

### Footer

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Text | centered, JetBrains Mono `9px`, `rgba(255,255,255,0.34)`, margin-top `24px`, letter-spacing `0.06em` → "YouTrade · v1.0 · 4 venues linked" | TBD | TBD |

### Interactive States

| State | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Theme toggle | toggles dark/light | TBD | TBD |
| Direction toggle | toggles Flux/Carbon | TBD | TBD |

---

## Auth Gate

The auth gate must align to the mockup visual language: dark `#06080f` background, `#0e131f` card, `#00e6d2` accent, Space Grotesk title, JetBrains Mono body.

| Element | Mockup value | Current Flutter value | Status |
|---|---|---|---|
| Background | `#06080f` | TBD | TBD |
| Card | `#0e131f`, border `1px rgba(255,255,255,0.07)`, radius `11px` | TBD | TBD |
| Accent | `#00e6d2` | TBD | TBD |
| Title | Space Grotesk, `28px`, weight 600, `#f2f5fa` | TBD | TBD |
| Subtitle | JetBrains Mono, `13px`, `rgba(255,255,255,0.55)` | TBD | TBD |
| Primary CTA | height `46px`, radius `8px`, bg `#00e6d2`, text `#06080f`, Space Grotesk `15px`, weight 600 | TBD | TBD |
| Secondary action | JetBrains Mono `11px`, `rgba(255,255,255,0.55)` | TBD | TBD |

---

## Audit Summary

| Screen | Status |
|---|---|
| Global / Chrome | TBD |
| 1. Home / Portfolio | TBD |
| 2. Trading Terminal | TBD |
| 3. Markets / Screener | TBD |
| 4. Exchange Detail | TBD |
| 5. Options Chain | TBD |
| 6. Compare | TBD |
| 7. Orders & History | TBD |
| 8. Account / Settings | TBD |
| Auth Gate | TBD |

This document is the mockup-side baseline. Each "TBD" current value must be verified and resolved in subsequent screen-alignment tasks.
