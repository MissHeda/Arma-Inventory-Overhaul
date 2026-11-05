#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Changes a size the size popover under its button in the header sets (fnc_openSizeMenu, fnc_sizeDefs) and shows it at once: the
 * value goes into the mission namespace, where the window reads it, and the open window is built again at the new size with the
 * popover kept open over it (fnc_sizeChanged) - the player sees the tiles and the words grow and shrink while the slider moves.
 *
 * What was changed is written to the player's CBA client setting once, when the slider is let go or the popover closes
 * ("commit", fnc_sizeSlide, fnc_sizeSettle), not with every step of a drag: CBA keeps it in the profile and shows it in its own
 * options, and its script comes back to fnc_sizeChanged with what the window shows already. A size a server or a mission forces
 * (fnc_settingForced) is not changed.
 *
 * Modes:
 *   "value"  - [index, value]: the size (an index of fnc_sizeDefs) to the value, in its slider's steps and between its ends
 *   "reset"  - every size back to its default, written at once
 *   "commit" - what was changed is written to CBA
 *
 * Arguments:
 * 0: Mode <STRING>
 * 1: Argument - "value": [index, value] <ANY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * ["value", [0, 1.2]] call aio_gui_fnc_sizeSet;
 *
 * Public: No
 */

params [["_mode", "", [""]], ["_argument", []]];

private _defs = call FUNC(sizeDefs);

// Into the mission namespace only; the setting's name is kept to be written to CBA.
private _fnc_value = {
    params ["_index", "_value"];

    (_defs param [_index, []]) params [["_setting", ""], "", "", ["_least", 0], ["_most", 1], ["_step", 1]];

    if (_setting isEqualTo "" || {[_setting] call FUNC(settingForced)}) exitWith {false};

    _value = (round ((((_value max _least) min _most) - _least) / _step)) * _step + _least;

    // Whole hundredths: a step of 0.05 added up must not leave 1.1500000001 in CBA's options.
    _value = (round (_value * 100)) / 100;

    if (_value isEqualTo ([_index] call FUNC(sizeValue))) exitWith {false};

    missionNamespace setVariable [_setting, _value];
    GVAR(sizeDirty) pushBackUnique _setting;

    true
};

switch (_mode) do {
    case "value": {
        _argument params [["_index", -1, [0]], ["_value", 0, [0]]];

        if ([_index, _value] call _fnc_value) then {
            [] call FUNC(sizeChanged);
        };
    };

    case "reset": {
        private _changed = false;

        {
            if ([_forEachIndex, _x select 6] call _fnc_value) then {
                _changed = true;
            };
        } forEach _defs;

        if (_changed) then {
            [] call FUNC(sizeChanged);
        };

        ["commit"] call FUNC(sizeSet);
    };

    case "commit": {
        private _dirty = GVAR(sizeDirty);

        GVAR(sizeDirty) = [];

        if (isNil "CBA_settings_fnc_set") exitWith {};

        {
            private _value = missionNamespace getVariable _x;

            if (!isNil "_value" && {!([_x] call FUNC(settingForced))}) then {
                [_x, _value, 0, "client"] call CBA_settings_fnc_set;
            };
        } forEach _dirty;
    };
};
