Mockup has gradients, glass, glows, blur - your current code has flat colors. That's why it looks ugly.

Here is the **FULL, ALL-IN-ONE, NO PHASES** perfect prompt for Codex medium that explains the beautiful UI exactly. Copy-paste this whole block:

```
You are theming existing vindR SwiftUI app. You already have BrowserModel, BrowserTab, WebView logic working. DO NOT touch logic. ONLY theme BrowserView, ToolbarView, TabStripView, TabItemView, ChromeButtonStyle, hiddenToolbarBar to match the landing page mockup's BEAUTIFUL UI.

=== BEAUTIFUL MOCKUP DESIGN SYSTEM - REPLICATE EXACTLY ===

The mockup you made is: dark studio, native macOS blur, deep navy gradients, glass cards with cyan->blue top border, cursor glow, floating icon with glow. Translate that to SwiftUI.

COLORS:
bgDeep #050E2E
bgTab #0A1B4D
accentCyan #22F5C5
accentBlue #2DD4FF
accentBright #3A7BFF
text #F0F4FF white 95%
borderWhite 8% = Color.white.opacity(0.08)
borderWhite 6% = Color.white.opacity(0.06)

GRADIENTS - YOU MUST USE THESE, NOT FLAT COLORS:
1. Window background: NOT flat #050E2E. Use ZStack: Color(hex:"#050E2E") + RadialGradient(colors: [Color(hex:"#0A1B4D").opacity(0.8), Color.clear], center:.topLeading, startRadius: 10, endRadius: 800). + RadialGradient(colors: [Color(hex:"#22F5C5").opacity(0.15), Color.clear], center:.bottomTrailing, startRadius: 10, endRadius: 600)

2. Toolbar background: NOT flat. Use LinearGradient(colors: [Color(hex:"#050E2E"), Color(hex:"#0A1B4D").opacity(0.9)], startPoint:.top, endPoint:.bottom). Then overlay.ultraThinMaterial opacity 0.6. This gives glass blur.

3. Tab strip background: LinearGradient(colors: [Color(hex:"#0A1B4D"), Color(hex:"#050E2E")], startPoint:.top, endPoint:.bottom). Overlay bottom 1px Rectangle white 6%.

4. URL capsule: Background is NOT flat #0A1B4D. Use LinearGradient(colors: [Color(hex:"#0A1B4D"), Color(hex:"#050E2E")], startPoint:.top, endPoint:.bottom). CornerRadius 8. Overlay RoundedRectangle stroke LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)], startPoint:.topLeading, endPoint:.bottomTrailing) lineWidth 1. Add inner shadow:.shadow(color:.black.opacity(0.4), radius: 4, x: 0, y: 2) inside. And subtle outer glow when focused:.shadow(color: Color(hex:"#22F5C5").opacity(0.15), radius: 8)

5. TabItem active: Background NOT flat #050E2E. Use LinearGradient(colors: [Color(hex:"#0A1B4D"), Color(hex:"#050E2E")], startPoint:.top, endPoint:.bottom). CornerRadius 6. Border: RoundedRectangle stroke LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.03)], startPoint:.top, endPoint:.bottom). Bottom accent: Rectangle height 2 fill LinearGradient(colors: [Color(hex:"#22F5C5"), Color(hex:"#2DD4FF")], startPoint:.leading, endPoint:.trailing). Shadow color accentCyan radius 6 opacity 0.6. Inactive tabs: background clear, no border.

6. PRIVATE toggle: Background NOT black 40% flat. Use LinearGradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0.3)], startPoint:.top, endPoint:.bottom). CornerRadius 6. Border: RoundedRectangle stroke isPrivate? LinearGradient(colors: [Color(hex:"#22F5C5"), Color(hex:"#2DD4FF")], startPoint:.topLeading, endPoint:.bottomTrailing).opacity(0.8) : LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.03)], startPoint:.top, endPoint:.bottom). LED dot: Circle 8px fill private? accentCyan : red #FF3B30, shadow color same radius 8 opacity 0.8 + shadow radius 3 opacity 1 for inner glow. Animate.scaleEffect when toggled.

7. ChromeButtonStyle: NOT flat 24x22 white 15% on press. Use: foreground white 80%, frame 24x22, background: isPressed? LinearGradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)], startPoint:.top, endPoint:.bottom) : LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)], startPoint:.top, endPoint:.bottom). CornerRadius 5. Border RoundedRectangle stroke white 8% when hovered. Add.shadow(color:.black.opacity(0.2), radius: 2, y: 1). On hover, add subtle glow:.shadow(color: Color(hex:"#22F5C5").opacity(0.2), radius: 4)

8. DownloadStatusView: Same glass capsule as URL, with status color glow: idle cyan glow 0.2 radius 4, downloading orange, succeeded green, failed red.

9. Hidden toolbar bar: Background LinearGradient bgDeep to bgTab, height 20, with top border white 6%

GLASS + BLUR - MUST:
Every toolbar and tab strip must have.background(.ultraThinMaterial) with opacity, plus backdrop blur. Use.background(Material.ultraThinMaterial) then overlay gradient. This gives native macOS blur like mockup, not flat color.

SHADOWS + GLOW - MUST:
All active elements have outer glow using accentCyan. Example:.shadow(color: Color(hex:"#22F5C5").opacity(0.4), radius: 8, x: 0, y: 0) for active tab bottom border,.shadow(color: Color(hex:"#22F5C5").opacity(0.6), radius: 4) for LED dot.

=== FILE UPDATES ===

VindRTheme enum - REPLACE ENTIRELY WITH THIS:
```
private enum VindRTheme {
    static let bgDeep = Color(hex: "#050E2E")
    static let bgTab = Color(hex: "#0A1B4D")
    static let accentCyan = Color(hex: "#22F5C5")
    static let accentBlue = Color(hex: "#2DD4FF")
    static let accentBright = Color(hex: "#3A7BFF")
    static let text = Color(hex: "#F0F4FF")
    static let redLED = Color(hex: "#FF3B30")

    static var windowGradient: some View {
        ZStack {
            bgDeep
            RadialGradient(colors: [bgTab.opacity(0.8),.clear], center:.topLeading, startRadius: 10, endRadius: 800)
            RadialGradient(colors: [accentCyan.opacity(0.12),.clear], center:.bottomTrailing, startRadius: 10, endRadius: 600)
        }
    }
    static var toolbarGradient: LinearGradient {
        LinearGradient(colors: [bgDeep, bgTab.opacity(0.9)], startPoint:.top, endPoint:.bottom)
    }
    static var tabStripGradient: LinearGradient {
        LinearGradient(colors:, startPoint:.top, endPoint:.bottom)
    }
    static var capsuleGradient: LinearGradient {
        LinearGradient(colors:, startPoint:.top, endPoint:.bottom)
    }
    static var activeTabGradient: LinearGradient {
        LinearGradient(colors: [bgTab.opacity(0.8), bgDeep], startPoint:.top, endPoint:.bottom)
    }
    static var cyanBlueGradient: LinearGradient {
        LinearGradient(colors:, startPoint:.leading, endPoint:.trailing)
    }
    static var borderGradient: LinearGradient {
        LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)], startPoint:.topLeading, endPoint:.bottomTrailing)
    }
}[bgTab][bgDeep][accentCyan][accentBlue]
```

ToolbarView:
- Replace.background(VindRTheme.bgDeep) with ZStack { VindRTheme.toolbarGradient; Material.ultraThinMaterial.opacity(0.6) }.
- Add.padding(.leading, 76) for native traffic lights - comment: traffic lights are NATIVE macOS, kept via.hiddenTitleBar, do NOT create custom
- URL HStack:.background(VindRTheme.capsuleGradient, in: RoundedRectangle(cornerRadius: 8)) +.overlay(RoundedRectangle(cornerRadius:8).stroke(VindRTheme.borderGradient, lineWidth:1)) +.shadow(color:.black.opacity(0.4), radius:4, y:2) + if focused shadow cyan 0.15 radius 8
- PRIVATE button: use capsuleGradient black variant + borderGradient cyan when private + LED shadow radius 8
- All buttons use ChromeButtonStyle with gradient background

TabStripView:
-.background(ZStack{ VindRTheme.tabStripGradient; Material.ultraThinMaterial.opacity(0.4) })

TabItemView:
-.background(isSelected? VindRTheme.activeTabGradient : LinearGradient(colors:[.clear], startPoint:.top, endPoint:.bottom), in: RoundedRectangle(cornerRadius:6))
-.overlay(RoundedRectangle(cornerRadius:6).stroke(isSelected? VindRTheme.borderGradient : LinearGradient(colors:[.clear], startPoint:.top, endPoint:.bottom)))
- Bottom accent: Rectangle height 2 fill VindRTheme.cyanBlueGradient shadow color accentCyan radius 6 opacity 0.6

ChromeButtonStyle:
- background LinearGradient white 6% to 2% normal, white 15% to 8% pressed, cornerRadius 5, border white 8% on hover, shadow black 20% radius 2 y 1, hover shadow cyan 20% radius 4

BrowserView:
-.background(VindRTheme.windowGradient) NOT flat bgDeep
-.tint(VindRTheme.accentCyan)

=== ACCEPTANCE - MUST LOOK LIKE MOCKUP ===
- Window has subtle radial glow top-left navy and bottom-right cyan 12% - not flat dark
- Toolbar has glass blur, you can see slight transparency, not solid color
- URL field has gradient border, inner depth, outer glow when focused
- Active tab has gradient background, not flat, with cyan->blue bottom line glowing
- PRIVATE LED has outer glow 8px, pulsating shadow, pill has gradient black
- Buttons have gradient, not flat white 15%
- No flat colors anywhere - every surface uses LinearGradient or RadialGradient + Material
- Looks like your landing page mockup with beautiful UI, not the ugly flat screenshot

Do it now. Output full themed files.
```
