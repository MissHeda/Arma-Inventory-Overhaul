#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Something was let go on a target of the window (the "drop" hook): a card or an item of the soldier's on a
 * free cell, a slot, the soldier, the give-back zone. Adds, equips or gives back, and says what it did.
 * Always ends a drag from the catalog.
 *
 * A card on a grid makes the item there (fnc_addItem: as many as the wheel left, turned the way it was held,
 * on the cell under the mouse), on a slot puts it on (fnc_equipItem), on the soldier equips it like
 * Alt+click, on the catalog does nothing. On a kit - its open window's grid or its tile - it is packed into
 * the kit (einv_compat_efak_fnc_packNew: only when the kit's arsenal setting is everything, as many as the
 * kit takes), else the kit says why not. An item of the soldier's on the give-back zone - or outside every
 * panel - goes back (fnc_giveBack), on the soldier it is put on. Everything else of the soldier's own,
 * moves between his grids and slots, is the inventory's.
 *
 * Arguments:
 * 0: Kind of target - "grid", "slot", "zone", "kitTile", ... <STRING>
 * 1: Index of the grid the item was dragged from, -1 for a slot's item <NUMBER>
 * 2: Index of its tile there <NUMBER>
 * 3: Slot it was dragged from, [unit, slot], or [] <ARRAY>
 * 4: The entry that was dragged <HASHMAP>
 * 5: How many of a stack go, -1 for all <NUMBER>
 * 6: Index of the target (a grid, a slot, a zone) <NUMBER>
 * 7: Column of the cell - for a kit's tile the index of the tile in the grid <NUMBER>
 * 8: Row of the cell <NUMBER>
 * 9: Width the item lies in <NUMBER>
 * 10: Height the item lies in <NUMBER>
 * 11: Slot id of the target <STRING>
 * 12: Whether the cell is where it is to lie <BOOL>
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * _this call einv_arsenal_fnc_onDrop;
 *
 * Public: No
 */

params [
    ["_kind", "", [""]], ["_sourceIndex", -1, [0]], ["_tileIndex", -1, [0]], ["_slotSource", [], [[]]],
    ["_entry", createHashMap, [createHashMap]], ["_count", -1, [0]], ["_targetIndex", -1, [0]], ["_col", 0, [0]],
    ["_row", 0, [0]], ["_w", 1, [0]], ["_h", 1, [0]], ["_targetSlot", "", [""]], ["_place", true, [true]]
];

private _grids = uiNamespace getVariable [QEGVAR(gui,grids), []];
private _zones = uiNamespace getVariable [QEGVAR(gui,zones), []];
private _fromGrid = if (_slotSource isEqualTo []) then {_grids param [_sourceIndex, createHashMap]} else {createHashMap};
private _fromCatalog = (_fromGrid getOrDefault ["source", ""]) isNotEqualTo "";

(uiNamespace getVariable [QGVAR(column), createHashMap]) set ["dragZone", ""];

// The zone under the drop, by its id. One that is not there (the index -1) is the give-back.
private _zone = if (_targetIndex < 0) then {"giveBack"} else {(_zones param [_targetIndex, []]) param [1, "giveBack"]};

// ----- From the catalog -----
if (_fromCatalog) exitWith {
    private _class = _entry getOrDefault ["class", ""];
    private _stack = _entry getOrDefault ["count", 1];
    private _amount = [_count, _stack] select (_count < 1);

    if (_class isEqualTo "") exitWith {true};

    // Into a kit, as many as it takes: the sound, the words, and the window looked at again.
    private _fnc_pack = {
        params ["_kit", "_cell"];

        if (isNil QEFUNC(compat_efak,packNew)) exitWith {
            [LLSTRING(Hint_KitFirst)] call EFUNC(gui,flashHint);
        };

        ([_kit, _class, _amount, _cell, GVAR(center)] call EFUNC(compat_efak,packNew)) params ["_added", "_why"];

        if (_added < 1) exitWith {
            [[_why, LLSTRING(Hint_KitLocked)] select (_why isEqualTo "ReadOnly")] call EFUNC(gui,flashHint);
        };

        private _name = [_class] call EFUNC(gui,itemName);

        ["move", _class] call EFUNC(gui,playSound);

        if (_added < _amount) then {
            [format [LLSTRING(Hint_OnlySome), _added, _amount]] call EFUNC(gui,flashHint);
        } else {
            [format [LLSTRING(Hint_AddedTo), [_name, format ["%1× %2", _added, _name]] select (_added > 1), [_kit] call EFUNC(gui,itemName)]] call FUNC(message);
        };
    };

    switch (_kind) do {
        case "grid": {
            private _grid = _grids param [_targetIndex, createHashMap];
            private _kit = _grid getOrDefault ["kit", ""];

            if (_kit isNotEqualTo "") then {
                // The cell asked for; a taken one is the kit's layout's to change.
                [_kit, [_col, _row, 0, _w, _h]] call _fnc_pack;
            } else {
                [_class, _amount, _grid getOrDefault ["container", objNull], [_col, _row, _grid getOrDefault ["block", 0], _w, _h]] call FUNC(addItem);
            };
        };
        case "slot": {
            private _slot = _targetSlot;

            if (_slot isEqualTo "") then {
                _slot = ((uiNamespace getVariable [QEGVAR(gui,slots), []]) param [_targetIndex, []]) param [5, ""];
            };

            [_class, _slot] call FUNC(equipItem);
        };
        case "zone": {
            if (_zone isEqualTo "soldier") then {
                [_class, ""] call FUNC(equipItem);
            };
        };
        // The index of the tile comes in the place of the column.
        case "kitTile": {
            private _tile = ((_grids param [_targetIndex, createHashMap]) getOrDefault ["tiles", []]) param [_col, createHashMap];

            [_tile getOrDefault ["class", ""], []] call _fnc_pack;
        };
        default {};
    };

    true
};

// ----- From the soldier's own things -----
if (_kind isNotEqualTo "zone") exitWith {false};

switch (_zone) do {
    case "giveBack": {
        if (_slotSource isNotEqualTo []) then {
            [[_slotSource select 0, _slotSource select 1]] call FUNC(giveBack);
        } else {
            [[_sourceIndex, _tileIndex], _count] call FUNC(giveBack);
        };
    };
    case "soldier": {
        // A tile is put on; what is on him already stays.
        if (_slotSource isEqualTo []) then {
            [_sourceIndex, _tileIndex] call EFUNC(gui,quickEquip);
        };
    };
    default {};
};

true
