# YouTrade Design Tokens

Source of truth extracted from [`mockups/colors_and_type.css`](../mockups/colors_and_type.css) and the inline theme logic in [`mockups/YouTrade.dc.html`](../mockups/YouTrade.dc.html).

All CSS custom properties are recorded with their Flutter/Dart equivalents. Pixel values are logical pixels (Flutter uses logical pixels by default; the mockup is rendered at 1× CSS pixel on a 390×844 viewport).

The runtime source of truth for the semantic tokens below is `AppColorTheme` in [`lib/presentation/theme/theme_extensions.dart`](../lib/presentation/theme/theme_extensions.dart). `AppColorTheme` exposes direction- and theme-aware values such as `bg`, `card`, `accent`, `up`, and `down`, and is retrieved via `Theme.of(context).extension<AppColorTheme>()`. Use `AppColorTheme` directly in widgets rather than hard-coding the static values in this document.

---

## Type Families

| CSS Token | Value | Flutter Equivalent |
|---|---|---|
| `--font-sans` | `Geist, ui-sans-serif, system-ui, sans-serif` | `fontFamily: 'Geist'` (fallback `sans-serif`) |
| `--font-display` | `Space Grotesk, Geist, ui-sans-serif, system-ui, sans-serif` | `fontFamily: 'Space Grotesk'` |
| `--font-mono` | `JetBrains Mono, ui-monospace, SFMono-Regular, Menlo, Consolas, monospace` | `fontFamily: 'JetBrains Mono'` |
| `--font-serif` | `Instrument Serif, Georgia, serif` | `fontFamily: 'Instrument Serif'` |

All four families are already declared in `pubspec.yaml` under `flutter:fonts:`.

---

## Type Scale

| CSS Token | CSS Value | Flutter Equivalent |
|---|---|---|
| `--text-display` | `5rem` → `80px` | `fontSize: 80` |
| `--text-display-lh` | `1` | `height: 1.0` |
| `--text-display-ls` | `-0.02em` | `letterSpacing: -0.02` (em → multiplier) |
| `--text-ui` | `0.75rem` → `12px` | `fontSize: 12` |
| `--text-ui-lh` | `1.2` | `height: 1.2` |
| `--text-ui-ls` | `0.05em` | `letterSpacing: 0.05` |
| `--text-ui-xs` | `0.5625rem` → `9px` | `fontSize: 9` |
| `--text-ui-xs-lh` | `1.2` | `height: 1.2` |
| `--text-ui-xs-ls` | `0.07em` | `letterSpacing: 0.07` |

---

## Neutral / Brand Primitives

| CSS Token | Value | Flutter `Color` |
|---|---|---|
| `--color-carbon` | `#020d23` | `Color(0xFF020D23)` |
| `--color-carbon-hover` | `#061336` | `Color(0xFF061336)` |
| `--color-carbon-muted` | `#212b44` | `Color(0xFF212B44)` |
| `--color-carbon-60` | `rgba(2,13,35,0.6)` | `Color(0x99020D23)` |
| `--color-carbon-40` | `rgba(2,13,35,0.4)` | `Color(0x66020D23)` |
| `--color-carbon-8` | `rgba(2,13,35,0.08)` | `Color(0x14020D23)` |
| `--color-carbon-4` | `rgba(2,13,35,0.04)` | `Color(0x0A020D23)` |
| `--color-titanium` | `#f7f4f3` | `Color(0xFFF7F4F3)` |
| `--color-dark` | `#030612` | `Color(0xFF030612)` |
| `--color-white-70` | `rgba(255,255,255,0.7)` | `Color(0xB3FFFFFF)` |
| `--color-white-50` | `rgba(255,255,255,0.5)` | `Color(0x80FFFFFF)` |
| `--color-white-15` | `rgba(255,255,255,0.15)` | `Color(0x26FFFFFF)` |
| `--color-white-8` | `rgba(255,255,255,0.08)` | `Color(0x14FFFFFF)` |
| `--color-cobalt-bold` | `#152d80` | `Color(0xFF152D80)` |
| `--color-cobalt-soft` | `#b4d7ff` | `Color(0xFFB4D7FF)` |
| `--color-cobalt-vivid` | `#0355f3` | `Color(0xFF0355F3)` |
| `--color-turquoise-bold` | `#005060` | `Color(0xFF005060)` |
| `--color-turquoise-soft` | `#bdecf6` | `Color(0xFFBDECF6)` |
| `--color-turquoise-vivid` | `#00bbcc` | `Color(0xFF00BBCC)` |
| `--color-emerald-bold` | `#1d683f` | `Color(0xFF1D683F)` |
| `--color-emerald-soft` | `#e8f5ce` | `Color(0xFFE8F5CE)` |
| `--color-emerald-vivid` | `#01a54c` | `Color(0xFF01A54C)` |
| `--color-amethyst-bold` | `#4c2672` | `Color(0xFF4C2672)` |
| `--color-amethyst-soft` | `#e9cdff` | `Color(0xFFE9CDFF)` |
| `--color-amethyst-vivid` | `#ae89ff` | `Color(0xFFAE89FF)` |
| `--color-fuchsia-bold` | `#720741` | `Color(0xFF720741)` |
| `--color-fuchsia-soft` | `#ffcce7` | `Color(0xFFFFCCE7)` |
| `--color-fuchsia-vivid` | `#ff8afa` | `Color(0xFFFF8AFA)` |
| `--color-sienna-bold` | `#ad4010` | `Color(0xFFAD4010)` |
| `--color-sienna-soft` | `#fce3c5` | `Color(0xFFFCE3C5)` |
| `--color-sienna-vivid` | `#ffc368` | `Color(0xFFFFC368)` |
| `--color-ochre-bold` | `#995e05` | `Color(0xFF995E05)` |
| `--color-ochre-soft` | `#fbeebb` | `Color(0xFFFBEEBB)` |
| `--color-ochre-vivid` | `#ffd468` | `Color(0xFFFFD468)` |

---

## Interactive Blue

| CSS Token | Value | Flutter `Color` |
|---|---|---|
| `--color-blue` | `#1634ef` | `Color(0xFF1634EF)` |
| `--color-blue-hover` | `#3952f1` | `Color(0xFF3952F1)` |
| `--color-blue-subtle` | `#e0e2ff` | `Color(0xFFE0E2FF)` |
| `--color-blue-muted` | `#eff0fc` | `Color(0xFFEFF0FC)` |

---

## Status

| CSS Token | Value | Flutter `Color` |
|---|---|---|
| `--color-success` | `#1d683f` | `Color(0xFF1D683F)` |
| `--color-success-bg` | `#e8f5ce` | `Color(0xFFE8F5CE)` |
| `--color-success-border` | `rgba(29,104,63,0.3)` | `Color(0x4D1D683F)` |
| `--color-warning` | `#995e05` | `Color(0xFF995E05)` |
| `--color-warning-bg` | `#fefce8` | `Color(0xFFFEFCE8)` |
| `--color-warning-border` | `rgba(153,94,5,0.3)` | `Color(0x4D995E05)` |

---

## Semantic — Light Theme

| CSS Token | Value | Flutter `Color` |
|---|---|---|
| `--color-background` | `#ffffff` | `Color(0xFFFFFFFF)` |
| `--color-foreground` | `#020d23` | `Color(0xFF020D23)` |
| `--color-primary` | `#1634ef` | `Color(0xFF1634EF)` |
| `--color-primary-foreground` | `#ffffff` | `Color(0xFFFFFFFF)` |
| `--color-secondary` | `#f7f4f3` | `Color(0xFFF7F4F3)` |
| `--color-secondary-foreground` | `#020d23` | `Color(0xFF020D23)` |
| `--color-accent` | `#f7f4f3` | `Color(0xFFF7F4F3)` |
| `--color-accent-foreground` | `#020d23` | `Color(0xFF020D23)` |
| `--color-destructive` | `lch(94.759 3.672 17.122)` | `Color(0xFFFEF0F0)` (approx) |
| `--color-destructive-foreground` | `lch(50 80 29)` | `Color(0xFFB42318)` (approx) |
| `--color-error` | `lch(50 80 29)` | `Color(0xFFB42318)` (approx) |
| `--color-error-bg` | `lch(94.759 3.672 17.122)` | `Color(0xFFFEF0F0)` (approx) |
| `--color-error-border` | `lch(50 80 29 / 0.3)` | `Color(0x4DB42318)` (approx) |
| `--color-muted` | `#f7f4f3` | `Color(0xFFF7F4F3)` |
| `--color-muted-foreground` | `rgba(2,13,35,0.6)` | `Color(0x99020D23)` |
| `--color-card` | `#ffffff` | `Color(0xFFFFFFFF)` |
| `--color-card-foreground` | `#020d23` | `Color(0xFF020D23)` |
| `--color-border` | `rgba(2,13,35,0.08)` | `Color(0x14020D23)` |
| `--color-ring` | `#1634ef` | `Color(0xFF1634EF)` |

---

## Semantic — Dark Theme

| CSS Token | Value | Flutter `Color` |
|---|---|---|
| `--color-background` | `#050505` | `Color(0xFF050505)` |
| `--color-foreground` | `#ffffff` | `Color(0xFFFFFFFF)` |
| `--color-primary` | `#1634ef` | `Color(0xFF1634EF)` |
| `--color-primary-foreground` | `#ffffff` | `Color(0xFFFFFFFF)` |
| `--color-secondary` | `#1a1a1a` | `Color(0xFF1A1A1A)` |
| `--color-secondary-foreground` | `#ffffff` | `Color(0xFFFFFFFF)` |
| `--color-accent` | `#1a1a1a` | `Color(0xFF1A1A1A)` |
| `--color-accent-foreground` | `#ffffff` | `Color(0xFFFFFFFF)` |
| `--color-destructive` | `lch(11.798 12.827 18.725)` | `Color(0xFF2A1212)` (approx) |
| `--color-destructive-foreground` | `lch(80 80 29)` | `Color(0xFFFFB4A9)` (approx) |
| `--color-error` | `lch(80 80 29)` | `Color(0xFFFFB4A9)` (approx) |
| `--color-error-bg` | `lch(11.798 12.827 18.725)` | `Color(0xFF2A1212)` (approx) |
| `--color-error-border` | `lch(80 80 29 / 0.3)` | `Color(0x4DFFB4A9)` (approx) |
| `--color-muted` | `#1a1a1a` | `Color(0xFF1A1A1A)` |
| `--color-muted-foreground` | `rgba(255,255,255,0.55)` | `Color(0x8CFFFFFF)` |
| `--color-card` | `lab(8.30603 0.618205 -2.16572)` | `Color(0xFF0E0E0E)` (approx) |
| `--color-card-foreground` | `#ffffff` | `Color(0xFFFFFFFF)` |
| `--color-border` | `rgba(255,255,255,0.06)` | `Color(0x0FFFFFFF)` |
| `--color-ring` | `#1634ef` | `Color(0xFF1634EF)` |

---

## Tag Palette

### Light

| Token | Value | Flutter `Color` |
|---|---|---|
| `--color-tag-cobalt-bg` | `lch(92 30 265)` | `Color(0xFFD8E6FF)` (approx) |
| `--color-tag-turquoise-bg` | `lch(92 25 200)` | `Color(0xFFD6F3F7)` (approx) |
| `--color-tag-emerald-bg` | `lch(92 28 145)` | `Color(0xFFE3F5D6)` (approx) |
| `--color-tag-amethyst-bg` | `lch(92 30 310)` | `Color(0xFFF2E3FF)` (approx) |
| `--color-tag-fuchsia-bg` | `lch(92 30 345)` | `Color(0xFFFFE3F5)` (approx) |
| `--color-tag-sienna-bg` | `lch(92 30 40)` | `Color(0xFFFFEBD8)` (approx) |
| `--color-tag-ochre-bg` | `lch(92 28 75)` | `Color(0xFFFFF4D6)` (approx) |

### Dark

| Token | Value | Flutter `Color` |
|---|---|---|
| `--color-tag-cobalt-bg` | `lch(20 35 265)` | `Color(0xFF0D1A4D)` (approx) |
| `--color-tag-turquoise-bg` | `lch(20 30 200)` | `Color(0xFF0D3338)` (approx) |
| `--color-tag-emerald-bg` | `lch(20 30 145)` | `Color(0xFF0D2E1C)` (approx) |
| `--color-tag-amethyst-bg` | `lch(20 35 310)` | `Color(0xFF2A1240)` (approx) |
| `--color-tag-fuchsia-bg` | `lch(20 35 345)` | `Color(0xFF3B0F2A)` (approx) |
| `--color-tag-sienna-bg` | `lch(20 35 40)` | `Color(0xFF3B1808)` (approx) |
| `--color-tag-ochre-bg` | `lch(20 30 75)` | `Color(0xFF332600)` (approx) |

---

## Runtime YouTrade Theme Tokens (from HTML `tokens()`)

The mockup computes these at runtime based on `theme` and `dir`. These are the values used by the actual screens.

### Dark + Flux (default)

| Token | Value | Flutter `Color` |
|---|---|---|
| `bg` | `#06080f` | `Color(0xFF06080F)` |
| `bg2` | `#0a0e18` | `Color(0xFF0A0E18)` |
| `card` | `#0e131f` | `Color(0xFF0E131F)` |
| `chip` | `#10151f` | `Color(0xFF10151F)` |
| `navbg` | `#080b12` | `Color(0xFF080B12)` |
| `line` | `rgba(255,255,255,0.07)` | `Color(0x12FFFFFF)` |
| `line2` | `rgba(255,255,255,0.13)` | `Color(0x21FFFFFF)` |
| `fg` | `#f2f5fa` | `Color(0xFFF2F5FA)` |
| `fg2` | `rgba(255,255,255,0.55)` | `Color(0x8CFFFFFF)` |
| `fg3` | `rgba(255,255,255,0.34)` | `Color(0x57FFFFFF)` |
| `accent` | `#00e6d2` | `Color(0xFF00E6D2)` |
| `glow` | `rgba(0,230,210,0.5)` | `Color(0x8000E6D2)` |
| `up` | `#2ee6a6` | `Color(0xFF2EE6A6)` |
| `down` | `#ff5d77` | `Color(0xFFFF5D77)` |
| `grid` | `rgba(255,255,255,0.045)` | `Color(0x0BFFFFFF)` |

### Dark + Carbon

| Token | Value | Flutter `Color` |
|---|---|---|
| `accent` | `#3f73ff` | `Color(0xFF3F73FF)` |
| `glow` | `transparent` | `Colors.transparent` |
| `up` | `#16d196` | `Color(0xFF16D196)` |
| `down` | `#ff4d63` | `Color(0xFFFF4D63)` |
| All other dark tokens | same as Flux | same as Flux |

### Light + Flux

| Token | Value | Flutter `Color` |
|---|---|---|
| `bg` | `#f1efee` | `Color(0xFFF1EFEE)` |
| `bg2` | `#fbfafa` | `Color(0xFFFBFAFA)` |
| `card` | `#ffffff` | `Color(0xFFFFFFFF)` |
| `chip` | `#ffffff` | `Color(0xFFFFFFFF)` |
| `navbg` | `#ffffff` | `Color(0xFFFFFFFF)` |
| `line` | `rgba(2,13,35,0.09)` | `Color(0x17020D23)` |
| `line2` | `rgba(2,13,35,0.16)` | `Color(0x29020D23)` |
| `fg` | `#020d23` | `Color(0xFF020D23)` |
| `fg2` | `rgba(2,13,35,0.6)` | `Color(0x99020D23)` |
| `fg3` | `rgba(2,13,35,0.38)` | `Color(0x61020D23)` |
| `accent` | `#0094a8` | `Color(0xFF0094A8)` |
| `glow` | `rgba(0,148,168,0.35)` | `Color(0x590094A8)` |
| `up` | `#00936b` | `Color(0xFF00936B)` |
| `down` | `#d22a47` | `Color(0xFFD22A47)` |
| `grid` | `rgba(2,13,35,0.06)` | `Color(0x0F020D23)` |

### Light + Carbon

| Token | Value | Flutter `Color` |
|---|---|---|
| `accent` | `#1634ef` | `Color(0xFF1634EF)` |
| `glow` | `transparent` | `Colors.transparent` |
| `up` | `#1d683f` | `Color(0xFF1D683F)` |
| `down` | `#c0392b` | `Color(0xFFC0392B)` |
| All other light tokens | same as Flux | same as Flux |

---

## Shadows

| CSS Token | Value | Flutter `BoxShadow` |
|---|---|---|
| `--shadow-minimal` | `0 1px 2px rgba(2,13,35,0.07)` | `BoxShadow(color: Color(0x12020D23), blurRadius: 2, offset: Offset(0, 1))` |
| `--shadow-subtle` | `0 0 8px rgba(2,13,35,0.08), 0 0 20px rgba(2,13,35,0.02)` | two `BoxShadow` |
| `--shadow-medium` | `0 11px 32px rgba(0,0,0,0.12)` | `BoxShadow(color: Color(0x1F000000), blurRadius: 32, offset: Offset(0, 11))` |
| `--shadow-standard` | `0 0 20px -6px rgba(2,13,35,0.24), 0 0 0 1px rgba(2,13,35,0.06)` | two `BoxShadow` |
| `--shadow-heavy` | `0 0 0 1px rgba(2,13,35,0.06), 0 16px 60px -30px rgba(2,13,35,0.24), 0 50px 100px -20px rgba(2,13,35,0.25)` | three `BoxShadow` |
| `--shadow-glow` | `0 0 0 4px rgba(255,255,255,0.5), 0 4px 100px rgba(0,0,0,0.1)` | two `BoxShadow` |
| `--shadow-nav` | `0 1px 0 rgba(2,13,35,0.08)` | `BoxShadow(color: Color(0x14020D23), blurRadius: 0, offset: Offset(0, 1))` |

Device chrome shadow in the mockup:

```css
box-shadow: 0 40px 90px -20px rgba(0,0,0,.7), 0 0 0 1px rgba(255,255,255,.05);
```

This is only for the preview wrapper and is **not** part of app UI.

---

## Radii

| CSS Token | Value | Flutter Equivalent |
|---|---|---|
| `--radius-none` | `0px` | `BorderRadius.zero` |
| `--radius-sm` | `4px` | `BorderRadius.circular(4)` |
| `--radius-md` | `8px` | `BorderRadius.circular(8)` |
| `--radius-lg` | `8px` | `BorderRadius.circular(8)` |
| `--radius-full` | `0px` | `BorderRadius.zero` (intentionally sharp) |

Mockup-specific radii (inline styles):

| Element | Radius | Notes |
|---|---|---|
| Device outer frame | `44px` | preview wrapper only |
| Device inner frame | `34px` | preview wrapper only |
| Status bar notch | `16px` | preview wrapper only |
| App logo | `8px` | `BorderRadius.circular(8)` |
| Header icon buttons | `9px` | `BorderRadius.circular(9)` |
| Equity curve card | `10px` | `BorderRadius.circular(10)` |
| Range buttons | `5px` | `BorderRadius.circular(5)` |
| Exchange cards | `11px` | `BorderRadius.circular(11)` |
| Exchange avatar | `9px` | `BorderRadius.circular(9)` |
| Position avatar | `8px` | `BorderRadius.circular(8)` |
| Side badge | `3px` | `BorderRadius.circular(3)` |
| Symbol chips | `7px` | `BorderRadius.circular(7)` |
| Class tag | `3px` | `BorderRadius.circular(3)` |
| Stat strip cells | `8px` via overflow | `BorderRadius.circular(8)` |
| Candle chart card | `10px` | `BorderRadius.circular(10)` |
| Timeframe buttons | `5px` | `BorderRadius.circular(5)` |
| Trade ticket buttons | `7px` / `6px` | `BorderRadius.circular(7)` / `BorderRadius.circular(6)` |
| Submit CTA | `8px` | `BorderRadius.circular(8)` |
| Search bar | `8px` | `BorderRadius.circular(8)` |
| Market filter chips | `7px` | `BorderRadius.circular(7)` |
| Market list | `11px` | `BorderRadius.circular(11)` |
| Market row avatar | `8px` | `BorderRadius.circular(8)` |
| Balance / P&L cards | `10px` | `BorderRadius.circular(10)` |
| Asset glyph | `8px` | `BorderRadius.circular(8)` |
| Options grid | `10px` | `BorderRadius.circular(10)` |
| Compare chart card | `10px` | `BorderRadius.circular(10)` |
| Orders cards / list | `10px` / `11px` | `BorderRadius.circular(10)` / `BorderRadius.circular(11)` |
| Settings list | `11px` | `BorderRadius.circular(11)` |
| Bottom nav | `9px` touch targets | `BorderRadius.circular(9)` for hit area |

---

## Transitions

| CSS Token | Value | Flutter Equivalent |
|---|---|---|
| `--transition-fast` | `0.15s ease` | `Duration(milliseconds: 150)` + `Curves.ease` |
| `--transition-base` | `0.25s ease` | `Duration(milliseconds: 250)` + `Curves.ease` |
| `--transition-medium` | `0.35s ease` | `Duration(milliseconds: 350)` + `Curves.ease` |
| `--transition-slow` | `0.55s cubic-bezier(0.165, 0.84, 0.44, 1)` | `Duration(milliseconds: 550)` + `Cubic(0.165, 0.84, 0.44, 1)` |

---

## Spacing

All values are in logical pixels. The mockup viewport is 390×844 CSS pixels.

| Context | Value | Flutter Equivalent |
|---|---|---|
| Screen horizontal padding | `16px` | `EdgeInsets.symmetric(horizontal: 16)` |
| Screen bottom padding | `20px` / `24px` | `EdgeInsets.only(bottom: 20)` |
| Section gap | `14px`–`20px` | `SizedBox(height: 14)` etc. |
| Card internal padding | `12px`–`14px` | `EdgeInsets.all(12)` / `EdgeInsets.all(14)` |
| List row gap | `9px`–`11px` | `SizedBox(height: 9)` / `SizedBox(height: 11)` |
| Chip gap | `6px` | `SizedBox(width: 6)` |
| App header padding | `6px 18px 12px` | `EdgeInsets.fromLTRB(18, 6, 18, 12)` |
| Status bar height | `46px` | `SizedBox(height: 46)` |
| Bottom nav height | `74px` (incl. safe area padding) | `SizedBox(height: 74)` |
| Bottom nav item padding | `5px 10px` | `EdgeInsets.symmetric(horizontal: 10, vertical: 5)` |
| Icon sizes | `13px`–`22px` | `Icon(size: 13)` … `Icon(size: 22)` |
| Avatar sizes | `30px`–`42px` | `Container(width: 30, height: 30)` etc. |

---

## Iconography

All icons in the mockup are inline SVG paths. They map to Material/Cupertino or custom SVG assets:

| Icon | Source |
|---|---|
| App logo (checkmark) | inline SVG in HTML |
| Theme moon | inline SVG |
| Signal bars / WiFi / Battery | inline SVG (status bar) |
| Search magnifier | inline SVG |
| Compare chart | inline SVG |
| Bottom nav icons (home, markets, trade, options, more) | inline SVG paths in `icon()` method |
| Side badges | text glyph + colored background |

For Flutter, prefer `flutter_svg` for exact path parity or Material icons if already installed. The project currently uses `cupertino_icons` and Material design icons (`uses-material-design: true`). If exact SVG replication is required, add `flutter_svg`.

---

## Notes

- **LCH/Lab approximations:** CSS `lch()` and `lab()` values are approximated to the nearest sRGB hex because Flutter’s `Color` class is sRGB-based. Exact LCH rendering would require a color space extension.
- **Computed tokens:** `accent`, `glow`, `up`, `down`, `fg`, `bg`, etc. are computed by the mockup’s `tokens()` method. They are direction- and theme-dependent and must be resolved at runtime, not hardcoded as a single value.
- **No pills:** The OpenTreasury system explicitly sets `--radius-full: 0px`; the mockup uses small rounded rectangles for chips and pills do not exist.
