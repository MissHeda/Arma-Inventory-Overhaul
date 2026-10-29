#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Changes what the palette popover (fnc_openPaletteMenu) sets - the one place that does - and shows it: the popover is
 * updated in place at once (fnc_updatePaletteMenu), and the window is built again for the new colours, every colour of it
 * coming from the theme (fnc_theme): fnc_buildSoon, which does the first build of a run of moves at once and the rest
 * once per rest, so a picker dragged across is seen live without a build for every pixel. The popover is made
 * again by the build (fnc_build), so the drag goes on. Kept in the profile when the popover closes (fnc_paletteSettle).
 *
 * A colour is a hue, a saturation and a value (fnc_hsv): the colour square gives the saturation (across) and the value (down),
 * the strip beside it the hue, the fields the red, green and blue 0 to 255 or the hex code. The picker of one that is still
 * the profile's, the accent's or the theme's own starts from what the window wears now (fnc_paletteInfo), so the first move changes
 * only that. Nothing happens when the value is what the player had chosen already. The surfaces under the text - the panels, the
 * cells and the tiles - are cut dark where they are chosen: their value is at most PALETTE_PANEL_VALUE_MAX (PALETTE_VALUE_MAX; the
 * square shows only that much of the value, fnc_openPaletteMenu), so a typed colour that is lighter comes back as the lightest they
 * have, and the fields show it.
 *
 * Colours are numbered 0 accent, 1 secondary colour, 2 panels, 3 cells, 4 tiles, 5 text, 6 lines (PALETTE_IDS); each lies in
 * einv_gui_palette where PALETTE_SLOTS says (the panels' transparency, at 2, and the tiles', at 8, are no colours).
 *
 * Modes:
 *   "alpha"  - the place 0 to 1 along the panels' slider: 0 is opaque, 1 as see-through as PALETTE_ALPHA_MIN allows (all the way)
 *   "tileAlpha" - the same for the item tiles' slider (the entry at 8)
 *   "hue"    - [colour, place]: the place 0 to 1 down the strip
 *   "square" - [colour, across, down]: 0 to 1 each from the square's top left: saturation from 0 to 1 across, value from its
 *              top (the colour's brightest) to 0 at the bottom
 *   "field"  - [colour, field, text]: what was typed in a field - 0 red, 1 green, 2 blue (0 to 255) or 3 the hex code (3 or 6
 *              digits, # first or not); a text that is none of these is put back, and a colour with no hue (grey) or no
 *              saturation (black) keeps the picker's hue and saturation
 *   "reset"  - "accent" (back to the Arma profile's colour), "secondary" (follows the accent again), "panel", "cells", "tiles",
 *              "text", "lines", "alpha", "tileAlpha" (each the theme's own) or "all"
 *
 * Arguments:
 * 0: Mode <STRING>
 * 1: Argument <ANY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["hue", [0, 0.5]] call einv_gui_fnc_paletteSet;
 *
 * Public: No
 */

params [["_mode", "", [""]], ["_argument", 0]];

// The array is changed in place: it is the one fnc_palette hands a copy of (PALETTE_UNSET says what lies where).
private _palette = GVAR(palette);
private _changed = false;

private _info = [] call FUNC(paletteInfo);

// Puts a colour's hue, saturation and value into the palette: rounded, the value cut where the colour is a surface under the text.
// False where it is the choice already.
private _fnc_pick = {
    params ["_which", "_hsv"];

    _hsv = _hsv apply {(((round (_x * 100000)) / 100000) max 0) min 1};
    _hsv set [2, (_hsv select 2) min (PALETTE_VALUE_MAX select _which)];

    private _slot = PALETTE_SLOTS select _which;

    if (((_info get "set") select _which) && {(_palette select _slot) isEqualTo _hsv}) exitWith {false};

    _palette set [_slot, _hsv];

    true
};

// Grown from an older save: every place there is now.
while {count _palette < count PALETTE_UNSET} do {
    _palette pushBack (PALETTE_UNSET select (count _palette));
};

// The places the rows' "Default" buttons take back, by row id: a row with a slider takes its transparency with its colour.
private _rowSlots = createHashMapFromArray [
    ["accent", [0]], ["titles", [12, 10]], ["secondary", [1, 14]], ["panel", [3, 2, 13]], ["cells", [4, 9]], ["items", [8]],
    ["text", [6]], ["lines", [7, 15]]
];

switch (_mode) do {
    // A transparency's slider: the panels', the cells' or the tiles'.
    case "alpha";
    case "cellAlpha";
    case "tileAlpha";
    case "secondaryAlpha";
    case "linesAlpha": {
        private _slot = (createHashMapFromArray PALETTE_ALPHAS) get _mode;
        private _place = (_argument max 0) min 1;
        private _alpha = 1 - (round (_place * (1 - PALETTE_ALPHA_MIN) / PALETTE_ALPHA_STEP)) * PALETTE_ALPHA_STEP;

        // Two decimals: the sum above leaves dust.
        _alpha = (round (_alpha * 100)) / 100;

        if ((_palette select _slot) isEqualTo _alpha) exitWith {};

        _palette set [_slot, _alpha];
        _changed = true;
    };

    // A style of the dropdown (fnc_paletteStyles): every place as the style says, and its id kept.
    case "style": {
        private _style = ([] call FUNC(paletteStyles)) select {(_x select 0) isEqualTo _argument};

        if (_style isEqualTo []) exitWith {};

        private _was = +_palette;
        private _values = +PALETTE_UNSET;

        {
            _values set [_forEachIndex, if (_x isEqualType []) then {+_x} else {_x}];
        } forEach ((_style select 0) select 2);

        _values set [11, _argument];

        // How far the gradient reaches is no part of a style: it stays as the player set it.
        _values set [16, _palette param [16, -1]];

        {
            _palette set [_forEachIndex, _x];
        } forEach _values;

        _changed = _was isNotEqualTo _palette;
    };

    case "hue": {
        _argument params [["_which", -1, [0]], ["_place", 0, [0]]];

        if (_which < 0 || {_which >= PALETTE_COLOURS}) exitWith {};

        // The strip's end is one step short of red again, so that the bottom is not a jump back to the top.
        private _step = (round (((_place max 0) min 1) * PALETTE_HUE_STEPS)) min (PALETTE_HUE_STEPS - 1);
        private _hsv = +((_info get "hsv") select _which);

        _hsv set [0, _step / PALETTE_HUE_STEPS];
        _changed = [_which, _hsv] call _fnc_pick;
    };

    case "square": {
        _argument params [["_which", -1, [0]], ["_across", 0, [0]], ["_down", 0, [0]]];

        if (_which < 0 || {_which >= PALETTE_COLOURS}) exitWith {};

        private _valueMax = PALETTE_VALUE_MAX select _which;
        private _saturation = (round (((_across max 0) min 1) * PALETTE_SV_STEPS)) / PALETTE_SV_STEPS;
        private _value = (round ((1 - ((_down max 0) min 1)) * PALETTE_SV_STEPS)) / PALETTE_SV_STEPS * _valueMax;
        private _hsv = +((_info get "hsv") select _which);

        _hsv set [1, _saturation];
        _hsv set [2, _value];
        _changed = [_which, _hsv] call _fnc_pick;
    };

    case "field": {
        _argument params [["_which", -1, [0]], ["_field", 0, [0]], ["_text", "", [""]]];

        if (_which < 0 || {_which >= PALETTE_COLOURS}) exitWith {};

        // What the fields say now: only a different value is a choice (a click into a field and out again is none).
        private _shown = ((_info get "rgb") select _which) apply {round (_x * 255)};
        private _typed = +_shown;
        private _valid = false;
        private _clean = trim _text;

        if (_field < 3) then {
            // Digits only, up to three of them: 0 to 255, more is cut.
            private _codes = toArray _clean;

            if (_codes isNotEqualTo [] && {count _codes <= 3} && {_codes findIf {_x < 48 || {_x > 57}} < 0}) then {
                _typed set [_field, (parseNumber _clean) min 255];
                _valid = true;
            };
        } else {
            // Three or six hex digits, a # in front or not.
            if ((_clean select [0, 1]) isEqualTo "#") then {
                _clean = _clean select [1];
            };

            private _digits = "0123456789abcdef";
            private _nibbles = (toLower _clean splitString "") apply {_digits find _x};

            if (count _nibbles in [3, 6] && {_nibbles findIf {_x < 0} < 0}) then {
                if (count _nibbles == 3) then {
                    _nibbles = [_nibbles select 0, _nibbles select 0, _nibbles select 1, _nibbles select 1, _nibbles select 2, _nibbles select 2];
                };

                _typed = [0, 2, 4] apply {(_nibbles select _x) * 16 + (_nibbles select (_x + 1))};
                _valid = true;
            };
        };

        // Nothing usable or nothing new: the fields are set to what is there again.
        if (!_valid || {_typed isEqualTo _shown}) exitWith {
            [] call FUNC(updatePaletteMenu);
        };

        private _was = (_info get "hsv") select _which;
        private _hsv = ["hsv", _typed apply {_x / 255}] call FUNC(hsv);

        // A grey has no hue and black no saturation: the picker keeps its own, or the cursor would jump to the corner.
        if ((_hsv select 1) == 0) then {
            _hsv set [0, _was select 0];
        };

        if ((_hsv select 2) == 0) then {
            _hsv set [0, _was select 0];
            _hsv set [1, _was select 1];
        };

        _changed = [_which, _hsv] call _fnc_pick;

        // A typed colour a surface cuts comes back changed, and one cut to the choice already made changes nothing: either way the
        // fields show what is.
        if (!_changed) then {
            [] call FUNC(updatePaletteMenu);
        };
    };

    // A row's gradient on or off: on, its end starts as its colour turned a sixth round (and the titles start at the accent when
    // they have no colour of their own yet); off, the end goes.
    case "gradient": {
        private _pair = (createHashMapFromArray [["titles", [8, 7]], ["panel", [2, 9]]]) getOrDefault [_argument, []];

        if (_pair isEqualTo []) exitWith {};

        _pair params ["_start", "_end"];

        private _endSlot = PALETTE_SLOTS select _end;

        if ((_palette select _endSlot) isNotEqualTo []) then {
            _palette set [_endSlot, []];
        } else {
            private _hsvs = _info get "hsv";

            if (_argument isEqualTo "titles" && {(_palette select 12) isEqualTo []}) then {
                _palette set [12, +(_hsvs select 0)];
            };

            _palette set [_endSlot, +(_hsvs select _end)];
        };

        _changed = true;
    };

    case "gradientReach": {
        if (_argument isEqualType 0 && {_argument in [0, 1, 2]} && {(_palette param [16, -1]) isNotEqualTo _argument}) then {
            _palette set [16, _argument];
            _changed = true;
        };
    };

    case "reset": {
        private _was = +_palette;

        // Everything, or the places of one row.
        if (_argument isEqualTo "all") then {
            {
                // A copy of a colour; a style's name is a plain string, which has none to make.
                _palette set [_forEachIndex, if (_x isEqualType []) then {+_x} else {_x}];
            } forEach PALETTE_DEFAULT;
        } else {
            {
                private _unset = PALETTE_DEFAULT select _x;

                _palette set [_x, if (_unset isEqualType []) then {+_unset} else {_unset}];
            } forEach (_rowSlots getOrDefault [_argument, []]);
        };

        _changed = _was isNotEqualTo _palette;
    };
};

// Changed by hand: no longer the style picked last (the dropdown says "Custom").
if (_changed && {_mode isNotEqualTo "style"} && {!(_mode isEqualTo "reset" && {_argument isEqualTo "all"})}) then {
    _palette set [11, ""];
};

if (!_changed) exitWith {};

GVAR(paletteDirty) = true;

[] call FUNC(updatePaletteMenu);

// A press on a picker is the event of a control that the build deletes, so the build waits for the next frame.
[{[] call FUNC(buildSoon)}] call FUNC(later);
