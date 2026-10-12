#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Says in words who a lock is for: "BLUFOR only", "group Alpha 1-1 only", "a disbanded group only",
 * "admins only". The text behind a locked section and in the tips and notices.
 *
 * Arguments:
 * 0: Lock, [mode, who] as fnc_getLock gives it <ARRAY>
 *
 * Return Value:
 * Text, "" when not locked <STRING>
 *
 * Example:
 * [[_crate] call einv_locks_fnc_getLock] call einv_locks_fnc_describe;
 *
 * Public: Yes
 */

params [["_lock", [], [[]]]];

_lock params [["_mode", "", [""]], ["_who", ""]];

private _text = "";

switch (_mode) do {
    case "admins": {
        _text = LLSTRING(Who_Admins);
    };
    case "side": {
        private _name = "";

        if (_who isEqualTo west) then {_name = LLSTRING(Side_West)};
        if (_who isEqualTo east) then {_name = LLSTRING(Side_East)};
        if (_who isEqualTo independent) then {_name = LLSTRING(Side_Independent)};
        if (_who isEqualTo civilian) then {_name = LLSTRING(Side_Civilian)};

        if (_name isNotEqualTo "") then {
            _text = format [LLSTRING(Who_Side), _name];
        };
    };
    case "group": {
        // A group that is gone (everyone left or died) is null for everyone who still holds the lock.
        if (_who isEqualType grpNull) then {
            if (isNull _who) then {
                _text = LLSTRING(Who_GroupGone);
            } else {
                _text = format [LLSTRING(Who_Group), groupId _who];
            };
        } else {
            _text = format [LLSTRING(Who_Group), _who];
        };
    };
};

_text
