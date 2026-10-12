#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Loads the selected loadout: the unique items on the soldier that it would lose ask for the second click,
 * then ACE's loadout is set with full magazines, the places with it, what does not fit goes back
 * (fnc_trimToFit), and ACE's events are raised.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Loaded <BOOL>
 *
 * Example:
 * call einv_arsenal_fnc_loadoutLoad;
 *
 * Public: No
 */

private _unit = GVAR(center);

if (isNull _unit) exitWith {false};

private _row = ([GVAR(loadoutsTab), false, GVAR(loadoutSelected)] call FUNC(loadoutsData)) param [0, []];

if (_row isEqualTo []) exitWith {false};

_row params ["_name", "", "", "", "", "_check", "_id"];

// Not checked yet: it is checked now, ACE's way - nothing is set from a loadout that was not.
if (_check isEqualTo []) then {
    _check = [_row] call FUNC(verifyStep);
};

private _extended = _check select 0;

// Loading replaces everything he wears and carries. What this arsenal does not have and the loadout does not
// bring back would be lost for good.
private _loadedClasses = (flatten (_extended select 0)) select {_x isEqualType "" && {_x isNotEqualTo ""}} apply {toLowerANSI _x};
private _lost = (flatten (getUnitLoadout _unit)) select {
    _x isEqualType "" && {_x isNotEqualTo ""} && {!(toLowerANSI _x in _loadedClasses)} && {[_x] call FUNC(isUnique)}
};

if (_lost isNotEqualTo [] && {!(["load|" + _id, format [LLSTRING(Loadouts_ConfirmLoad), [_lost select 0] call EFUNC(gui,itemName)]] call FUNC(arm))}) exitWith {false};

[_extended, _name, true] call FUNC(applyLoadout);

[QACEGVAR(arsenal,onLoadoutLoad), [_extended select 0, _name]] call CBA_fnc_localEvent;
[QACEGVAR(arsenal,onLoadoutLoadExtended), [_extended, _name]] call CBA_fnc_localEvent;

true
