#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the player chose in the palette (the header's palette button, fnc_openPaletteMenu), as the themes read it whenever
 * one is built (fnc_theme, fnc_accentColour, fnc_panelColour): nine overrides, each empty or unset where the player chose nothing.
 *
 *   accent     [] or [hue, saturation, value] - the accent colour in place of the Arma profile's colour (fnc_accentColour)
 *   secondary  [] or [hue, saturation, value] - the tint of the caption tabs, buttons, bar tracks and of the soft accent (fnc_theme)
 *   alpha      -1 or the panels' alpha, PALETTE_ALPHA_MIN (0, fully see-through) to 1 (fnc_theme)
 *   panel      [] or [hue, saturation, value] - the colour of the panels, its value at most PALETTE_PANEL_VALUE_MAX (fnc_panelColour)
 *   cells      [] or [hue, saturation, value] - the empty grid cells and the slot boxes, value at most PALETTE_PANEL_VALUE_MAX (fnc_theme)
 *   tiles      [] or [hue, saturation, value] - the item tiles' background, value at most PALETTE_PANEL_VALUE_MAX (fnc_theme)
 *   text       [] or [hue, saturation, value] - the text and its dimmer shades (fnc_theme)
 *   lines      [] or [hue, saturation, value] - the tint of the hairlines and borders (fnc_theme)
 *   tileAlpha  -1 or the item tiles' alpha, PALETTE_ALPHA_MIN to 1 (fnc_theme); the last entry, so a palette saved with eight reads it unset
 *
 * Each number of a colour is 0 to 1 (fnc_hsv; saturation 0 is grey or white, value 0 black). Which theme key follows which entry is
 * the table at the top of fnc_theme. Where the server switched the palette off (fnc_paletteAllowed), all of them come back unset
 * (PALETTE_UNSET), whatever the player has saved: the profile's accent and the themes' own colours. The choices are kept in
 * einv_gui_palette - read from the profile once in XEH_preInit (a palette saved before the last four rows existed reads them as
 * unset, and so does one from before the tile transparency), written back when the palette closes (fnc_paletteSettle).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [accent, secondary, alpha, panel, cells, tiles, text, lines, tileAlpha] <ARRAY>
 *
 * Example:
 * ([] call einv_gui_fnc_palette) params ["_accent", "_secondary", "_alpha", "_panel", "_cells", "_tiles", "_text", "_lines", "_tileAlpha"];
 *
 * Public: No
 */

// The colours a server or mission forces (einv_gui_paletteText): everyone wears those.
if ([] call FUNC(paletteForced)) exitWith {
    private _forced = [parseSimpleArray (missionNamespace getVariable [QGVAR(paletteText), ""])] call FUNC(paletteRead);

    [_forced, +PALETTE_DEFAULT] select (_forced isEqualTo [])
};

if !([] call FUNC(paletteAllowed)) exitWith {
    +PALETTE_DEFAULT
};

+GVAR(palette)
