#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes away what fnc_coalesce keeps waiting for a key, because the work was done another way meanwhile (a build made by the
 * signature check covers the build a click asked for). The key keeps resting as it did.
 *
 * Arguments:
 * 0: The key <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["build"] call aio_gui_fnc_coalesceDrop;
 *
 * Public: No
 */

params [["_key", "", [""]]];

private _state = GVAR(coalesced) getOrDefault [_key, []];

if (_state isNotEqualTo []) then {
    _state set [2, -1];
};
