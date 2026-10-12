#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Return in a field of the window (the "submit" hook): in the name of a loadout it saves it.
 *
 * Arguments:
 * 0: The field <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_edit] call einv_arsenal_fnc_onSubmit;
 *
 * Public: No
 */

params [["_edit", controlNull, [controlNull]]];

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];

// Only the name of a loadout is saved by Return; the search field has its own way.
if (isNull _edit || {_edit isNotEqualTo (_column getOrDefault ["nameEdit", controlNull])}) exitWith {};

GVAR(loadoutName) = ctrlText _edit;

[GVAR(loadoutName)] call FUNC(loadoutSave);
