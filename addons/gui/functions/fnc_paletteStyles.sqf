#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The styles of the palette popover's dropdown (fnc_openPaletteMenu): ready-made palettes a player starts from. Picking one
 * sets every row as the style says (fnc_paletteSet "style"); a row changed afterwards makes it "Custom" again, and the style
 * stays where it was as a starting point. Classic is the window's own look - nothing chosen.
 *
 * Each palette is as PALETTE_UNSET: colours as [hue, saturation, value] 0 to 1, transparencies 0 to 1, -1 or [] for the look's
 * own. The panels, the cells and the tiles stay below PALETTE_PANEL_VALUE_MAX, so the text stays readable on them. A style of
 * all 19 places also says where the titles' gradient shows (GRADIENT_*) and which parts run in colours of their own ([part, start,
 * end], fnc_paletteSet "style"): where it suits the look - a read-out's amber, a night-vision green - not in every style.
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
    // The window as it ships (PALETTE_DEFAULT): the player's own Arma colour on the plain films, the titles, the headings, the name at
    // the mouse and the weight bar running from it into white.
    ["classic", LLSTRING(Style_Classic), PALETTE_DEFAULT],

    // Arma 3's own menus - near-black glass, white text, an amber highlight; the titles and the weight bar into a pale amber.
    ["arma", LLSTRING(Style_Arma), [
        [0.11, 0.85, 0.95], [0, 0, 0.75], 0.9, [0, 0, 0.07], [0, 0, 0.13], [], [], [0, 0, 0.4], -1, 1, [0.12, 0.3, 1], "",
        [], [], -1, -1, -1, 262151, []
    ]],

    // Apex: Tanoa's jungle, a deep teal with a jade highlight - its titles and a few parts running into a lighter jade.
    ["apex", LLSTRING(Style_Apex), [
        [0.45, 0.7, 0.85], [0.42, 0.35, 0.75], 0.92, [0.47, 0.55, 0.07],
        [0.47, 0.4, 0.12], [], [], [0.45, 0.45, 0.6], -1, 1, [0.3, 0.6, 0.95], "",
        [], [], -1, -1, -1, 135775, [[17, [0.42, 0.6, 0.9], [0.3, 0.15, 1]], [9, [0.45, 0.7, 0.85], [0.3, 0.3, 1]]]
    ]],

    // Contact: Livonia's cold forest, blue-grey with an icy highlight; the titles and the name at the mouse frosting over.
    ["contact", LLSTRING(Style_Contact), [
        [0.55, 0.4, 1], [0.58, 0.15, 0.8], 0.92, [0.6, 0.3, 0.07],
        [0.6, 0.22, 0.12], [], [], [0.56, 0.3, 0.65], -1, 1, [0.52, 0.12, 1], "",
        [], [], -1, -1, -1, 4103, []
    ]],

    // Tanks: desert dust and steel; the titles and the weight bar bleaching into sand.
    ["tanks", LLSTRING(Style_Tanks), [
        [0.09, 0.6, 0.85], [0.08, 0.25, 0.75], 0.93, [0.08, 0.35, 0.07],
        [0.08, 0.25, 0.12], [], [], [0.08, 0.35, 0.6], -1, 1, [0.11, 0.25, 1], "",
        [], [], -1, -1, -1, 262151, []
    ]],

    // Jets: a cockpit at night, steel blue with an amber read-out; the titles, the bars and the header lines from amber into steel.
    ["jets", LLSTRING(Style_Jets), [
        [0.13, 0.8, 1], [0.6, 0.25, 0.8], 0.92, [0.6, 0.35, 0.06],
        [0.6, 0.25, 0.11], [], [], [0.6, 0.35, 0.55], -1, 1, [0.58, 0.45, 1], "",
        [], [], -1, -1, -1, 1310727, []
    ]],

    // Laws of War: charcoal, and red as the only colour.
    ["lawsOfWar", LLSTRING(Style_LawsOfWar), [
        [0, 0.78, 0.88], [0, 0, 0.7], 0.95, [0, 0, 0.06],
        [0, 0, 0.11], [], [], [0, 0.4, 0.55], -1, 1, [], ""
    ]],

    // Olive and sand, as gear and maps are - dark; the titles into sand.
    ["tactical", LLSTRING(Style_Tactical), [
        [0.12, 0.5, 0.85], [0.18, 0.3, 0.7], 0.94, [0.19, 0.4, 0.07],
        [0.19, 0.3, 0.12], [], [0.14, 0.12, 1], [0.16, 0.35, 0.55], -1, 1, [0.14, 0.25, 0.95], "",
        [], [], -1, -1, -1, 7, []
    ]],

    // Night vision: black, its green the only light; the titles and the name at the mouse glowing brighter.
    ["stealth", LLSTRING(Style_Stealth), [
        [0.33, 0.75, 0.85], [0.33, 0.35, 0.6], 0.96, [0.33, 0.3, 0.04],
        [0.33, 0.25, 0.09], [], [], [0.33, 0.5, 0.45], -1, 1, [0.33, 0.3, 1], "",
        [], [], -1, -1, -1, 4103, []
    ]],

    // Dark blue glass.
    ["modern", LLSTRING(Style_Modern), [
        [0.6, 0.7, 1], [0.6, 0.3, 0.9], 0.9, [0.63, 0.45, 0.08],
        [0.63, 0.35, 0.13], [], [], [0.6, 0.45, 0.65], -1, 1, [], ""
    ]],

    // The same, its titles running from blue into violet - the titles only.
    ["modernGradient", LLSTRING(Style_ModernGradient), [
        [0.6, 0.7, 1], [0.7, 0.3, 0.9], 0.9, [0.67, 0.45, 0.08],
        [0.67, 0.35, 0.13], [], [], [0.7, 0.45, 0.65], -1, 1, [0.8, 0.6, 1], ""
    ]]
]
