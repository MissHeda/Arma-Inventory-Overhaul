#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The context menu (the "menu" hook): for a card inspect, equip or attach to a weapon, add here and there,
 * favorite, copy the class; for the soldier's own things also give back, give back all of a class, fill a
 * container, open, sort; for a slot show it in the arsenal, take off and detach; for free cells the target,
 * sort, empty the container. Replaces the inventory's, and so has none of the other mods' rows: they act on
 * the world.
 *
 * The rows of an open kit's tile are the kit's own (einv_compat_efak_fnc_menuChoices) besides the ones every
 * tile has; a tile in a kit's window can be given back when the kit's arsenal setting lets the arsenal take
 * things out of it (einv_compat_efak_fnc_arsenalEditing). Under a slot's rows come the actions ACE's window
 * has for that slot's tab (fnc_aceActions): the gunbag's, say.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * Choices [[text, arguments, code, options], ...], [] for no menu <ARRAY>
 *
 * Example:
 * [_display] call einv_arsenal_fnc_menu;
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

private _unit = GVAR(center);

if (isNull _unit) exitWith {[]};

private _grids = uiNamespace getVariable [QEGVAR(gui,grids), []];
private _slots = uiNamespace getVariable [QEGVAR(gui,slots), []];
private _hover = EGVAR(gui,hover);
private _choices = [];
private _equipment = [_unit] call EFUNC(storage,getEquipment);
private _containers = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] select {!isNull _x};

private _fnc_name = {
    params ["_class"];

    [_class] call EFUNC(gui,itemName)
};

// Equip, attach to, load into: a row for each place the soldier has for it.
private _fnc_equipRows = {
    params ["_class", "_code", ["_tileArgs", []]];

    private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";
    private _rows = [];

    if (_kind in ["muzzle", "optic", "rail", "bipod", "magazine", "grenade"]) then {
        private _parts = [[_kind], ["mag", "mag2"]] select (_kind in ["magazine", "grenade"]);

        {
            private _base = _x;
            private _weapon = (_equipment getOrDefault [_base, []]) param [0, ""];

            {
                private _slot = format ["%1_%2", _base, _x];

                if (_weapon isNotEqualTo "" && {[_unit, _slot, _class] call EFUNC(storage,slotAccepts)}) then {
                    _rows pushBack [
                        format [[LELSTRING(gui,Menu_AttachTo), LELSTRING(gui,Menu_LoadInto)] select (_x in ["mag", "mag2"]), [_weapon] call _fnc_name],
                        [_class, _slot] + _tileArgs, _code
                    ];
                };
            } forEach _parts;
        } forEach ["primary", "handgun", "launcher"];
    } else {
        private _slot = [_unit, _class] call EFUNC(storage,slotFor);

        if (_slot isNotEqualTo "") then {
            _rows pushBack [LELSTRING(gui,Equip), [_class, _slot] + _tileArgs, _code];
        };
    };

    _rows
};

// Sort is the storage's op: run where the container is local, seen by everyone.
private _fnc_sort = {
    params ["_grid"];

    private _container = _grid getOrDefault ["container", objNull];
    private _kit = _grid getOrDefault ["kit", ""];
    private _holder = if (_kit isEqualTo "") then {
        _grid getOrDefault ["holder", _container]
    } else {
        _grid getOrDefault ["holder", _grid getOrDefault ["layoutKey", ""]]
    };

    if (_holder isEqualTo "" || {_holder isEqualType objNull && {isNull _holder}}) exitWith {};

    _choices pushBack [
        format [LELSTRING(gui,Menu_Sort), [[_container] call EFUNC(gui,containerName), [_kit] call _fnc_name] select (_kit isNotEqualTo "")],
        [_holder, _grid getOrDefault ["root", objNull]],
        {
            params ["_holder", "_root"];

            [[createHashMapFromArray [["kind", "sort"], ["from", _holder], ["fromRoot", _root]]]] call EFUNC(gui,sendMoves);
        }
    ];
};

switch (_hover param [0, ""]) do {
    case "tile": {
        private _gridIndex = _hover param [1, -1];
        private _tileIndex = _hover param [2, -1];
        private _grid = _grids param [_gridIndex, createHashMap];
        private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
        private _class = _tile getOrDefault ["class", ""];

        if (_class isEqualTo "" || {_tile getOrDefault ["hidden", false]}) exitWith {};

        if ((_grid getOrDefault ["source", ""]) isNotEqualTo "") then {
            // ----- A card -----
            private _kind = _tile getOrDefault ["kind", ""];

            if (_kind in ["face", "voice", "insignia"]) then {
                _choices pushBack [LLSTRING(Menu_Use), [_kind, _class], {_this call FUNC(applyIdentity)}];
            } else {
                private _capacity = (_tile getOrDefault ["capacity", 0]);
                private _probe = createHashMapFromArray [
                    ["class", _class], ["count", 1], ["ammo", _capacity], ["capacity", _capacity], ["attachments", []], ["container", objNull]
                ];

                _choices pushBack [
                    LELSTRING(gui,Menu_Inspect), [_class, 1, -1, []], {_this call EFUNC(gui,inspect)}
                ];

                _choices append ([_class, {_this call FUNC(equipItem)}] call _fnc_equipRows);

                _choices pushBack [LLSTRING(Menu_Add), [_class, 1], {_this call FUNC(quickAdd)}];

                // Each of his containers with room for it and a cell.
                {
                    if ([_x, _probe] call EFUNC(storage,hasRoom) && {[_x, _probe] call EFUNC(storage,hasSpace)}) then {
                        _choices pushBack [format [LLSTRING(Menu_AddTo), [_x] call EFUNC(gui,containerName)], [_class, 1, _x], {_this call FUNC(quickAdd)}];
                    };
                } forEach _containers;

                private _amount = missionNamespace getVariable [QGVAR(quickAddAmount), 5];

                if (_amount > 1) then {
                    _choices pushBack [format [LLSTRING(Menu_AddMore), _amount], [_class, _amount], {_this call FUNC(quickAdd)}];
                };

                private _favorite = (toLowerANSI _class) in (missionNamespace getVariable [QACEGVAR(arsenal,favorites), createHashMap]);

                _choices pushBack [[LLSTRING(Menu_Favorite), LLSTRING(Menu_Unfavorite)] select _favorite, [_class], {_this call FUNC(toggleFavorite)}];
            };

            _choices pushBack [LLSTRING(Menu_CopyClass), [_class], {
                params ["_class"];

                if ([_class] call FUNC(clipboardWrite)) then {
                    [format [LLSTRING(Hint_Copied), _class]] call FUNC(message);
                };
            }];
        } else {
            // ----- A tile of the soldier's -----
            private _kit = _grid getOrDefault ["kit", ""];
            private _container = _grid getOrDefault ["container", objNull];
            private _inside = _tile getOrDefault ["container", objNull];

            if (isNull _container && {_kit isEqualTo ""}) exitWith {};

            _choices pushBack [
                LELSTRING(gui,Menu_Inspect),
                [_class, _tile getOrDefault ["count", 1], _tile getOrDefault ["ammo", -1], _tile getOrDefault ["attachments", []]],
                {_this call EFUNC(gui,inspect)}
            ];

            // Equip, attach, load: the inventory's own move (it takes the item out of where it lies).
            if !(_tile getOrDefault ["pending", false]) then {
                {
                    _x params ["_text", "_args"];

                    _args params ["", "_slot"];

                    _choices pushBack [_text, [_slot, _container, _tile, _kit], {_this call EFUNC(gui,doEquip)}];
                } forEach ([_class, {}] call _fnc_equipRows);

                if (_kit isEqualTo "") then {
                    _choices pushBack [LLSTRING(Menu_GiveBack), [[_gridIndex, _tileIndex], -1], {_this call FUNC(giveBack)}];
                    _choices pushBack [format [LLSTRING(Menu_GiveBackAll), [_class] call _fnc_name], [_class], {_this call FUNC(giveBackAll)}];
                    _choices pushBack [
                        format [LLSTRING(Menu_Fill), [_container] call EFUNC(gui,containerName)], [_class, _container], {_this call FUNC(fill)}
                    ];
                } else {
                    // Out of a kit, for a kit the arsenal may take things out of.
                    if (!isNil QEFUNC(compat_efak,arsenalEditing) && {([_kit] call EFUNC(compat_efak,arsenalEditing)) >= EDIT_REMOVE}) then {
                        _choices pushBack [LLSTRING(Menu_GiveBack), [[_gridIndex, _tileIndex], -1], {_this call FUNC(giveBack)}];
                    };
                };
            };

            // A kit opens or closes in a window of its own, with the kit's rows.
            if (!isNil QEFUNC(compat_efak,menuChoices)) then {
                _choices append ([_gridIndex, _tileIndex] call EFUNC(compat_efak,menuChoices));
            };

            // A uniform, vest or backpack lying here opens as a section of the storage column.
            if (!isNull _inside) then {
                private _isOpen = EGVAR(gui,opened) findIf {(_x select 1) isEqualTo _inside} >= 0;

                _choices pushBack [
                    format [[LLSTRING(Menu_Open), LLSTRING(Menu_Close)] select _isOpen, [_class] call _fnc_name],
                    [_gridIndex, _tileIndex], {_this call EFUNC(gui,openNested)}
                ];
            };

            [_grid] call _fnc_sort;
        };
    };
    case "slot": {
        private _index = _hover param [1, -1];
        private _record = _slots param [_index, []];
        private _slot = _record param [5, ""];
        private _class = _record param [1, ""];

        if (_slot isEqualTo "" || {(_record param [6, objNull]) isNotEqualTo _unit}) exitWith {};

        if (_class isNotEqualTo "") then {
            private _worn = [_unit, _slot] call EFUNC(storage,getSlot);

            _choices pushBack [
                LELSTRING(gui,Menu_Inspect), [_class, 1, _worn getOrDefault ["ammo", -1], _worn getOrDefault ["attachments", []]],
                {_this call EFUNC(gui,inspect)}
            ];
        };

        // The catalog shows what belongs in the slot, and the slot is the target.
        if (([_slot] call FUNC(categoryForSlot)) isNotEqualTo []) then {
            _choices pushBack [LLSTRING(Menu_Browse), [_index], {_this call FUNC(onSlotClick)}];
        };

        if (_class isEqualTo "") exitWith {};

        _choices pushBack [LELSTRING(gui,Menu_TakeOff), [_unit, _slot], {_this call EFUNC(gui,quickUnequip)}];
        _choices pushBack [LLSTRING(Menu_GiveBack), [[_unit, _slot], -1], {_this call FUNC(giveBack)}];

        // A weapon: each of its parts on its own, into the storage.
        if (_slot in ["primary", "handgun", "launcher"]) then {
            private _weapon = _equipment getOrDefault [_slot, []];

            {
                private _part = _weapon param [_forEachIndex + 1, ""];
                private _partClass = if (_part isEqualType []) then {_part param [0, ""]} else {_part};

                if (_partClass isNotEqualTo "") then {
                    _choices pushBack [
                        format [LELSTRING(gui,Menu_Detach), [_partClass] call _fnc_name],
                        [_unit, format ["%1_%2", _slot, _x]], {_this call EFUNC(gui,quickUnequip)}
                    ];
                };
            } forEach ["muzzle", "rail", "optic", "mag", "mag2", "bipod"];
        };

        // What ACE's window offers under this slot's tab.
        _choices append ([_slot] call FUNC(aceActions));
    };
    default {
        // Free cells of one of his containers: make it the target, sort it, empty it.
        private _mouse = getMousePosition;
        private _layer = [_mouse] call EFUNC(gui,topAt);
        private _grid = (_grids select {
            (_x getOrDefault ["window", ""]) isEqualTo _layer && {!(_x getOrDefault ["virtual", true])}
            && {([_x, _mouse] call EFUNC(gui,screenToCell)) isNotEqualTo []}
        }) param [0, createHashMap];
        private _container = _grid getOrDefault ["container", objNull];

        if (isNull _container || {(_grid getOrDefault ["kit", ""]) isNotEqualTo ""}) exitWith {};

        _choices pushBack [LLSTRING(Menu_AddHere), [_container], {
            params ["_container"];

            GVAR(targetContainer) = _container;
            [LLSTRING(Hint_Target)] call FUNC(message);
            [uiNamespace getVariable [QEGVAR(gui,display), displayNull]] call FUNC(drawTargets);
        }];

        [_grid] call _fnc_sort;

        _choices pushBack [
            format [LLSTRING(Menu_Empty), [_container] call EFUNC(gui,containerName)], [_container], {_this call FUNC(emptyContainer)}
        ];
    };
};

_choices
