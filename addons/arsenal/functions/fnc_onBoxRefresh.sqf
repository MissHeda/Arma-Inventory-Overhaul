#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * ACE's list of a box changed while the window is open (ace_arsenal_refresh): the list is read again -
 * ACE's own refresh forgets the flat list of everything and the unique ones - and the catalog and the
 * loadouts follow. A box that lost its list closes the window.
 *
 * Only for the box of the open window, and only when its list is what the window offers: not a full
 * arsenal, which ignores the box's list, and not a vanilla box (its cargo is no ACE list). ACE's own
 * handler of the event runs as well and finds no display of its own to refresh.
 *
 * Arguments:
 * 0: The box that changed <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_box] call einv_arsenal_fnc_onBoxRefresh;
 *
 * Public: No
 */

params [["_box", objNull, [objNull]]];

if (isNull _box || {_box isNotEqualTo GVAR(box)} || {GVAR(full)} || {GVAR(source) isNotEqualTo "ace"}) exitWith {};

private _list = _box getVariable QACEGVAR(arsenal,virtualItems);

// The box left the arsenal system.
if (isNil "_list") exitWith {
    [LLSTRING(Hint_BoxGone), false, 4, 2] call ACEFUNC(common,displayText);
    [2] call FUNC(close);
};

// ACE's order: the list copied, flattened, the flat list kept as everything known, the unique ones after.
ACEGVAR(arsenal,virtualItems) = +_list;
call ACEFUNC(arsenal,updateVirtualItemsFlat);
ACEGVAR(arsenal,virtualItemsFlatAll) = +ACEGVAR(arsenal,virtualItemsFlat);
call ACEFUNC(arsenal,updateUniqueItemsList);

// The fresh list itself is the catalog's now: no displayOpened came for it, so ACE Arsenal Extended's copy
// would be the old one.
[false] call FUNC(readSupply);

// Loadouts are checked against the new supply the next time they are looked at.
GVAR(verified) = createHashMap;
GVAR(verifyQueue) = [];

[true] call FUNC(refreshCatalog);

// Built anew a frame later (this may come from inside any script).
[{
    private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

    if (!isNull _display) then {
        [_display] call EFUNC(gui,build);
    };
}, []] call EFUNC(gui,later);
