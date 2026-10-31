#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Closes a uniform, vest or backpack that was opened from inside a container (fnc_openNested) - the
 * cross on its section's caption line, with the sound of the container it is. Open kits close through their
 * windows (fnc_closeWindow).
 *
 * Arguments:
 * 0: Its container object <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_object] call aio_gui_fnc_closeNested;
 *
 * Public: No
 */

disableSerialization;

params [["_object", objNull, [objNull]]];

// Closes with the sound of the container it is, as it goes.
private _closing = GVAR(opened) findIf {(_x select 1) isEqualTo _object};

if (_closing >= 0) then {
    ["close", (GVAR(opened) select _closing) select 0, _object] call FUNC(playSound);
};

GVAR(opened) = GVAR(opened) select {(_x select 1) isNotEqualTo _object && {!isNull (_x select 1)}};

// The state is changed; the window is built once for a run of clicks (fnc_buildSoon).
[] call FUNC(buildSoon);
