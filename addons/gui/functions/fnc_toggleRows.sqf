#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the empty rows a tall compartment folds away (fnc_viewBlocks) - the line under its grid - or
 * folds them away again, and builds the window. Kept per holder for as long as the mission runs
 * (GVAR(expanded)), like the sections folded to their caption.
 *
 * Arguments:
 * 0: Holder - the container, or a key <OBJECT or STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_crate] call einv_gui_fnc_toggleRows;
 *
 * Public: No
 */

disableSerialization;

params [["_holder", objNull, [objNull, ""]]];

if (_holder isEqualType objNull && {isNull _holder}) exitWith {};
if (_holder isEqualTo "") exitWith {};

private _index = GVAR(expanded) find _holder;

if (_index >= 0) then {
    GVAR(expanded) deleteAt _index;
} else {
    GVAR(expanded) pushBack _holder;
};

// Containers that are gone go with them.
GVAR(expanded) = GVAR(expanded) select {_x isEqualType "" || {!isNull _x}};

// The state is changed; the window is built once for a run of clicks (fnc_buildSoon).
[] call FUNC(buildSoon);
