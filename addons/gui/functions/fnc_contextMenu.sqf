#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Right click on what the mouse is on: the choices for it, in a context menu (fnc_openMenu).
 *
 * A tile: inspect it (fnc_inspect), put it on (or, for an attachment or magazine, on which of the
 * player's weapons), repack all magazines of its kind when it is a magazine that is not full in the
 * player's own gear (einv_magazines_fnc_menuChoices - only when that addon is loaded; the slot of a loaded
 * magazine has the row too), put it on the hotbar or take it off (einv_hotbar_fnc_menuChoices - only when that
 * addon is loaded), move it over (what a double click does, fnc_quickMove - the way for a backpack lying
 * in a crate, which opens on a double click), drop it, open it (a uniform, vest or backpack lying there
 * in the loot column), sort its container, select everything in it (fnc_selectSection). A slot: inspect
 * it, take it off, drop it, and for a weapon take off each of its attachments and its magazines on their
 * own; a slot of the hotbar: clear it (einv_hotbar_fnc_stripMenu). Free cells: sort the container, select
 * all in it.
 *
 * On a tile of a selection of several only what can be done with all of them: move them over, drop them,
 * deselect (fnc_quickMoveGroup, fnc_clearSelection).
 *
 * Sort is the storage's op "sort" (fnc_sortHolder, fnc_sendMoves), run where the container's root is local:
 * everyone who looks into it sees it sorted. The section's caption line has a button for it as well
 * (fnc_drawSection, fnc_drawWindow). Drop goes to the ground at the feet, or into the vehicle's cargo
 * while seated. A tile a move is under way for only shows what it is, and opens or closes.
 *
 * A tile in a container or one of the player's own slots: also what other mods add to CBA's item
 * context menu for the item (fnc_cbaOptions), set apart by a line.
 *
 * A kit of Enhanced First Aid Kits or Enhanced Utility Pouches: open or close it in a window of its own
 * and unpack everything in it (einv_compat_efak_fnc_menuChoices - only when that addon is loaded). A
 * tile in an open kit's window: inspect, put on, drop, sort the kit - the kit has no container for other
 * mods' options, and no arsenal. Only what lies on top under the mouse counts (fnc_updateHover,
 * fnc_topAt): a tile or free cells of a column under a kit window have no menu there.
 *
 * A tile or free cells of an ACE arsenal box: also open its arsenal (einv_arsenal_fnc_open - only when
 * that addon is loaded).
 *
 * A radio of the player's own - the radio slot, the uniform, vest or backpack, the long-range backpack
 * worn: also "Open radio" (the window steps aside for TFAR's or ACRE2's dialog and comes back,
 * einv_gui_fnc_stepAside) and "Use as active radio" for one that is not in use (einv_compat_tfar,
 * einv_compat_acre - whichever mod is loaded, through fnc_compatCollect). The dummy radio ACRE2 keeps in
 * the radio slot (einv_compat_acre_fnc_isFixedSlot) can only be inspected.
 *
 * A living person's gear the player may only look at (fnc_checkTouch): only what changes nothing of
 * theirs - inspect, open or close a uniform, vest, backpack or kit lying there; no sorting, which
 * everyone looking at them would see, and no choices of other mods.
 *
 * A window that attached (fnc_attach) gives its choices through the "menu" hook: they replace everything
 * above, an empty list means no menu at all.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Where to open it [x, y] - the tile or slot there is the one it is for - [] for the mouse <ARRAY>
 *    (default: [])
 *
 * Return Value:
 * A menu opened <BOOL>
 *
 * Example:
 * [_display] call einv_gui_fnc_contextMenu;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_at", [], [[]]]];

private _mouse = [_at, getMousePosition] select (_at isEqualTo []);

[_display, _mouse, true] call FUNC(updateHover);

// Where it opened, to open it there again when an option of another mod asks to stay open (fnc_cbaRun), and
// what for: its rows name a tile by its number in its grid, so fnc_redrawTiles closes the menu of a tile
// whose section it draws anew.
GVAR(menuAt) = _mouse;
GVAR(menuFor) = +GVAR(hover);

// A window that attached has its own menus (the "menu" hook): its choices replace the ones below; none, no
// menu at all. Nothing answered, the choices below.
private _hooked = ["menu", [_display]] call FUNC(hook);

if (!isNil "_hooked" && {_hooked isEqualType []}) exitWith {
    if (_hooked isEqualTo []) exitWith {false};

    [_display, _hooked, _mouse] call FUNC(openMenu);
    true
};

private _unit = GVAR(unit);
private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _choices = [];

private _fnc_name = {
    params ["_class"];
    [_class] call FUNC(itemName)
};

// The holder a grid stands for, with its root when the grid knows it. Only where the player may change
// it: a living person's as the settings say (fnc_checkTouch), a kit in their gear the same way
// (einv_compat_efak_fnc_checkTouch).
private _fnc_addSort = {
    params ["_grid", ["_separator", false]];

    private _kit = _grid getOrDefault ["kit", ""];
    private _container = _grid getOrDefault ["container", objNull];

    private _holder = if (_kit isEqualTo "") then {
        _grid getOrDefault ["holder", _container]
    } else {
        _grid getOrDefault ["holder", _grid getOrDefault ["layoutKey", ""]]
    };

    if (_holder isEqualTo "" || {_holder isEqualType objNull && {isNull _holder}}) exitWith {};

    private _why = if (_kit isEqualTo "") then {
        [_container, "items"] call FUNC(checkTouch)
    } else {
        if (isNil QEFUNC(compat_efak,checkTouch)) then {""} else {[_kit] call EFUNC(compat_efak,checkTouch)}
    };

    if (_why isNotEqualTo "") exitWith {};

    private _name = if (_kit isEqualTo "") then {[_container] call FUNC(containerName)} else {[_kit] call _fnc_name};

    // The same sort as the button on the section's caption line (fnc_sortHolder): a kit's grid by the kit's key.
    _choices pushBack [
        format [LLSTRING(Menu_Sort), _name], [_holder, _grid getOrDefault ["root", objNull]], {_this call FUNC(sortHolder)},
        createHashMapFromArray [["separator", _separator]]
    ];
};

// Everything in a section selected - in the inventory only, for the grids of the columns.
private _fnc_addSelectAll = {
    params ["_grid"];

    if (!(call FUNC(isInventoryMode)) || {_grid getOrDefault ["virtual", true]} || {(_grid getOrDefault ["window", ""]) isNotEqualTo ""}) exitWith {};
    if ((_grid getOrDefault ["side", ""]) isEqualTo "" || {isNull (_grid getOrDefault ["container", objNull])}) exitWith {};

    private _holder = _grid getOrDefault ["holder", objNull];

    if (_holder isEqualType objNull && {isNull _holder}) exitWith {};

    _choices pushBack [format [LLSTRING(Menu_SelectAll), [_grid get "container"] call FUNC(containerName)], [_holder], {_this call FUNC(selectSection)}];
};

// An ACE arsenal box: its arsenal, opened for the player once this window is closed. The arsenal
// addon may not be loaded - then there is no such choice.
private _fnc_addArsenal = {
    params ["_container"];

    if (!isNil QEFUNC(arsenal,canOpen) && {[_unit, _container] call EFUNC(arsenal,canOpen)}) then {
        _choices pushBack [LELSTRING(arsenal,Menu_OpenArsenal), [_unit, _container], {_this call EFUNC(arsenal,open)}];
    };
};

switch (GVAR(hover) param [0, ""]) do {
    case "tile": {
        GVAR(hover) params ["", "_gridIndex", "_tileIndex"];

        private _grid = _grids select _gridIndex;
        private _tile = (_grid get "tiles") select _tileIndex;
        private _from = _grid getOrDefault ["container", objNull];
        private _kit = _grid getOrDefault ["kit", ""];
        private _class = _tile getOrDefault ["class", ""];

        if (_tile getOrDefault ["hidden", false] || {isNull _from && {_kit isEqualTo ""}} || {_grid getOrDefault ["virtual", true]}) exitWith {};

        // On one of several selected tiles: what can be done with all of them.
        private _selected = if (call FUNC(isInventoryMode)) then {call FUNC(selectionTiles)} else {[]};

        if (count _selected >= 2 && {[_gridIndex, _tileIndex] in _selected}) exitWith {
            _choices pushBack [format [LLSTRING(Menu_MoveSelected), count _selected], [_selected], {_this call FUNC(quickMoveGroup)}];
            _choices pushBack [format [LLSTRING(Menu_DropSelected), count _selected], [_selected, true], {_this call FUNC(quickMoveGroup)}];
            _choices pushBack [LLSTRING(Menu_Deselect), [], {call FUNC(clearSelection)}];
        };

        _choices pushBack [
            LLSTRING(Menu_Inspect),
            [_class, _tile getOrDefault ["count", 1], _tile getOrDefault ["ammo", -1], _tile getOrDefault ["attachments", []]],
            {_this call FUNC(inspect)}
        ];

        // A move of it is under way: what it is, and opening or closing a uniform, vest or backpack it
        // is - nothing that would plan it a second time.
        private _inside = _tile getOrDefault ["container", objNull];

        if (_tile getOrDefault ["pending", false]) exitWith {
            if (!isNull _inside) then {
                private _isOpen = GVAR(opened) findIf {(_x select 1) isEqualTo _inside} >= 0;

                _choices pushBack [
                    format [[LLSTRING(Menu_OpenContainer), LLSTRING(Menu_CloseContainer)] select _isOpen, [_class] call _fnc_name],
                    [_gridIndex, _tileIndex],
                    {_this call FUNC(openNested)}
                ];
            };
        };

        // Equip, attach, load and drop take it out of where it lies - a living person's item only as the
        // settings say (fnc_checkTouch), also out of a kit lying in their gear, and never another living
        // player's kit (einv_compat_efak).
        private _touch = if (_kit isNotEqualTo "" && {!isNil QEFUNC(compat_efak,checkTouch)}) then {
            ([_kit] call EFUNC(compat_efak,checkTouch)) isEqualTo ""
        } else {
            ([_from, "items"] call FUNC(checkTouch)) isEqualTo ""
            && {isNil QEFUNC(compat_efak,checkTile) || {([_class, _from] call EFUNC(compat_efak,checkTile)) isEqualTo ""}}
        };

        if (_touch) then {
            // Put on: the slot it belongs to - attachments and magazines on each weapon that takes them.
            private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";

            if (_kind in ["muzzle", "optic", "rail", "bipod", "magazine", "grenade"]) then {
                private _parts = [[_kind], ["mag", "mag2"]] select (_kind in ["magazine", "grenade"]);

                {
                    private _base = _x;
                    private _weapon = (([_unit] call EFUNC(storage,getEquipment)) getOrDefault [_base, []]) param [0, ""];

                    {
                        private _slot = format ["%1_%2", _base, _x];

                        if (_weapon isNotEqualTo "" && {[_unit, _slot, _class] call EFUNC(storage,slotAccepts)}) then {
                            _choices pushBack [
                                format [[LLSTRING(Menu_AttachTo), LLSTRING(Menu_LoadInto)] select (_x in ["mag", "mag2"]), [_weapon] call _fnc_name],
                                [_slot, _from, _tile, _kit],
                                {_this call FUNC(doEquip)}
                            ];
                        };
                    } forEach _parts;
                } forEach ["primary", "handgun", "launcher"];
            } else {
                private _slot = [_unit, _class] call EFUNC(storage,slotFor);

                if (_slot isNotEqualTo "") then {
                    _choices pushBack [LLSTRING(Equip), [_slot, _from, _tile, _kit], {_this call FUNC(doEquip)}];
                };
            };

            // A magazine that is not full, in the player's own gear: all of its kind there repacked
            // (einv_magazines, when loaded).
            if (!isNil QEFUNC(magazines,menuChoices) && {_kit isEqualTo ""}) then {
                _choices append ([_class, _from, _tile getOrDefault ["ammo", 0]] call EFUNC(magazines,menuChoices));
            };

            // The hotbar: put it on a key, or take it off (einv_hotbar - only when that addon is loaded).
            if (call FUNC(isInventoryMode) && {!isNil QEFUNC(hotbar,menuChoices)}) then {
                _choices append ([_class, ["grid", _grid]] call EFUNC(hotbar,menuChoices));
            };

            // What a double click does: out of the player's gear into the loot, out of the loot into the
            // gear - the way for a backpack in a crate or a kit's tile, which a double click opens.
            if (call FUNC(isInventoryMode)) then {
                _choices pushBack [LLSTRING(Menu_MoveOver), [_gridIndex, _tileIndex], {_this call FUNC(quickMove)}];
            };

            if (_kit isNotEqualTo "" || {!([_from] call EFUNC(storage,isGroundHolder))}) then {
                _choices pushBack [LLSTRING(Drop), [_gridIndex, _tileIndex], {_this call FUNC(dropToGround)}];
            };
        };

        // A kit of Enhanced First Aid Kits or its pouches: open it in a window of its own, unpack it.
        if (!isNil QEFUNC(compat_efak,menuChoices)) then {
            _choices append ([_gridIndex, _tileIndex] call EFUNC(compat_efak,menuChoices));
        };

        // A uniform, vest or backpack lying here: open it in the loot column, or close it.
        if (!isNull _inside) then {
            private _isOpen = GVAR(opened) findIf {(_x select 1) isEqualTo _inside} >= 0;

            _choices pushBack [
                format [[LLSTRING(Menu_OpenContainer), LLSTRING(Menu_CloseContainer)] select _isOpen, [_class] call _fnc_name],
                [_gridIndex, _tileIndex],
                {_this call FUNC(openNested)}
            ];
        };

        // A radio the player carries: open it, use it (einv_compat_tfar, einv_compat_acre). Not one in a kit.
        if (_kit isEqualTo "") then {
            private _carried = _from in [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];

            _choices append ([
                [QEFUNC(compat_tfar,menuChoices), QEFUNC(compat_acre,menuChoices)],
                [_class, _tile getOrDefault ["container", objNull], _carried, false]
            ] call FUNC(compatCollect));
        };

        // Inside a kit: its own grid is all there is to sort.
        if (_kit isNotEqualTo "") exitWith {
            [_grid] call _fnc_addSort;
        };

        // What other mods offer for the item where it lies, then the window's own again below a line - not
        // for a living person's item the player may only look at: those choices would change it.
        ([_grid] call FUNC(cbaTileTarget)) params ["_cbaSlot", "_cbaContainer"];

        private _cba = if (_touch) then {[call CBA_fnc_currentUnit, _cbaContainer, _class, _cbaSlot] call FUNC(cbaOptions)} else {[]};

        _choices append _cba;

        [_grid, _cba isNotEqualTo []] call _fnc_addSort;
        [_grid] call _fnc_addSelectAll;

        [_from] call _fnc_addArsenal;
    };
    case "slot": {
        private _record = (uiNamespace getVariable [QGVAR(slots), []]) select (GVAR(hover) select 1);
        private _slot = _record param [5, ""];
        private _owner = _record param [6, objNull];

        // A slot of the hotbar (einv_hotbar - only when that addon is loaded): clear it.
        if (call FUNC(isInventoryMode) && {(_record param [7, -1]) >= 0} && {!isNil QEFUNC(hotbar,stripMenu)}) then {
            _choices append ([_record select 7] call EFUNC(hotbar,stripMenu));
        };

        if (_slot isEqualTo "" || {isNull _owner} || {(_record param [1, ""]) isEqualTo ""}) exitWith {};

        private _worn = [_owner, _slot] call EFUNC(storage,getSlot);

        _choices pushBack [
            LLSTRING(Menu_Inspect),
            [_record param [1, ""], 1, _worn getOrDefault ["ammo", -1], _worn getOrDefault ["attachments", []]],
            {_this call FUNC(inspect)}
        ];

        // The radio slot ACRE2 keeps for itself: nothing to do with it but look (einv_compat_acre).
        if (!isNil QEFUNC(compat_acre,isFixedSlot) && {[_owner, _slot] call EFUNC(compat_acre,isFixedSlot)}) exitWith {};

        // A radio of the player's own in a slot, or the long-range radio on their back: open it, use it.
        private _holder = [objNull, backpackContainer _owner] select (_slot isEqualTo "backpack");

        _choices append ([
            [QEFUNC(compat_tfar,menuChoices), QEFUNC(compat_acre,menuChoices)],
            [_record param [1, ""], _holder, _owner isEqualTo _unit, true]
        ] call FUNC(compatCollect));

        // What a living person wears comes off only as the settings say (fnc_checkTouch) - else inspect only.
        if (([_owner, "worn"] call FUNC(checkTouch)) isNotEqualTo "") exitWith {};

        _choices pushBack [LLSTRING(Menu_TakeOff), [_owner, _slot], {_this call FUNC(quickUnequip)}];
        _choices pushBack [LLSTRING(Drop), [_owner, _slot], {
            params ["_owner", "_slot"];
            [_owner, _slot, "ground", []] call FUNC(doUnequip);
        }];

        // A magazine loaded in one of the player's weapons: all of its kind in the gear repacked, the loaded
        // one stays as it is (einv_magazines, when loaded).
        if (!isNil QEFUNC(magazines,menuChoices) && {_owner isEqualTo _unit} && {_slot in ["primary_mag", "primary_mag2", "handgun_mag", "launcher_mag"]}) then {
            _choices append ([_record param [1, ""], _owner] call EFUNC(magazines,menuChoices));
        };

        // A weapon: each of its parts on its own.
        if (_slot in ["primary", "handgun", "launcher"]) then {
            private _weapon = ([_owner] call EFUNC(storage,getEquipment)) getOrDefault [_slot, []];

            {
                private _part = _weapon param [_forEachIndex + 1, ""];
                private _class = if (_part isEqualType []) then {_part param [0, ""]} else {_part};

                if (_class isNotEqualTo "") then {
                    _choices pushBack [
                        format [LLSTRING(Menu_Detach), [_class] call _fnc_name],
                        [_owner, format ["%1_%2", _slot, _x]],
                        {_this call FUNC(quickUnequip)}
                    ];
                };
            } forEach ["muzzle", "rail", "optic", "mag", "mag2", "bipod"];
        };

        // What other mods offer for the item in the slot - the player's own slots only.
        ([_owner, _slot] call FUNC(cbaSlotTarget)) params ["_cbaSlot", "_cbaContainer"];

        _choices append ([call CBA_fnc_currentUnit, _cbaContainer, _record param [1, ""], _cbaSlot] call FUNC(cbaOptions));
    };
    default {
        // Free cells of a container: sort it - those of the topmost layer there, a kit window's own over a
        // column's.
        private _layer = [_mouse] call FUNC(topAt);
        private _grid = (_grids select {
            (_x getOrDefault ["window", ""]) isEqualTo _layer && {([_x, _mouse] call FUNC(screenToCell)) isNotEqualTo []}
        }) param [0, createHashMap];
        private _container = _grid getOrDefault ["container", objNull];

        if (_grid getOrDefault ["virtual", true]) exitWith {};

        // Free cells of an open kit's window: sort the kit.
        if ((_grid getOrDefault ["kit", ""]) isNotEqualTo "") exitWith {
            [_grid] call _fnc_addSort;
        };

        if (isNull _container) exitWith {};

        [_grid] call _fnc_addSort;
        [_grid] call _fnc_addSelectAll;

        [_container] call _fnc_addArsenal;
    };
};

if (_choices isEqualTo []) exitWith {false};

[_display, _choices, _mouse] call FUNC(openMenu);
true
