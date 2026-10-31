#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows the volumes in the dropdown under the speaker in the header (fnc_openSoundMenu), in place: each row's
 * switch, the slider's fill and knob and the percentage. Asked whenever a volume changes (fnc_soundSet), so a
 * slider follows the mouse without the dropdown being made again. Neutral greys only: a kind that is on is
 * white and light grey, one that is off is dim. Nothing happens while the dropdown is not open.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_gui_fnc_updateSoundMenu;
 *
 * Public: No
 */

disableSerialization;

private _rows = uiNamespace getVariable [QGVAR(soundRows), []];

if (_rows isEqualTo []) exitWith {};

private _theme = GVAR(theme);
private _text = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _boxOff = [1, 1, 1, 0.14];
private _boxOn = [0.86, 0.86, 0.86, 1];
private _fillOn = [0.72, 0.72, 0.72, 1];

{
    _x params ["_index", "_box", "_check", "_label", "_fill", "_thumb", "_percent", "_geo"];
    _geo params ["_left", "_top", "_width", "_height", "_thumbW", "_thumbH", "_thumbTop"];

    private _volume = (GVAR(soundLevels) select _index) select 0;
    private _on = _volume > 0;

    // The switch: light grey with a dark tick while on, a faint film while off.
    private _color = [_boxOff, _boxOn] select _on;

    {
        if (ctrlClassName _x isEqualTo "EINV_PanelRect") then {
            _x ctrlSetBackgroundColor _color;
        } else {
            _x ctrlSetTextColor _color;
        };
    } forEach _box;

    _check ctrlShow _on;

    _label ctrlSetTextColor ([_muted, _text] select _on);

    _fill ctrlSetBackgroundColor _fillOn;
    _fill ctrlSetPosition [_left, _top, _width * _volume, _height];
    _fill ctrlCommit 0;
    _fill ctrlShow _on;

    _thumb ctrlSetTextColor ([_muted, _text] select _on);
    _thumb ctrlSetPosition [_left + _width * _volume - _thumbW / 2, _thumbTop, _thumbW, _thumbH];
    _thumb ctrlCommit 0;

    _percent ctrlSetText ((str round (_volume * 100)) + "%");
    _percent ctrlSetTextColor ([_muted, _text] select _on);
} forEach _rows;
