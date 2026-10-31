#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Notes what the open uniform, vest or backpack holds now (GVAR(snapshot)), so the next add of ACE can
 * be told from what was there: [container, lowercase class -> count] (fnc_countAll).
 *
 * Where everything lies is written down first (einv_storage_fnc_normalize, on the container's authority -
 * the player's own machine): laid out again after an add, every old tile then keeps its record and only
 * the new things look for a free spot - what finds none is that add, never something that lay there
 * already (fnc_reconcile).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_arsenal_fnc_snapshot;
 *
 * Public: No
 */

[] call FUNC(keepPlaces);

(call FUNC(selected)) params ["", "_container"];

if (isNull _container) exitWith {
    GVAR(snapshot) = [objNull, createHashMap];
};

[_container] call EFUNC(storage,normalize);

GVAR(snapshot) = [_container, [_container] call FUNC(countAll)];
