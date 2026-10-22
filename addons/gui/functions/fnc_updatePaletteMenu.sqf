#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows what the palette is set to in the popover under the palette button (fnc_openPaletteMenu), in place: each slider's knob
 * and value, the panel of the pure hue behind a vividness track, the swatches, and the buttons that take a choice away, which
 * show only while there is one. Asked whenever a value changes (fnc_paletteSet), so a slider follows the mouse without the
 * popover being made again, and by the popover itself when it is made. Nothing happens while it is not open.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_gui_fnc_updatePaletteMenu;
 *
 * Public: No
 */

disableSerialization;

private _rows = uiNamespace getVariable [QGVAR(paletteRows), createHashMap];

if (count _rows == 0) exitWith {};

private _info = [] call FUNC(paletteInfo);

(_info get "accentHs") params ["_accentHue", "_accentVivid"];
(_info get "secondaryHs") params ["_secondaryHue", "_secondaryVivid"];

private _alpha = _info get "alpha";

// How far along its track each slider stands, 0 to 1 (the transparency's 0 is an alpha of 1).
private _places = [_accentHue, _accentVivid, _secondaryHue, _secondaryVivid, (1 - _alpha) / (1 - PALETTE_ALPHA_MIN)];

// The text of a value: a vividness and the transparency in percent, a hue by its colour alone.
private _values = ["", str round (_accentVivid * 100) + " %", "", str round (_secondaryVivid * 100) + " %", str round ((1 - _alpha) * 100) + " %"];

{
    _x params ["_thumbs", "_geo", "_value", "_extra"];
    _geo params ["_left", "_top", "_width", "_height", "_thumbW", "_thumbH", "_thumbTop"];

    private _place = ((_places select _forEachIndex) max 0) min 1;
    private _knobX = _left + _width * _place - _thumbW / 2;

    // The knob is two circles: the dark ring a little larger than the white one.
    (_thumbs select 0) ctrlSetPosition [_knobX - pixelW * 2, _thumbTop - pixelH * 2, _thumbW + pixelW * 4, _thumbH + pixelH * 4];
    (_thumbs select 0) ctrlCommit 0;
    (_thumbs select 1) ctrlSetPosition [_knobX, _thumbTop, _thumbW, _thumbH];
    (_thumbs select 1) ctrlCommit 0;

    _value ctrlSetText (_values select _forEachIndex);

    if (!isNull _extra) then {
        if (_forEachIndex == 4) then {
            // The fill of the transparency's track.
            _extra ctrlSetPosition [_left, _top, _width * _place, _height];
            _extra ctrlCommit 0;
            _extra ctrlShow (_place > 0);
        } else {
            // The pure hue under a vividness track: this colour's own hue, at full strength.
            private _pure = ["rgb", [[_accentHue, _secondaryHue] select (_forEachIndex == 3), 1, 1]] call FUNC(hsv);

            _extra ctrlSetBackgroundColor (_pure + [1]);
        };
    };
} forEach (_rows get "sliders");

// The swatches: the accent, the secondary colour and the panel colour as the panels have it now.
private _swatches = _rows get "swatches";

[_swatches select 0, (_info get "accentRgb") + [1]] call FUNC(paintSurface);
[_swatches select 1, (_info get "secondaryRgb") + [1]] call FUNC(paintSurface);
[_swatches select 2, ((GVAR(theme) getOrDefault ["panel", [0.05, 0.05, 0.05, 1]]) select [0, 3]) + [_alpha]] call FUNC(paintSurface);

// What can be taken away shows its button.
private _chosen = [_info get "accentSet", _info get "secondarySet", _info get "alphaSet"];

{
    private _on = _chosen select _forEachIndex;

    {_x ctrlShow _on} forEach _x;
} forEach (_rows get "chips");

{_x ctrlShow (_info get "any")} forEach (_rows get "resetAll");
