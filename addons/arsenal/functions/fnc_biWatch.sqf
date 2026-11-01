#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The vanilla Virtual Arsenal tells of no change the way ACE does (ace_arsenal_itemsChanged, fnc_onItemsChanged): its "+" and
 * "-", another uniform, vest or backpack picked in its list, a loadout loaded or the tab switched all happen in BI's own code.
 * So the panel's frame looks (fnc_onFrame, every BI_WATCH_FRAMES frames): the soldier's three containers, what each weighs and
 * holds, and the tabs open. When any of it changed, it does what ACE's event does - the arrangement of new containers put
 * back (fnc_keepPlaces), what came in laid out (fnc_reconcile) and the panel and the list put right (fnc_settle).
 *
 * Arguments:
 * 0: The vanilla arsenal's display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call aio_arsenal_fnc_biWatch;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

if (!GVAR(attached) || {isNull _display} || {diag_frameNo % BI_WATCH_FRAMES != 0}) exitWith {};

private _center = call FUNC(center);

if (isNull _center) exitWith {};

private _list = [_display] call FUNC(rightList);
private _seen = [
    uniformContainer _center, vestContainer _center, backpackContainer _center,
    loadUniform _center, loadVest _center, loadBackpack _center,
    count uniformItems _center, count vestItems _center, count backpackItems _center,
    (call FUNC(selected)) select 2, ctrlIDC _list
];

if (_seen isEqualTo GVAR(biSeen)) exitWith {};

private _first = GVAR(biSeen) isEqualTo [];

GVAR(biSeen) = _seen;

if (_first) exitWith {};

[] call FUNC(keepPlaces);
GVAR(itemsSeen) = true;

if (((call FUNC(selected)) select 0) isNotEqualTo "") then {
    [_display] call FUNC(reconcile);
};

[] call FUNC(settle);
