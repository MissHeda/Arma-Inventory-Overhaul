#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts ACE's list right for what the open uniform, vest or backpack holds, after the panel changed it or
 * took back what ACE had just written down: the count of every row (as ACE counts, by uniformItems,
 * vestItems or backpackItems), the load bar, ACE's own record of the container's items
 * (ace_arsenal_currentItems) and, through ACE's ace_arsenal_fnc_updateRightPanel, the "Remove all" button,
 * the weight text and its greying of rows. The rows ACE greys by weight are lit again afterwards where the
 * grid has room (fnc_ungrey).
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_arsenal_fnc_syncAce;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

(call FUNC(selected)) params ["_id", "_container", "", "_itemsIndex", "_loadoutIndex"];

private _list = _display displayCtrl ARSENAL_IDC_LIST;
private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

if (isNull _container || {isNull _list}) exitWith {};

private _items = switch (_id) do {
    case "uniform": {uniformItems _center};
    case "vest": {vestItems _center};
    default {backpackItems _center};
};

private _counts = createHashMap;

{
    private _key = toLowerANSI _x;
    _counts set [_key, (_counts getOrDefault [_key, 0]) + 1];
} forEach _items;

for "_row" from 0 to ((lnbSize _list) select 0) - 1 do {
    private _text = str (_counts getOrDefault [toLowerANSI (_list lnbData [_row, 0]), 0]);

    if ((_list lnbText [_row, 2]) isNotEqualTo _text) then {
        _list lnbSetText [[_row, 2], _text];
    };
};

private _load = switch (_id) do {
    case "uniform": {loadUniform _center};
    case "vest": {loadVest _center};
    default {loadBackpack _center};
};

(_display displayCtrl ARSENAL_IDC_LOAD) progressSetPosition _load;

private _current = missionNamespace getVariable [QACEGVAR(arsenal,currentItems), []];

if (_current isEqualType [] && {count _current > _itemsIndex}) then {
    _current set [_itemsIndex, ((getUnitLoadout _center) select _loadoutIndex) param [1, []]];
};

if (!isNil QACEFUNC(arsenal,updateRightPanel)) then {
    private _begin = diag_tickTime;

    [_list, _container, _items isNotEqualTo []] call ACEFUNC(arsenal,updateRightPanel);

    // ACE's own look at every row (its weight check), which no budget of ours can cut: told apart in the log.
    ["syncAce/ACE's updateRightPanel (ACE's own code)", _begin, format ["%1 rows", (lnbSize _list) select 0]] call FUNC(noteOpen);
};
