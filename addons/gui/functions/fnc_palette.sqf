#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the player chose in the palette (the header's palette button, fnc_openPaletteMenu), as the themes read it whenever
 * one is built (fnc_theme, fnc_accentColour): three overrides, each empty or unset where the player chose nothing.
 *
 *   accent     [] or [hue, vividness] - the accent colour in place of the Arma profile's colour (fnc_accentColour)
 *   secondary  [] or [hue, vividness] - the tint of the films on the panes and of the soft accent (fnc_theme)
 *   alpha      -1 or the panels' alpha, PALETTE_ALPHA_MIN to 1 (fnc_theme)
 *
 * Hue and vividness are 0 to 1 (fnc_hsv; vividness 0 is white, 1 the pure hue). Where the server switched the palette off
 * (fnc_paletteAllowed), all three come back unset, whatever the player has saved: the profile's accent, the themes' own films
 * and panels. The choices are kept in einv_gui_palette - read from the profile once in XEH_preInit, written back when the
 * palette closes (fnc_paletteSettle).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [accent, secondary, alpha] <ARRAY>
 *
 * Example:
 * ([] call einv_gui_fnc_palette) params ["_accent", "_secondary", "_alpha"];
 *
 * Public: No
 */

if !([] call FUNC(paletteAllowed)) exitWith {
    [[], [], -1]
};

+GVAR(palette)
