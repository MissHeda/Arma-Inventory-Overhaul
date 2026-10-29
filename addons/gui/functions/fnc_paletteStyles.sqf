#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The styles of the palette popover's dropdown (fnc_openPaletteMenu): ready-made palettes a player starts from. Picking one
 * sets every row as the style says (fnc_paletteSet "style"); a row changed afterwards makes it "Custom" again, and the style
 * stays where it was as a starting point. Classic is the window's own look - nothing chosen.
 *
 * Each palette is as PALETTE_UNSET: colours as [hue, saturation, value] 0 to 1, transparencies 0 to 1, -1 or [] for the look's
 * own. The panels, the cells and the tiles stay below PALETTE_PANEL_VALUE_MAX, so the text stays readable on them.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The styles, [id, name, palette] each, in the dropdown's order <ARRAY>
 *
 * Example:
 * [] call einv_gui_fnc_paletteStyles;
 *
 * Public: No
 */

[
    // The window as it ships.
    ["classic", LLSTRING(Style_Classic), PALETTE_UNSET],

    // Cool blue glass: lighter, more see-through panels, blue lines.
    ["modern", LLSTRING(Style_Modern), [
        [0.6, 0.72, 1], [0.6, 0.35, 1], 0.86, [0.62, 0.45, 0.13],
        [0.62, 0.35, 0.17], [], [], [0.6, 0.45, 1], -1, 0.9, [], ""
    ]],

    // The same, its accent texts running from blue into violet.
    ["modernGradient", LLSTRING(Style_ModernGradient), [
        [0.6, 0.72, 1], [0.7, 0.35, 1], 0.86, [0.66, 0.45, 0.13],
        [0.66, 0.35, 0.17], [], [], [0.7, 0.45, 1], -1, 0.9, [0.79, 0.62, 1], ""
    ]],

    // Olive and sand, as gear and maps are.
    ["tactical", LLSTRING(Style_Tactical), [
        [0.11, 0.55, 0.88], [0.17, 0.3, 0.75], 0.94, [0.19, 0.4, 0.12],
        [0.18, 0.3, 0.17], [], [0.14, 0.12, 1], [0.15, 0.35, 0.75], -1, -1, [], ""
    ]],

    // True black, no glass: for dark rooms and OLED screens.
    ["night", LLSTRING(Style_Night), [
        [0.58, 0.3, 0.9], [0, 0, 0.55], 1, [0, 0, 0],
        [0, 0, 0.07], [], [0, 0, 0.88], [0, 0, 0.3], -1, 1, [], ""
    ]],

    // Pink into cyan on a deep violet.
    ["neon", LLSTRING(Style_Neon), [
        [0.9, 0.75, 1], [0.5, 0.75, 1], 0.9, [0.76, 0.6, 0.1],
        [0.76, 0.5, 0.14], [], [], [0.5, 0.75, 1], -1, 0.92, [0.5, 0.85, 1], ""
    ]]
]
