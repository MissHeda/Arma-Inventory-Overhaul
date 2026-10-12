#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads what the session offers from ACE's live lists, after every handler of ace_arsenal_displayOpened has
 * changed them - a role or whitelist mod removes classes, ACE Arsenal Extended swaps the list for one class
 * per model and keeps the full one - and keeps it for the catalog: a set of lowercase classes that are
 * offered and the category lists. Raises the counter the catalog compares to see that the supply changed.
 *
 * With ACE Arsenal Extended loaded the catalog lists its full copy, so every colour and variant is a card of
 * its own - this window has no panel of its own for choosing among variants. Without it, or when the list
 * itself is the fresh one (a refresh of the box, which raised no displayOpened), ACE's own map: whatever a
 * role or whitelist mod removed stays removed. ACE's virtualItems itself is left as the handlers set it, so
 * the functions of ACE that read the flat lists find what they expect.
 *
 * Arguments:
 * 0: After the event - false when the list itself is the fresh one, as after a refresh of the box <BOOL>
 *    (default: true)
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_readSupply;
 *
 * Public: No
 */

params [["_afterOpen", true, [true]]];

// A HashMap: _x is the class, whatever its value (nil for an offered class, true for a unique one - the flat
// list holds the offered ones only).
private _available = createHashMap;

{
    _available set [toLowerANSI _x, true];
} forEach (missionNamespace getVariable [QACEGVAR(arsenal,virtualItemsFlat), createHashMap]);

GVAR(availableLc) = _available;
GVAR(availableStamp) = GVAR(availableStamp) + 1;
GVAR(lists) = createHashMap;
GVAR(uniqueCache) = createHashMap;

private _items = missionNamespace getVariable [QACEGVAR(arsenal,virtualItems), createHashMap];

if (_afterOpen && {isClass (configFile >> "CfgPatches" >> "aceax_arsenal")}) then {
    private _full = missionNamespace getVariable ["aceax_arsenal_initialVirtualItems", createHashMap];

    if (_full isEqualType createHashMap && {count _full > 0}) then {
        _items = _full;
    };
};

GVAR(catalogItems) = _items;
