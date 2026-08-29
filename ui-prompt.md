THEME ONLY. Match target screenshot 2. Your current is flat dark, wrong.

Colors: #050E2E deep, #0A1B4D tab, #22F5C5 cyan, #2DD4FF blue, #FF3B30 red, white 6%/8%/12% borders.

Window: ZStack { #050E2E + RadialGradient(#0A1B4D 80% topLeading 800) + RadialGradient(#22F5C5 12% bottomTrailing 600) } not flat black.

Top bar: Custom HStack height 36, background = LinearGradient(#050E2E -> #0A1B4D 90%) + .ultraThinMaterial 0.6. NOT system toolbar. padding .leading 76 (native traffic lights). traffic lights native - .hiddenTitleBar keeps them.

Tab strip: height 32, background LinearGradient(#0A1B4D -> #050E2E) + ultraThinMaterial 0.4, bottom white 6% 1px.

Tab item: active = LinearGradient(#0A1B4D 80% -> #050E2E) + border LinearGradient(white 10% -> 3%) + bottom 2px LinearGradient(#22F5C5 -> #2DD4FF) + shadow #22F5C5 radius 6. Inactive clear. dot #2DD4FF 6px.

URL capsule: LinearGradient(#0A1B4D -> #050E2E) corner 8, border LinearGradient(white 12% -> 4% topLeading->bottomTrailing) 1px, shadow black 40% radius4 y2, focused glow #22F5C5 15% radius8.

PRIVATE pill: LinearGradient(black 60% -> 30%) corner6, border cyan->blue 80% when private else white 10%->3%, LED 8px + shadow 8 opacity .8 + pulse scale.

ChromeButton: background LinearGradient(white 6% ->2%) normal, 15%->8% pressed, corner5, border white 8% hover, shadow black 20% r2 y1, hover cyan 20% r4.

Cards (main content): background LinearGradient(#0A1B4D -> #050E2E) + ultraThinMaterial, border white 8%, shadow black 30% r6.

No new logic. Only replace Color.* flat with gradients above. Keep BrowserModel untouched.