#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Changes the window's sound volumes the dropdown under the speaker in the header (fnc_openSoundMenu) sets, and
 * shows it at once in the dropdown and on the speaker. Kept in the profile when the dropdown closes
 * (fnc_soundSettle) - or here, at once, when it is not open (a right click on the speaker).
 *
 * A kind of sound at volume 0 is off. Its switch turns it off by setting the volume to 0 and remembering what it
 * was; turned on again it comes back to that volume. Dragging a volume up from 0 turns the kind on. The master
 * volume is over all of them.
 *
 * Modes:
 *   "volume" - the kind (an index of einv_gui_soundGroups) is set to the volume, 0 to 1
 *   "toggle" - the kind's switch: off sets the volume to 0, on brings it back
 *   "master" - the master volume is set, 0 to 1
 *   "all"    - mutes every kind, or when everything is silent already, brings them all back
 *
 * Arguments:
 * 0: Mode <STRING>
 * 1: Argument - "volume": [index, volume]; "toggle": the index; "master": the volume <ANY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["volume", [1, 0.5]] call einv_gui_fnc_soundSet;
 *
 * Public: No
 */

params [["_mode", "", [""]], ["_argument", 0]];

private _levels = GVAR(soundLevels);

switch (_mode) do {
    case "volume": {
        _argument params [["_index", -1, [0]], ["_volume", 0, [0]]];

        if (_index < 0 || {_index >= count _levels}) exitWith {};

        _volume = (round (((_volume max 0) min 1) * 100)) / 100;

        private _level = _levels select _index;

        _level set [0, _volume];

        if (_volume > 0) then {
            _level set [1, _volume];
        };
    };

    case "toggle": {
        if (!(_argument isEqualType 0) || {_argument < 0} || {_argument >= count _levels}) exitWith {};

        private _level = _levels select _argument;

        if ((_level select 0) > 0) then {
            _level set [1, _level select 0];
            _level set [0, 0];
        } else {
            _level set [0, [1, _level select 1] select ((_level select 1) > 0)];
        };
    };

    case "master": {
        if !(_argument isEqualType 0) exitWith {};

        GVAR(soundMaster) = (round (((_argument max 0) min 1) * 100)) / 100;
    };

    case "all": {
        private _audible = !([""] call FUNC(soundMuted));

        {
            if (_audible) then {
                if ((_x select 0) > 0) then {
                    _x set [1, _x select 0];
                };

                _x set [0, 0];
            } else {
                _x set [0, [1, _x select 1] select ((_x select 1) > 0)];
            };
        } forEach _levels;

        if (!_audible && {GVAR(soundMaster) <= 0}) then {
            GVAR(soundMaster) = 1;
        };
    };
};

GVAR(soundDirty) = true;

[] call FUNC(updateSoundMenu);
[] call FUNC(updateSoundButton);

// Kept at once when the dropdown is not open to keep it for later.
if ((uiNamespace getVariable [QGVAR(menu), []]) isEqualTo [] || {(GVAR(menuFor) param [0, ""]) isNotEqualTo "sound"}) then {
    [] call FUNC(soundSettle);
};
