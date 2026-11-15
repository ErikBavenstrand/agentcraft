# UI rules: build like Blizzard

These rules come from reading Blizzard's own Forever UI code (github.com/Gethe/wow-ui-source, branch `forever`, fetched 2026-11-15).
They beat dev/ui-spec-v2.md wherever the two disagree. `dev.ps1 lint-ui` checks the ones marked [lint].

The offline renderer (dev/render) is only a rough preview. It does not model scale, pixel snapping, real atlas sizes, fonts or animation playback.
The ground truth is an in-game capture (`/ac capture`, see dev/README.md).

## Motion

1. [lint] Never slide, bump, squish or scale a window, page, panel, popup, toast or row.
   Blizzard panels (CharacterFrame, SettingsPanel, PlayerSpellsFrame) have no AnimationGroup at all.
   UIParentPanelManager "slides" panels by re-anchoring them instantly.
   No `Translation` animations anywhere; no `Scale` animations on frames that hold content.
2. Windows, pages, tabs and popups show and hide instantly, with a sound:
   `IG_CHARACTER_INFO_OPEN` / `_CLOSE` on open and close, `IG_CHARACTER_INFO_TAB` on tab change.
3. Animation is allowed only on small highlight art:
   an Alpha pulse of a glow texture (Blizzard's tab glow: 0.9 s, looping), or a focus or cursor intro of at most 0.25 s (alpha 0 to 1, scale 1.5 to 1 on the icon only).
   [lint] Any Alpha or Scale animation longer than 1 s that is not on a glow or highlight child is a warning.
4. Nothing moves or pulses without a reason. Idle drift, cascades and attention pulses on whole rows are not used.

## Crisp pixels

5. Call `SetRoundLayoutToNearestPixel(true)` on the window root, recursively where the client supports it (`PixelUtil.SetRoundLayoutToNearestPixelRecursively`).
   On the Steam Deck (800 px tall) one physical pixel is 0.96 UI units, so whole-number offsets land on half pixels without it.
   [lint] Do not use the deprecated `PixelUtil.SetSize` / `PixelUtil.SetPoint`.
6. [lint] Do not call `SetSnapToPixelGrid(false)` or `SetTexelSnappingBias(0)` on static art. Blizzard does that only for scaled or animated textures.
7. Use `SetAtlas(name, true)` (atlas size) unless the frame really needs another size.
   [lint] Never call `SetTexCoord` on a texture that uses an atlas.
8. Borders come from Blizzard templates or NineSliceUtil layouts. Do not stretch edge textures by hand or set `SetHorizTile` / `SetVertTile` yourself.
   Tiling comes from the atlas info. Forever has per-atlas offset overrides for the Classic metal frames that hand-built borders miss.
9. Never tint stock bronze, metal or parchment art.

## No flicker

10. [lint] Do not create frames, textures or font strings inside Refresh / Update / OnUpdate / OnEvent code unless pooled or guarded (create once, then toggle).
11. [lint] Do not call `SetAtlas`, `SetTexture`, `SetPoint`, `ClearAllPoints` or `Show`/`Hide` churn from OnUpdate. Do it when state changes.
12. A refresh only changes what changed. Do not hide everything and show it again, and do not set alpha to 0 and back.
13. [lint] `ScrollBox:SetDataProvider(p)` without `ScrollBoxConstants.RetainScrollPosition` resets scroll to the top and rebuilds every row. Mutate the existing provider, or pass Retain.
14. Highlight and focus art is created once per button and toggled. Blizzard's gamepad focus FX are made on demand once (ActionBarFocusFX.lua).
15. Do not fight over frame levels or strata. Set them once at build time.

## Templates and controller

16. Prefer stock templates that exist in Forever: ButtonFrameTemplate / PortraitFrameTemplate, UIPanelButtonTemplate, MinimalTabTemplate, WowScrollBoxList + MinimalScrollBar, Settings control templates.
17. Gamepad focus is a pre-made highlight texture toggled on focus change, using `gamepad-*` atlases.
18. Button prompts use Blizzard's glyph lookup (InputIconTextureFrameTemplate / input icon utils), not hard-coded glyph texture paths. Space stacked glyphs 4 px apart.

## Readability and hover (owner feedback, 2026-11-15)

19. The Inspector uses the same dark pane on every page; no parchment under it. UI.C colours (gold, red, orange, grey, green) are for dark backgrounds.
    Text drawn straight on light parchment uses dark ink (`UI.Ink(fs)`, `UI.C.INK` / `UI.C.INK_DIM`), as Blizzard's parchment UIs do.
20. [lint R12] Every HIGHLIGHT-layer texture is additive (`SetBlendMode("ADD")`). HIGHLIGHT draws above icon and text, so opaque hover art blanks the widget.
21. [lint R13] Hover shows only the highlight and the tooltip. It never moves the focus and never changes the Inspector; a click (or a key/pad move) does.
    The page tabs never touch the Inspector at all (`acNoInspect`).

## Sources

- Blizzard_UIPanels_Game/Camelot/CharacterFrame.lua and .xml (open/close sounds, no animations)
- Blizzard_Settings_Shared/Blizzard_SettingsPanel.xml and .lua
- Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua (MoveUIPanel re-anchors)
- Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml (TabGlowAnimation, the only AnimationGroup)
- Blizzard_GamepadSoftCursor/SoftCursor.xml, Blizzard_GamepadSmartNavigation/SmartNavigation.xml
- Blizzard_GamepadActionBars/ActionBarFocusFX.lua, Blizzard_GamepadSharedUtility/FrameControlsManager.lua, InputPrompts/InputPrompts.xml
- Blizzard_SharedXML/PixelUtil.lua, NineSlice.lua, Shared/Scroll/ScrollBox.lua
