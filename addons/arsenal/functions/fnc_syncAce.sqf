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
 * While Enhanced First Aid Kits' kits tab lies over ACE's panels (fnc_focusedKit) ACE's list is hidden under it, and
 * the list shown counts what the picked kit holds by itself - that mod's own, from the kit's contents that every
 * change writes (efak_core_contentsChanged). What ACE keeps of the soldier is kept right all the same: its record of
 * the uniform's, vest's and backpack's items (ace_arsenal_currentItems) - things move between them and the kit - and
 * the weight beside its menu bar, three frames later: a kit's own weight reaches the soldier's load a frame after its
 * contents change, which that mod's tab waits for as well (efak_arsenal_fnc_flush). ACE's updateRightPanel is not
 * asked then: it would show its "Remove all" over that tab.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call aio_arsenal_fnc_syncAce;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

private _center = (call FUNC(center));

if ((([_display] call FUNC(focusedKit)) select 0)) exitWith {
    if (isNull _center) exitWith {};

    private _current = missionNamespace getVariable [QACEGVAR(arsenal,currentItems), []];

    if (_current isEqualType [] && {count _current > ARSENAL_ITEMS_BACKPACK}) then {
        private _loadout = getUnitLoadout _center;

        {
            _x params ["_itemsIndex", "_loadoutIndex"];

            _current set [_itemsIndex, (_loadout select _loadoutIndex) param [1, []]];
        } forEach [
            [ARSENAL_ITEMS_UNIFORM, LOADOUT_UNIFORM], [ARSENAL_ITEMS_VEST, LOADOUT_VEST], [ARSENAL_ITEMS_BACKPACK, LOADOUT_BACKPACK]
        ];
    };

    if (isNil QACEFUNC(common,getWeight)) exitWith {};

    // Three frames on: the next frame's script, twice more.
    [{
        [{
            [{
                params ["_display", "_center"];

                if (isNull _display || {isNull _center}) exitWith {};

                (_display displayCtrl ARSENAL_IDC_WEIGHT) ctrlSetText format [
                    "%1 (%2)", _center call ACEFUNC(common,getWeight), [_center, 1] call ACEFUNC(common,getWeight)
                ];
            }, _this] call EFUNC(gui,later);
        }, _this] call EFUNC(gui,later);
    }, [_display, _center]] call EFUNC(gui,later);
};

(call FUNC(selected)) params ["_id", "_container", "", "_itemsIndex", "_loadoutIndex"];

private _list = [_display] call FUNC(rightList);
private _bi = GVAR(kind) isEqualTo "bi";

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

(_display displayCtrl ([ARSENAL_IDC_LOAD, BI_IDC_LOAD] select _bi)) progressSetPosition _load;

// The vanilla arsenal keeps no record of its own: its rows are greyed again by weight, as its own "+" does it.
if (_bi) exitWith {
    ["SelectItemRight", [_display, _list, ctrlIDC _list - BI_IDC_LIST]] call BIS_fnc_arsenal;
};

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
