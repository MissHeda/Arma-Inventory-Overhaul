#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows the volumes in the dropdown under the speaker in the header (fnc_openSoundMenu), in place: each row's
 * switch, the slider's fill and knob, the percentage, and the "Mute all" / "Unmute all" at the top. Asked
 * whenever a volume changes (fnc_soundSet), so a slider follows the mouse without the dropdown being made
 * again. Nothing happens while the dropdown is not open.
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

(uiNamespace getVariable [QGVAR(soundRows), []]) params [["_allLabel", controlNull], ["_rows", []]];

if (isNull _allLabel) exitWith {};

private _theme = GVAR(theme);
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _text = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _boxOff = [1, 1, 1, 0.16];

_allLabel ctrlSetText ([LLSTRING(Sound_MuteAll), LLSTRING(Sound_UnmuteAll)] select ([""] call FUNC(soundMuted)));

{
    _x params ["_index", "_box", "_check", "_label", "_fill", "_thumb", "_percent", "_geo"];
    _geo params ["_left", "_top", "_width", "_height", "_thumbW", "_thumbH", "_thumbTop"];

    private _volume = if (_index < 0) then {GVAR(soundMaster)} else {(GVAR(soundLevels) select _index) select 0};
    private _on = _volume > 0;

    // The switch: the accent with a tick while on, a faint film while off. The master volume has none.
    if (_index >= 0) then {
        private _color = [_boxOff, _accent] select _on;

        {
            if (ctrlClassName _x isEqualTo "EINV_PanelRect") then {
                _x ctrlSetBackgroundColor _color;
            } else {
                _x ctrlSetTextColor _color;
            };
        } forEach _box;

        _check ctrlShow _on;
    };

    _label ctrlSetTextColor ([_muted, _text] select (_on || {_index < 0}));

    _fill ctrlSetBackgroundColor ([_muted, _accent] select _on);
    _fill ctrlSetPosition [_left, _top, _width * _volume, _height];
    _fill ctrlCommit 0;
    _fill ctrlShow _on;

    _thumb ctrlSetTextColor ([_muted, _text] select _on);
    _thumb ctrlSetPosition [_left + _width * _volume - _thumbW / 2, _thumbTop, _thumbW, _thumbH];
    _thumb ctrlCommit 0;

    _percent ctrlSetText ((str round (_volume * 100)) + "%");
    _percent ctrlSetTextColor ([_muted, _text] select _on);
} forEach _rows;
