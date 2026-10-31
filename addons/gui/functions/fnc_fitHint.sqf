#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Places the footer's hint line for what was just written into it (fnc_drawFooter keeps both boxes on it): centred on the
 * screen while the words fit there on one line, the whole room between the key hints and the version when they would
 * break onto a second. A hint line of another window (the Arsenal panel's) has no boxes and is left as it is.
 *
 * Arguments:
 * 0: The hint line <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_hint] call aio_gui_fnc_fitHint;
 *
 * Public: No
 */

params [["_hint", controlNull, [controlNull]]];

if (isNull _hint) exitWith {};

private _centred = _hint getVariable [QGVAR(hintCentred), []];

if (_centred isEqualTo []) exitWith {};

_hint ctrlSetPosition _centred;
_hint ctrlCommit 0;

if (ctrlTextHeight _hint > (_hint getVariable [QGVAR(hintLine), 0]) * 1.6) then {
    _hint ctrlSetPosition (_hint getVariable [QGVAR(hintWide), _centred]);
    _hint ctrlCommit 0;
};
