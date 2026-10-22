#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Changes what the palette popover (fnc_openPaletteMenu) sets - the one place that does - and shows it: the popover is
 * updated in place at once (fnc_updatePaletteMenu), and the window is built again for the new colours, every colour of it
 * coming from the theme (fnc_theme): fnc_buildSoon, which does the first build of a run of moves at once and the rest
 * once per rest, so a slider dragged across the track is seen live without a build for every pixel. The popover is made
 * again by the build (fnc_build), so the drag goes on. Kept in the profile when the popover closes (fnc_paletteSettle).
 *
 * A colour is a hue and a vividness (fnc_hsv); the slider of one that is still the profile's or the accent's own starts from
 * what the window wears now (fnc_paletteInfo), so the first move changes only that. Nothing happens when the value is what
 * the player had chosen already.
 *
 * Modes:
 *   "slider" - [index, place]: slider 0 the accent's hue, 1 its vividness, 2 the secondary colour's hue, 3 its vividness,
 *              4 the transparency; place 0 to 1 along the track (for the transparency 0 is opaque, 1 as see-through as
 *              PALETTE_ALPHA_MIN allows)
 *   "reset"  - "accent" (back to the Arma profile's colour), "secondary" (follows the accent again), "alpha" (the themes'
 *              own) or "all"
 *
 * Arguments:
 * 0: Mode <STRING>
 * 1: Argument <ANY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["slider", [0, 0.5]] call einv_gui_fnc_paletteSet;
 *
 * Public: No
 */

params [["_mode", "", [""]], ["_argument", 0]];

// The array is changed in place: it is the one fnc_palette hands a copy of.
private _palette = GVAR(palette);
private _changed = false;

switch (_mode) do {
    case "slider": {
        _argument params [["_index", -1, [0]], ["_place", 0, [0]]];

        if (_index < 0 || {_index > 4}) exitWith {};

        _place = (_place max 0) min 1;

        if (_index == 4) then {
            private _alpha = 1 - (round (_place * (1 - PALETTE_ALPHA_MIN) / PALETTE_ALPHA_STEP)) * PALETTE_ALPHA_STEP;

            // Two decimals: the sum above leaves dust.
            _alpha = (round (_alpha * 100)) / 100;

            if ((_palette select 2) isEqualTo _alpha) exitWith {};

            _palette set [2, _alpha];
            _changed = true;
        } else {
            // Which colour, and which of its two sliders.
            private _which = floor (_index / 2);
            private _part = _index mod 2;
            private _info = [] call FUNC(paletteInfo);
            private _hs = +(_info get (["accentHs", "secondaryHs"] select _which));
            private _chosen = _info get (["accentSet", "secondarySet"] select _which);
            private _steps = [PALETTE_HUE_STEPS, PALETTE_VIVID_STEPS] select _part;
            private _value = (round (_place * _steps)) / _steps;

            if (_chosen && {(_hs select _part) isEqualTo _value}) exitWith {};

            _hs set [_part, _value];
            _palette set [_which, _hs];
            _changed = true;
        };
    };

    case "reset": {
        private _was = +_palette;

        switch (_argument) do {
            case "accent": {_palette set [0, []]};
            case "secondary": {_palette set [1, []]};
            case "alpha": {_palette set [2, -1]};
            case "all": {
                _palette set [0, []];
                _palette set [1, []];
                _palette set [2, -1];
            };
        };

        _changed = _was isNotEqualTo _palette;
    };
};

if (!_changed) exitWith {};

GVAR(paletteDirty) = true;

[] call FUNC(updatePaletteMenu);

// A press on a slider is the event of a control that the build deletes, so the build waits for the next frame.
[{[] call FUNC(buildSoon)}] call FUNC(later);
