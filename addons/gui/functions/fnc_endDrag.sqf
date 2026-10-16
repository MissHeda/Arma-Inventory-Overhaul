#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The mouse button let go of a dragged item. Where the footprint was green it is asked for: a tile
 * moves to its cells (fnc_applyMove) - as many of a stack as the wheel left, the way round it was held
 * - or is put on in a slot (fnc_doEquip), a magazine dropped on a weapon loaded, an attachment put on,
 * also let go anywhere over the equipment column (the slot that takes it, fnc_updateDrag) or, a uniform,
 * vest or backpack, on the storage column off its grids; a slot's item
 * comes off onto the cells (fnc_doUnequip), or onto another unit's same slot, which gives back what it
 * wore there (fnc_doSwap). Outside every panel it goes on the ground;
 * anywhere else it goes back, saying why when it did not fit (fnc_flashHint). First of all
 * what lifting it previewed about weight is put back (fnc_clearWeightPreview).
 *
 * Into, out of and between kits of Enhanced First Aid Kits - the grids of their windows and their tiles -
 * it goes through that addon (einv_compat_efak_fnc_drop, when loaded): two kits' grids both have no
 * container, so they are told apart by their kit before anything compares containers. Where it lands is
 * only ever what lay on top under the mouse (fnc_updateDrag).
 *
 * Onto a slot of the hotbar (einv_hotbar - only when that addon is loaded) nothing moves: the item's class
 * is put on that key.
 *
 * Where the storage keeps separate stacks (einv_storage_stackSplits), what is let go on a free cell lies
 * there as a stack of its own: it does not join a stack of its class elsewhere in the container, and part
 * of a stack let go in the container it lies in is split off onto the cell (fnc_applyMove, "separate").
 * What is let go onto a stack of its own class that has room joins that very stack, as many as fit (the
 * target's plan says merge, fnc_swapPlan; "mergeInto"), the rest stays where it lay. Quick move and Take
 * all still fill partial stacks.
 *
 * Onto a tile that lies there, where the footprint showed a swap (the target's 10th element, fnc_swapPlan):
 * the two tiles change places in one transaction (fnc_applySwap) - the dragged one onto the cell it was let
 * go on, the other onto the cell the dragged one came from.
 *
 * Onto a partly filled magazine of its kind (einv_magazines - only when that addon is loaded) nothing moves
 * either: the two are repacked in the window (einv_magazines_fnc_startPair), which says in the hint why not
 * when it cannot be (a refusal above, with its reason, never gets here).
 *
 * A window that attached (fnc_attach) is asked first where the item was let go (the "drop" hook, told the
 * target as the drag found it): what is dragged out of one of its source grids and what is let go on one of
 * its zones is ended by it alone, whatever it answers.
 *
 * Tiles dragged together (GVAR(dragGroup), fnc_groupMode) go where the footprint said: keeping their
 * arrangement (the ones that stay in their holder laid down at once), packed into the container (what
 * fits moves, the rest stays and the hint says how many), one after the other into a kit, or onto the
 * ground (fnc_quickMoveGroup).
 *
 * Every move is a transaction now (fnc_sendMoves): nothing shows in its new place before it got there.
 * A tile that went on its way stays faded where it lay and cannot be lifted again, the cells it goes to
 * are outlined (fnc_drawPending); where it landed lights up once the answer is finished (fnc_onFrame,
 * fnc_afterAction).
 *
 * With einv_gui_debugTiming on, the RPT gets one line for the drag before anything else: "timing: drag 0.04 ms
 * avg, 1.20 ms max over 140 frames (start 2.1 ms; slowest frame: ...)" - the lift, and what its frames cost
 * (fnc_logDrag, fnc_startDrag, fnc_updateDrag).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_gui_fnc_endDrag;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

// For the tester's numbers (einv_gui_debugTiming): the line of this drag (fnc_logDrag - a build and the window
// closing write it too, as they end a drag without this).
call FUNC(logDrag);

// What lifting it showed about weight goes first.
[] call FUNC(clearWeightPreview);

ctrlDelete (uiNamespace getVariable [QGVAR(dragGhost), controlNull]);
ctrlDelete (uiNamespace getVariable [QGVAR(dragFootprint), controlNull]);
ctrlDelete (uiNamespace getVariable [QGVAR(dragCounter), controlNull]);
ctrlDelete (uiNamespace getVariable [QGVAR(dragSwapFootprint), controlNull]);
uiNamespace setVariable [QGVAR(dragSwapFootprint), controlNull];
uiNamespace setVariable [QGVAR(dragGhost), controlNull];
uiNamespace setVariable [QGVAR(dragFootprint), controlNull];
uiNamespace setVariable [QGVAR(dragCounter), controlNull];
uiNamespace setVariable [QGVAR(dragScroll), []];

// The lit slots' highlights are kept for the next drag (fnc_glowSlot): only hidden.
{
    if (!isNull _x) then {_x ctrlShow false};
} forEach (uiNamespace getVariable [QGVAR(dragGlow), []]);
uiNamespace setVariable [QGVAR(dragGlow), []];

// The footprints and pictures of a group, and which tiles it was.
{ctrlDelete _x} forEach (uiNamespace getVariable [QGVAR(dragFootprints), []]);
{ctrlDelete (_x select 0)} forEach (uiNamespace getVariable [QGVAR(dragGhosts), []]);
{ctrlDelete _x} forEach (uiNamespace getVariable [QGVAR(dragShapes), []]);
uiNamespace setVariable [QGVAR(dragFootprints), []];
uiNamespace setVariable [QGVAR(dragShapes), []];
uiNamespace setVariable [QGVAR(dragGhosts), []];

private _group = GVAR(dragGroup);
GVAR(dragGroup) = [];

private _entry = uiNamespace getVariable [QGVAR(dragEntry), createHashMap];
uiNamespace setVariable [QGVAR(dragEntry), createHashMap];

GVAR(press) params ["_sourceIndex", "_tileIndex", "", "", "", "_slotSource"];
GVAR(dragTarget) params [["_kind", ""], ["_targetIndex", -1], ["_col", 0], ["_row", 0], ["_fits", false], ["_reason", ""], ["_targetSlot", ""], ["_place", true], ["_targetUnit", objNull], ["_swap", []]];
GVAR(dragSize) params ["_w", "_h"];

// Which way round it is held (fnc_rotateDrag): 1 turned a quarter clockwise - a shaped item in a square
// box says so by this alone.
private _rot = GVAR(dragRot);

GVAR(press) = [];
GVAR(dragging) = false;
GVAR(dragTarget) = [];

{
    _x ctrlSetFade 0;
    _x ctrlCommit 0;
} forEach (_entry getOrDefault ["controls", []]);

{
    private _lifted = ((uiNamespace getVariable [QGVAR(grids), []]) param [_x select 0, createHashMap]) getOrDefault ["tiles", []];

    {
        _x ctrlSetFade 0;
        _x ctrlCommit 0;
    } forEach ((_lifted param [_x select 1, createHashMap]) getOrDefault ["controls", []]);
} forEach _group;

if (GVAR(filter) isNotEqualTo "") then {
    call FUNC(applyFilter);
};

// The hint goes back to what the mouse is on - a reason why not, below, writes over it.
[_display, getMousePosition, true] call FUNC(updateHover);

if (count _entry == 0 || {_kind isEqualTo ""}) exitWith {};

// How many of a stack go: what the wheel left (fnc_onMouseZ), -1 for all of it.
private _stack = _entry getOrDefault ["count", 1];
private _count = [-1, GVAR(dragCount)] select (GVAR(dragCount) < _stack);

if (!_fits) exitWith {
    [_reason] call FUNC(flashHint);
};

private _grids = uiNamespace getVariable [QGVAR(grids), []];

// The source grid - none for a slot's item, whose index is -1: never looked up then.
private _fromGrid = if (_slotSource isEqualTo []) then {_grids param [_sourceIndex, createHashMap]} else {createHashMap};
private _fromBox = _fromGrid getOrDefault ["container", objNull];
private _fromKit = _fromGrid getOrDefault ["kit", ""];

// A window that attached has the first word on where it was let go (the "drop" hook): true, it has done it
// all. What comes from a source grid (ACE's list in the Arsenal panel) is always its to end, whatever it answers -
// there is no container behind that tile to move from -, and a zone is nothing but its own.
private _handled = ["drop", [_kind, _sourceIndex, _tileIndex, _slotSource, _entry, _count, _targetIndex, _col, _row, _w, _h, _targetSlot, _place, _rot, _swap], false] call FUNC(hook);

if (
    _handled isEqualTo true || {(_fromGrid getOrDefault ["source", ""]) isNotEqualTo ""} || {_kind isEqualTo "zone"}
) exitWith {};

// Onto the hotbar: the class goes on that key, nothing moves (the drag asked whether it may already).
if (_kind isEqualTo "hotbar") exitWith {
    if (!isNil QEFUNC(hotbar,bind)) then {
        [_targetIndex, _entry get "class", [], true] call EFUNC(hotbar,bind);
    };
};

// Whether it was asked for (fnc_sendMoves) - a refusal before that says why itself.
private _sent = call {
    // Several tiles together: onto the ground, or where fnc_groupMode planned it (the plan is kept under the
    // key the drag target carries in the place of a slot's id).
    if (_group isNotEqualTo []) exitWith {
        if (_kind isEqualTo "ground") exitWith {
            ([_group, true] call FUNC(quickMoveGroup)) isEqualTo true
        };

        private _answer = if (_kind isEqualTo "group") then {GVAR(dragRoom) get _targetSlot} else {nil};

        if (isNil "_answer") exitWith {false};

        _answer params ["_mode", "_data", "", "_total"];

        private _target = _grids param [_targetIndex, createHashMap];

        switch (_mode) do {
            case "keep": {
                // Every tile to its cell, with the size it lies in.
                private _holder = _target getOrDefault ["holder", objNull];
                private _root = _target getOrDefault ["root", objNull];
                private _block = _target getOrDefault ["block", 0];
                private _moving = false;
                private _assigned = [];

                {
                    _x params ["_groupGrid", "_groupTile", "_cellCol", "_cellRow"];

                    private _from = _grids param [_groupGrid, createHashMap];
                    private _tile = (_from getOrDefault ["tiles", []]) param [_groupTile, createHashMap];

                    // Where it lies already, in the holder it lies in: nothing to do for it.
                    if (
                        (_from getOrDefault ["holder", objNull]) isNotEqualTo _holder || {(_tile get "col") != _cellCol}
                        || {(_tile get "row") != _cellRow} || {(_from getOrDefault ["block", 0]) != _block}
                    ) then {
                        _moving = true;
                    };

                    _tile set ["holder", _from getOrDefault ["holder", objNull]];
                    _tile set ["root", _from getOrDefault ["root", objNull]];

                    _assigned pushBack [_tile, _holder, _root, [
                        _cellCol, _cellRow, _block, _tile get "w", _tile get "h", parseNumber (_tile getOrDefault ["rotated", false])
                    ]];
                } forEach _data;

                _moving && {[_assigned, _total] call FUNC(sendPlan)}
            };
            case "pack": {
                _data params ["_assigned"];

                [_assigned, _total] call FUNC(sendPlan)
            };
            case "kit": {
                // The kit decides tile by tile, in order, in this one frame (einv_compat_efak).
                if (isNil QEFUNC(compat_efak,drop)) exitWith {false};

                private _kitTile = (_target getOrDefault ["tiles", []]) param [_data param [0, -1], createHashMap];
                private _any = false;

                {
                    private _from = _grids param [_x select 0, createHashMap];
                    private _tile = (_from getOrDefault ["tiles", []]) param [_x select 1, createHashMap];
                    private _source = [_from getOrDefault ["container", objNull], ""];

                    private _done = if (count _kitTile > 0) then {
                        [_source, [_target getOrDefault ["container", objNull], _kitTile get "class"], _tile, -1, [], []] call EFUNC(compat_efak,drop)
                    } else {
                        [_source, [_target getOrDefault ["container", objNull], _target getOrDefault ["kit", ""]], _tile, -1, [], []] call EFUNC(compat_efak,drop)
                    };

                    if (_done isEqualTo true) then {
                        _any = true;
                    };
                } forEach _group;

                _any
            };
            default {false};
        }
    };

    // Onto a magazine of its kind: the two are repacked (einv_magazines), nothing is moved here. Its tile
    // index travels in the column's place.
    if (_kind isEqualTo "repack") exitWith {
        private _grid = _grids param [_targetIndex, createHashMap];
        private _under = (_grid getOrDefault ["tiles", []]) param [_col, createHashMap];

        if (!isNil QEFUNC(magazines,startPair) && {count _under > 0}) then {
            [_fromGrid, _entry, _grid, _under] call EFUNC(magazines,startPair);
        };

        false
    };

    // Onto a kit's tile: into that kit (einv_compat_efak). Its tile index travels in the column's place.
    if (_kind isEqualTo "kitTile") exitWith {
        private _grid = _grids param [_targetIndex, createHashMap];
        private _kitTile = (_grid getOrDefault ["tiles", []]) param [_col, createHashMap];

        if (isNil QEFUNC(compat_efak,drop) || {count _kitTile == 0}) exitWith {false};

        ([[_fromBox, _fromKit], [_grid getOrDefault ["container", objNull], _kitTile get "class"], _entry, _count, [], _slotSource] call EFUNC(compat_efak,drop)) isEqualTo true
    };

    // Onto the ground - the server finds the pile at the feet or makes one, or a seated player's vehicle
    // takes it (fnc_dropToGround, fnc_doUnequip): this machine never picks a pile itself.
    if (_kind isEqualTo "ground") exitWith {
        if (_slotSource isEqualTo []) exitWith {
            ([_sourceIndex, _tileIndex, _count] call FUNC(dropToGround)) isEqualTo true
        };

        _slotSource params ["_unit", "_slot"];

        ([_unit, _slot, "ground", []] call FUNC(doUnequip)) isEqualTo true
    };

    if (_kind isEqualTo "slot") exitWith {
        // The slot it goes in - on a weapon card that of the part a magazine or attachment takes.
        if (_targetSlot isEqualTo "" && {_targetIndex >= 0}) then {
            _targetSlot = ((uiNamespace getVariable [QGVAR(slots), []]) param [_targetIndex, []]) param [5, ""];
        };

        // Worn gear onto another unit's slot: the two exchange it (fnc_doSwap).
        if (_slotSource isNotEqualTo []) exitWith {
            ([_slotSource, _targetUnit, _targetSlot] call FUNC(doSwap)) isEqualTo true
        };

        ([_targetSlot, _fromBox, _entry, _fromKit] call FUNC(doEquip)) isEqualTo true
    };

    private _target = _grids param [_targetIndex, createHashMap];

    if (count _target == 0) exitWith {false};

    private _to = _target getOrDefault ["container", objNull];
    private _toKit = _target getOrDefault ["kit", ""];

    // Onto a tile that lies there, as the footprint showed: the two swap places (fnc_swapPlan).
    if (_swap isNotEqualTo [] && {_slotSource isEqualTo []}) exitWith {
        _swap params ["_indexOther", "_cellEntry", "_cellOther", ["_merge", false], ["_mergeCount", 0]];

        private _other = (_target getOrDefault ["tiles", []]) param [_indexOther, createHashMap];

        // Onto a stack of its own class: as many as fit join it, the rest stays where it lay.
        if (_merge) exitWith {
            private _mergeAll = _mergeCount >= _stack || {_mergeCount < 1};

            ([_fromBox, _to, _entry, [_mergeCount, -1] select _mergeAll, [], createHashMapFromArray [
                ["mergeInto", [_other get "col", _other get "row", _other getOrDefault ["block", _target getOrDefault ["block", 0]]]]
            ]] call FUNC(applyMove)) isEqualTo true
        };

        ([_fromGrid, _target, _entry, _other, _cellEntry, _cellOther] call FUNC(applySwap)) isEqualTo true
    };

    // The cell, with the size it lies in there - turned or not. On a taken cell of a kit's grid none:
    // its layout finds one.
    private _cell = [[], [_col, _row, _target getOrDefault ["block", 0], _w, _h, _rot]] select _place;

    // Dropped where it lies already, the same way round.
    if (
        _slotSource isEqualTo [] && {_targetIndex == _sourceIndex} && {_col == (_entry get "col")} && {_row == (_entry get "row")}
        && {_w == (_entry get "w")} && {_h == (_entry get "h")} && {_rot == (parseNumber (_entry getOrDefault ["rotated", false]))}
    ) exitWith {false};

    // Into, out of or between kits (einv_compat_efak) - before the slot's item and before containers are
    // compared: two kits' grids both have none. Part of a stack within the kit it lies in changes nothing.
    if (_toKit isNotEqualTo "" || {_fromKit isNotEqualTo ""}) exitWith {
        if (_count > 0 && {_fromKit isEqualTo _toKit} && {_fromBox isEqualTo _to}) exitWith {false};
        if (isNil QEFUNC(compat_efak,drop)) exitWith {false};

        ([[_fromBox, _fromKit], [_to, _toKit], _entry, _count, _cell, _slotSource] call EFUNC(compat_efak,drop)) isEqualTo true
    };

    if (_slotSource isNotEqualTo []) exitWith {
        _slotSource params ["_unit", "_slot"];

        ([_unit, _slot, _to, _cell] call FUNC(doUnequip)) isEqualTo true
    };

    // On a cell of its own it lies as a stack of its own, where the storage keeps them apart.
    private _separate = _place && {missionNamespace getVariable [QEGVAR(storage,stackSplits), false]};

    // Part of a stack into the container it lies in changes nothing where a container holds a class as one.
    if (_count > 0 && {_fromBox isEqualTo _to} && {!_separate}) exitWith {false};

    ([_fromBox, _to, _entry, _count, _cell, createHashMapFromArray [["separate", _separate]]] call FUNC(applyMove)) isEqualTo true
};

// A refusal before it went out flashed its own reason.
if (!_sent) exitWith {};

// On its way: it stays where it lay, faded, and cannot be lifted again until the answer came; the cells
// it goes to are outlined (fnc_drawPending, which finds it by the moves in flight - its own record says
// so as well, for fnc_startDrag).
if (_slotSource isEqualTo [] && {_group isEqualTo []}) then {
    _entry set ["pending", true];

    {
        _x ctrlSetFade DRAG_SOURCE_FADE;
        _x ctrlCommit 0;
    } forEach (_entry getOrDefault ["controls", []]);
};

call FUNC(drawPending);
