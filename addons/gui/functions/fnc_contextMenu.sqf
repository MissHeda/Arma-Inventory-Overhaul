#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Right click on what the mouse is on: the choices for it, in a context menu (fnc_openMenu).
 *
 * Only what belongs to the thing under the mouse is in it. The moves have their own ways and no row
 * here: a double click moves a tile - or a whole selection - over (fnc_quickMove, fnc_quickMoveGroup),
 * G drops what is under the mouse or selected (fnc_dropToGround, fnc_quickMoveGroup), a drag moves
 * one tile or a selection anywhere, Ctrl+click takes a worn item off (fnc_quickUnequip), and the Sort
 * button on a section's caption line sorts its container (fnc_sortHolder, fnc_drawSection,
 * fnc_drawWindow).
 *
 * A tile: inspect it (fnc_inspect), put it on (or, for an attachment or magazine, on which of the
 * player's weapons), repack all magazines of its kind when it is a magazine that is not full in the
 * player's own gear (aio_magazines_fnc_menuChoices - only when that addon is loaded; the slot of a loaded
 * magazine has the row too), put it on the hotbar or take it off (aio_hotbar_fnc_menuChoices - only when that
 * addon is loaded), drop it, open it (a uniform, vest or backpack lying there in the loot column), select
 * everything in its container (fnc_selectSection). A slot: inspect it, drop it (to the ground - it does
 * not go into the player's own gear first, as Ctrl+click's take off does), and for a weapon take off each
 * of its attachments and its magazines on their own; a slot of the hotbar: clear it
 * (aio_hotbar_fnc_stripMenu). Free cells: select all in the container.
 *
 * On a tile of a selection of several nothing but deselect (fnc_clearSelection): what can be done with
 * all of them is a double click, a drag and Delete (fnc_quickMoveGroup).
 *
 * An action waiting for the hands (fnc_queueMoves) - a tinted tile, or a slot whose item is to come
 * off - has Cancel in its menu, after Inspect (and the container rows of a tile).
 *
 * Drop goes to the ground at the feet, or into the vehicle's cargo while seated. A tile a move is under
 * way for only shows what it is, and opens or closes.
 *
 * A tile in a container or one of the player's own slots: also what other mods add to CBA's item
 * context menu for the item (fnc_cbaOptions), set apart by a line.
 *
 * A kit of Enhanced First Aid Kits or Enhanced Utility Pouches: open or close it in a window of its own
 * and unpack everything in it (aio_compat_efak_fnc_menuChoices - only when that addon is loaded). A
 * tile in an open kit's window: inspect, put on, drop - the kit has no container for other mods'
 * options, and no arsenal; free cells there have no menu at all. Only what lies on top under the mouse
 * counts (fnc_updateHover, fnc_topAt): a tile or free cells of a column under a kit window have no menu
 * there.
 *
 * A tile or free cells of an ACE arsenal box: also open its arsenal (aio_arsenal_fnc_open - only when
 * that addon is loaded).
 *
 * A radio of the player's own - the radio slot, the uniform, vest or backpack, the long-range backpack
 * worn - not one lying in a container the settings "Use items from ..." close to it (aio_storage_fnc_useState)
 * and that it is not whitelisted for: also "Open radio" (the window steps aside for TFAR's or ACRE2's dialog and comes back,
 * aio_gui_fnc_stepAside) and "Use as active radio" for one that is not in use (aio_compat_tfar,
 * aio_compat_acre - whichever mod is loaded, through fnc_compatCollect). The dummy radio ACRE2 keeps in
 * the radio slot (aio_compat_acre_fnc_isFixedSlot) can only be inspected.
 *
 * A living person's gear the player may only look at (fnc_checkTouch): only what changes nothing of
 * theirs - inspect, open or close a uniform, vest, backpack or kit lying there; no sorting, which
 * everyone looking at them would see, and no choices of other mods.
 *
 * For whoever may open the setup wizard (aio_setup_fnc_canOpen - only when that addon is loaded), a last
 * row "Settings for <name>" on a tile, on a worn slot, on the box of an opened uniform, vest or backpack and on
 * the free cells of a crate's or vehicle's grid: it closes this window and opens the wizard at the page of
 * that item - the Containers page for what holds things (uniform, vest, backpack, crate, vehicle, kit), the
 * Items page for the rest - with the class picked (aio_setup_fnc_openFromGame, which takes the step's index:
 * found here by its id in aio_setup_steps, so a reordering of the pages does not matter).
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
 * [_display] call aio_gui_fnc_contextMenu;
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

// The class a "Settings for ..." row is for (see the header), the name it shows and the page of the wizard
// when the kind of the class does not say ("items" or "containers").
private _settingsClass = "";
private _settingsName = "";
private _settingsPage = "";

private _fnc_name = {
    params ["_class"];
    [_class] call FUNC(itemName)
};

// Everything in a section selected - in the inventory only, for the grids of the columns. Set apart by a
// line from what other mods' options put above it.
private _fnc_addSelectAll = {
    params ["_grid", ["_separator", false]];

    if (!(call FUNC(isInventoryMode)) || {_grid getOrDefault ["virtual", true]} || {(_grid getOrDefault ["window", ""]) isNotEqualTo ""}) exitWith {};
    if ((_grid getOrDefault ["side", ""]) isEqualTo "" || {isNull (_grid getOrDefault ["container", objNull])}) exitWith {};

    private _holder = _grid getOrDefault ["holder", objNull];

    if (_holder isEqualType objNull && {isNull _holder}) exitWith {};

    _choices pushBack [
        format [LLSTRING(Menu_SelectAll), [_grid get "container"] call FUNC(containerName)], [_holder], {_this call FUNC(selectSection)},
        createHashMapFromArray [["separator", _separator]]
    ];
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

        // On one of several selected tiles: nothing but letting go of the selection. Moving and dropping
        // them all is a double click, a drag and Delete (fnc_quickMoveGroup).
        private _selected = if (call FUNC(isInventoryMode)) then {call FUNC(selectionTiles)} else {[]};

        if (count _selected >= 2 && {[_gridIndex, _tileIndex] in _selected}) exitWith {
            _choices pushBack [LLSTRING(Menu_Deselect), [], {call FUNC(clearSelection)}];
        };

        _choices pushBack [
            LLSTRING(Menu_Inspect),
            [_class, _tile getOrDefault ["count", 1], _tile getOrDefault ["ammo", -1], _tile getOrDefault ["attachments", []], _from],
            {_this call FUNC(inspect)}
        ];

        _settingsClass = _class;

        // A move of it is under way: what it is, and opening or closing a uniform, vest or backpack it
        // is - nothing that would plan it a second time.
        private _inside = _tile getOrDefault ["container", objNull];

        if (_tile getOrDefault ["pending", false]) exitWith {
            // Waiting for the hands (fnc_queueMoves): it can be cancelled.
            if ((_tile getOrDefault ["queued", 0]) > 0) then {
                _choices pushBack [LLSTRING(Menu_CancelQueued), [_tile get "queued"], {_this call FUNC(cancelQueued)}];
            };

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
        // player's kit (aio_compat_efak).
        private _touch = if (_kit isNotEqualTo "" && {!isNil QEFUNC(compat_efak,checkTouch)}) then {
            ([_kit] call EFUNC(compat_efak,checkTouch)) isEqualTo ""
        } else {
            ([_from, "items"] call FUNC(checkTouch)) isEqualTo ""
            && {isNil QEFUNC(compat_efak,checkTile) || {([_class, _from] call EFUNC(compat_efak,checkTile)) isEqualTo ""}}
        };

        if (_touch) then {
            // Put on: the slot it belongs to - attachments and magazines on each weapon that takes them.
            private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";

            // A weapon lying here: its parts changed as on a worn one, in the attachments view (#56, fnc_drawInspect) - found again
            // by its cell (fnc_weaponTile).
            if (_kind in ["rifle", "handgun", "launcher"] && {_kit isEqualTo ""} && {!isNull _from}) then {
                _choices pushBack [
                    LLSTRING(Menu_Modify),
                    [
                        _class, 1, -1, _tile getOrDefault ["attachments", []], _from,
                        createHashMapFromArray [
                            ["container", _from],
                            ["cell", [_tile getOrDefault ["col", 0], _tile getOrDefault ["row", 0], _tile getOrDefault ["block", 0]]]
                        ],
                        true
                    ],
                    {_this call FUNC(inspect)}
                ];
            };

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
                } forEach ["primary", "handgun", "launcher", "primary2"];
            } else {
                private _slot = [_unit, _class] call EFUNC(storage,slotFor);

                if (_slot isNotEqualTo "") then {
                    _choices pushBack [LLSTRING(Equip), [_slot, _from, _tile, _kit], {_this call FUNC(doEquip)}];
                };
            };

            // A magazine that is not full, in the player's own gear: all of its kind there repacked
            // (aio_magazines, when loaded).
            if (!isNil QEFUNC(magazines,menuChoices) && {_kit isEqualTo ""}) then {
                _choices append ([_class, _from, _tile getOrDefault ["ammo", 0]] call EFUNC(magazines,menuChoices));
            };

            // The hotbar: put it on a key, or take it off (aio_hotbar - only when that addon is loaded).
            if (call FUNC(isInventoryMode) && {!isNil QEFUNC(hotbar,menuChoices)}) then {
                _choices append ([_class, ["grid", _grid]] call EFUNC(hotbar,menuChoices));
            };

            // Moving it over is a double click (fnc_quickMove) or a drag: no row for it here.
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

        // A radio the player carries: open it, use it (aio_compat_tfar, aio_compat_acre). Not one in a kit. The settings
        // "Use items from ..." are about using things up: a radio in the backpack is opened as TFAR and ACRE2 open it.
        if (_kit isEqualTo "") then {
            private _carried = _from in [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];

            _choices append ([
                [QEFUNC(compat_tfar,menuChoices), QEFUNC(compat_acre,menuChoices)],
                [_class, _tile getOrDefault ["container", objNull], _carried, false]
            ] call FUNC(compatCollect));
        };

        // Inside a kit: the kit has no container for other mods' options, no selection and no arsenal.
        if (_kit isNotEqualTo "") exitWith {};

        // What other mods offer for the item where it lies, then the window's own again below a line - not
        // for a living person's item the player may only look at: those choices would change it.
        ([_grid] call FUNC(cbaTileTarget)) params ["_cbaSlot", "_cbaContainer"];

        private _cba = if (_touch) then {[call CBA_fnc_currentUnit, _cbaContainer, _class, _cbaSlot] call FUNC(cbaOptions)} else {[]};

        _choices append _cba;

        [_grid, _cba isNotEqualTo []] call _fnc_addSelectAll;

        [_from] call _fnc_addArsenal;
    };
    case "slot": {
        private _record = (uiNamespace getVariable [QGVAR(slots), []]) select (GVAR(hover) select 1);
        private _slot = _record param [5, ""];
        private _owner = _record param [6, objNull];

        // A slot of the hotbar (aio_hotbar - only when that addon is loaded): clear it.
        if (call FUNC(isInventoryMode) && {(_record param [7, -1]) >= 0} && {!isNil QEFUNC(hotbar,stripMenu)}) then {
            _choices append ([_record select 7] call EFUNC(hotbar,stripMenu));
        };

        // The box of a uniform, vest or backpack opened from inside a container, and a worn slot: the setup
        // wizard's page for the item.
        if ((_record param [7, -1]) < 0) then {
            _settingsClass = _record param [1, ""];
        };

        // The player's own backpack slot with BackpackOnChest loaded (aio_compat_boc): to the chest, back onto the
        // back or swapped with the pack on the chest - also on the empty slot, where the pack on the chest goes.
        if (_slot isEqualTo "backpack" && {_owner isEqualTo _unit} && {!isNil QEFUNC(compat_boc,menuChoices)}) then {
            _choices append ([_owner] call EFUNC(compat_boc,menuChoices));
        };

        if (_slot isEqualTo "" || {isNull _owner} || {(_record param [1, ""]) isEqualTo ""}) exitWith {};

        private _worn = [_owner, _slot] call EFUNC(storage,getSlot);

        // One of the player's own weapons: Attachments opens it with its parts to change (#56, fnc_drawHotspots); Inspect only looks.
        private _ownWeapon = _owner isEqualTo _unit && {_slot in ["primary", "handgun", "launcher", "primary2"]};

        _choices pushBack [
            LLSTRING(Menu_Inspect),
            [_record param [1, ""], 1, _worn getOrDefault ["ammo", -1], _worn getOrDefault ["attachments", []]],
            {_this call FUNC(inspect)}
        ];

        if (_ownWeapon) then {
            _choices pushBack [
                LLSTRING(Menu_Modify),
                [_record param [1, ""], 1, -1, _worn getOrDefault ["attachments", []], objNull, _slot, true],
                {_this call FUNC(inspect)}
            ];
        };

        // Waiting to be taken off (fnc_queueMoves): it can be cancelled, and nothing else is offered for it.
        private _queuedId = [_owner, _slot] call FUNC(queuedSlot);

        if (_queuedId > 0) exitWith {
            _choices pushBack [LLSTRING(Menu_CancelQueued), [_queuedId], {_this call FUNC(cancelQueued)}];
        };

        // The radio slot ACRE2 keeps for itself: nothing to do with it but look (aio_compat_acre).
        if (!isNil QEFUNC(compat_acre,isFixedSlot) && {[_owner, _slot] call EFUNC(compat_acre,isFixedSlot)}) exitWith {};

        // A radio of the player's own in a slot, or the long-range radio on their back: open it, use it.
        private _holder = [objNull, backpackContainer _owner] select (_slot isEqualTo "backpack");

        _choices append ([
            [QEFUNC(compat_tfar,menuChoices), QEFUNC(compat_acre,menuChoices)],
            [_record param [1, ""], _holder, _owner isEqualTo _unit, true]
        ] call FUNC(compatCollect));

        // What a living person wears comes off only as the settings say (fnc_checkTouch) - else inspect only.
        if (([_owner, "worn"] call FUNC(checkTouch)) isNotEqualTo "") exitWith {};

        // Drop only - onto the ground. "Take off", which put it into the player's own gear first, is
        // Ctrl+click on the slot (fnc_quickUnequip).
        _choices pushBack [LLSTRING(Drop), [_owner, _slot], {
            params ["_owner", "_slot"];
            [_owner, _slot, "ground", []] call FUNC(doUnequip);
        }];

        // The primary and the second primary on the back (a two-primary mod, aio_storage_fnc_secondPrimary) trade
        // places - what that mod's own key does, without the hands having to be free of anything else.
        if (_slot in ["primary", "primary2"]) then {
            private _other = ["primary2", "primary"] select (_slot isEqualTo "primary2");

            if (([[_owner, _slot], _owner, _other] call FUNC(canSwap)) isEqualTo "") then {
                _choices pushBack [
                    [LLSTRING(Menu_SwapSecondPrimary), LLSTRING(Menu_SwapPrimary)] select (_slot isEqualTo "primary2"),
                    [[_owner, _slot], _owner, _other],
                    {_this call FUNC(doSwap)}
                ];
            };
        };

        // A magazine loaded in one of the player's weapons: all of its kind in the gear repacked, the loaded
        // one stays as it is (aio_magazines, when loaded).
        if (!isNil QEFUNC(magazines,menuChoices) && {_owner isEqualTo _unit} && {_slot in ["primary_mag", "primary_mag2", "handgun_mag", "launcher_mag"]}) then {
            _choices append ([_record param [1, ""], _owner] call EFUNC(magazines,menuChoices));
        };

        // A weapon: each of its parts on its own.
        if (_slot in ["primary", "handgun", "launcher", "primary2"]) then {
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
        // Free cells of a container: select all in it - those of the topmost layer there, a kit window's own
        // over a column's. Nothing for the free cells of an open kit's window.
        private _layer = [_mouse] call FUNC(topAt);
        private _grid = (_grids select {
            (_x getOrDefault ["window", ""]) isEqualTo _layer && {([_x, _mouse] call FUNC(screenToCell)) isNotEqualTo []}
        }) param [0, createHashMap];
        private _container = _grid getOrDefault ["container", objNull];

        if (_grid getOrDefault ["virtual", true]) exitWith {};
        if ((_grid getOrDefault ["kit", ""]) isNotEqualTo "") exitWith {};
        if (isNull _container) exitWith {};

        [_grid] call _fnc_addSelectAll;

        [_container] call _fnc_addArsenal;

        // A crate or a vehicle: its grid in the wizard. Not the soldier's own containers, which are items there, and
        // not the ground.
        if (isNull (([_container] call EFUNC(storage,getOwner)) select 0) && {!([_container] call EFUNC(storage,isGroundHolder))}) then {
            _settingsClass = typeOf _container;
            _settingsName = [_container] call FUNC(containerName);
            _settingsPage = "containers";
        };
    };
};

// The setup wizard, for whoever may open it: at the page of this class (aio_setup).
if (
    _settingsClass isNotEqualTo "" && {call FUNC(isInventoryMode)} && {!isNil QEFUNC(setup,openFromGame)}
    && {call (missionNamespace getVariable [QEFUNC(setup,canOpen), {false}])}
) then {
    private _kind = ([_settingsClass] call EFUNC(items,getInfo)) getOrDefault ["kind", ""];
    private _id = _settingsPage;

    if (_id isEqualTo "") then {
        _id = ["items", "containers"] select (_kind in ["uniform", "vest", "backpack", "crate", "vehicle", "kit"]);
    };

    private _step = (missionNamespace getVariable [QEGVAR(setup,steps), []]) findIf {(_x param [0, ""]) isEqualTo _id};

    if (_settingsName isEqualTo "") then {
        _settingsName = [_settingsClass] call _fnc_name;
    };

    if (_step >= 0) then {
        _choices pushBack [
            format [LLSTRING(Menu_Settings), _settingsName], [_step, _settingsClass], {_this call EFUNC(setup,openFromGame)},
            createHashMapFromArray [["separator", _choices isNotEqualTo []]]
        ];
    };
};

if (_choices isEqualTo []) exitWith {false};

[_display, _choices, _mouse] call FUNC(openMenu);
true
