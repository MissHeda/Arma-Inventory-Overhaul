#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Folds a section of a column away to its caption, or opens it again - a click on its caption tab
 * (fnc_drawSection). What is kept per container for as long as the mission runs (GVAR(collapsed)) is the
 * change from how the section starts: own sections start open, the crates found lying around start
 * folded (their "folded"), so a container in the list is one the player turned the other way round.
 * Open kits have windows of their own (fnc_drawWindow), which do not fold.
 *
 * Arguments:
 * 0: The section's container <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [backpackContainer player] call einv_gui_fnc_toggleSection;
 *
 * Public: No
 */

disableSerialization;

params [["_container", objNull, [objNull]]];

if (isNull _container) exitWith {};

private _index = GVAR(collapsed) find _container;

if (_index >= 0) then {
    GVAR(collapsed) deleteAt _index;
} else {
    GVAR(collapsed) pushBack _container;
};

// Containers that are gone go with them.
GVAR(collapsed) = GVAR(collapsed) select {_x isEqualType objNull && {!isNull _x}};

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (!isNull _display) then {
    [_display] call FUNC(build);
};
