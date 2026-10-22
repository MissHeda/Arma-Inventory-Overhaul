#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A move into, out of or between kits, for the window - a drag let go (einv_gui_fnc_endDrag), Ctrl+click
 * (einv_gui_fnc_quickMove, fnc_takeOut), the drop key and Drop (einv_gui_fnc_dropToGround). As many of a
 * stack as the drag counted, all of them or none.
 *
 * Checked here against what this machine sees, so a refusal says why at once and nothing is sent: what
 * the kit takes and has room for (fnc_canDrop), room in a container, the kits of others
 * (fnc_mayReach) and the window's rules for a living person's gear (einv_gui_fnc_checkTouch). Then it
 * becomes one move of the window's transactions (einv_gui_fnc_sendMoves): a kit is a holder of the
 * storage, "kit:" + its lowercase class, whose root is the root of the container it lies in
 * (fnc_holderRoot); its ops run at that root's authority (einv_storage_holderTypes "kit"), which checks
 * everything again against the kit as it is then:
 *   within one kit       - only where it lies changes, a whole tile onto a cell ("kitPlace")
 *   a slot into a kit    - taken off, then into the kit ("unequip")
 *   kit into kit         - "kitMove" when both lie under one root, else out of one and into the other
 *   container into a kit - out of the container, into the kit ("kitPut")
 *   kit into a container - out of the kit ("kitTake"), into the container - or onto the ground
 * What a kit or a container turns away by then goes back where it came from, else into the vehicle or
 * onto the ground (einv_storage_fnc_settle) - never lost, never doubled. The window shows the tiles
 * waiting until the answer and the new places arrived.
 *
 * Arguments:
 * 0: Where it comes from, [container, kit] - [objNull, ""] for a slot <ARRAY>
 * 1: Where it goes, [container, kit]: a kit's open grid [objNull, kit], a kit's tile [the container its
 *    tile lies in, kit], a container [container, ""], or the ground at the player's feet ["ground", ""]
 *    - seated, the vehicle's cargo <ARRAY>
 * 2: Entry - a tile's, or a slot's (einv_storage_fnc_getSlot) <HASHMAP>
 * 3: How many of a stack, -1 for all of it <NUMBER> (default: -1)
 * 4: Cell [col, row, compartment, w, h] it was dropped on, [] to let the layout find one <ARRAY>
 *    (default: [])
 * 5: The slot it comes from, [unit, slot id] - [] for a tile <ARRAY> (default: [])
 *
 * Return Value:
 * Sent <BOOL>
 *
 * Example:
 * [[backpackContainer player, ""], [objNull, "efak_IFAK_7"], _entry] call einv_compat_efak_fnc_drop;
 *
 * Public: No
 */

params [
    ["_source", [objNull, ""], [[]]],
    ["_target", [objNull, ""], [[]]],
    ["_entry", createHashMap, [createHashMap]],
    ["_count", -1, [0]],
    ["_cell", [], [[]]],
    ["_slotSource", [], [[]]]
];

_source params [["_from", objNull, [objNull]], ["_fromKit", "", [""]]];
_target params [["_to", objNull, [objNull, ""]], ["_toKit", "", [""]]];

// "ground": at the player's feet, or - seated - into the vehicle (einv_gui_fnc_sendMoves decides).
private _ground = "";

if (_to isEqualType "") then {
    _ground = _to;
    _to = objNull;
};

private _stack = _entry getOrDefault ["count", 1];
private _n = [_count, _stack] select (_count < 1 || {_count > _stack});
private _whole = _n >= _stack;

// What the move asks for: the whole tile as it lies where the op runs, or so many of it.
private _asked = [_n, -1] select _whole;

// A move of the window's transactions, with the answer flashing where it landed.
private _fnc_send = {
    params ["_move"];

    [[_move], createHashMapFromArray [["flash", true]]] call EFUNC(gui,sendMoves)
};

private _fnc_refuse = {
    params ["_why"];

    [_why] call EFUNC(gui,flashHint);
    false
};

// What the kit it comes out of holds before anything leaves it, for the packing-off rule
// (fnc_repackable): a kit opened before its contents reached this machine has no note of it yet
// (fnc_open), and what came out could not go back.
if (_fromKit isNotEqualTo "") then {
    [_fromKit] call FUNC(snapshot);
};

private _fromKey = "";
private _fromRoot = objNull;

if (_fromKit isNotEqualTo "") then {
    _fromKey = "kit:" + toLowerANSI _fromKit;
    _fromRoot = [_fromKey] call FUNC(holderRoot);
};

// ----- Within one kit: only where it lies changes - a whole tile, onto a cell -----
// Part of a stack, or the kit's own tile, changes nothing: a kit holds a class as one, as a container
// does.
if (_fromKit isNotEqualTo "" && {_fromKit == _toKit}) exitWith {
    if (_cell isEqualTo [] || {!_whole}) exitWith {false};
    if (isNull _fromRoot) exitWith {["Failed"] call _fnc_refuse};

    [createHashMapFromArray [
        ["kind", "move"], ["from", _fromKey], ["fromRoot", _fromRoot], ["entry", _entry], ["count", -1],
        ["to", _fromKey], ["toRoot", _fromRoot], ["cell", _cell]
    ]] call _fnc_send
};

// Nothing changes before the kits' contents are here (fnc_notReady).
private _wait = call FUNC(notReady);

if (_wait isNotEqualTo "") exitWith {[_wait] call _fnc_refuse};

// Out of a kit: only while the player may still reach it where it lies now (fnc_mayReach) - it was
// opened a while ago, and a soldier looted while down may be up again by now - and, in a living
// person's gear, as the settings for it say.
if (_fromKit isNotEqualTo "") then {
    private _fromWhere = ([_fromKit] call FUNC(locate)) select 1;

    _wait = switch (true) do {
        case (isNull _fromWhere || {isNull _fromRoot}): {"Failed"};
        case (!([_fromWhere] call FUNC(mayReach))): {LLSTRING(NotYours)};
        // In ACE Arsenal's window the kits tab's rules decide whether it lets things out, as for Remove there
        // (fnc_discard): "Remove only" does, a kit that follows the default contents does not (fnc_arsenalEditable).
        case (!([] call EFUNC(gui,isInventoryMode))): {[_fromKit, false] call FUNC(arsenalEditable)};
        default {[_fromWhere, "items"] call EFUNC(gui,checkTouch)};
    };
};

if (_wait isNotEqualTo "") exitWith {[_wait] call _fnc_refuse};

// In ACE Arsenal's window what Enhanced First Aid Kits' kits tab still has staged is written before a kit changes
// (fnc_arsenalFlush): the move is checked against the kit as that tab shows it, and nothing of the tab is replayed
// onto it afterwards.
if (!([] call EFUNC(gui,isInventoryMode)) && {_fromKit isNotEqualTo "" || {_toKit isNotEqualTo ""}}) then {
    [] call FUNC(arsenalFlush);
};

// ----- Into a kit -----
if (_toKit isNotEqualTo "") exitWith {
    // A kit's tile lies in the target's container, an open kit where the window found it.
    ([_toKit, [[], [_to, ""]] select (!isNull _to)] call FUNC(locate)) params ["_holder", "_where"];

    ([_source, _toKit, _entry, _count, _slotSource, _holder] call FUNC(canDrop)) params ["_fits", "_why"];

    if (!_fits) exitWith {[_why] call _fnc_refuse};
    if (isNull _where) exitWith {["Failed"] call _fnc_refuse};

    // Where the outermost kit lies, for a kit packed in kits - its own holder was reached already.
    if !([_where] call FUNC(mayReach)) exitWith {[LLSTRING(NotYours)] call _fnc_refuse};

    private _toKey = "kit:" + toLowerANSI _toKit;
    private _toRoot = [_where] call EFUNC(storage,rootOf);

    if (isNull _toRoot) exitWith {["Failed"] call _fnc_refuse};

    // Off one of the player's slots: taken off where the unit is local, then into the kit.
    if (_slotSource isNotEqualTo []) exitWith {
        _slotSource params [["_unit", objNull, [objNull]], ["_slot", "", [""]]];

        [createHashMapFromArray [
            ["kind", "unequip"], ["unit", _unit], ["slot", _slot], ["from", _unit], ["fromRoot", _unit],
            ["entry", _entry], ["count", 1], ["to", _toKey], ["toRoot", _toRoot], ["cell", _cell]
        ]] call _fnc_send
    };

    // Out of another kit - kitMove when both lie under one root.
    if (_fromKit isNotEqualTo "") exitWith {
        [createHashMapFromArray [
            ["kind", "move"], ["from", _fromKey], ["fromRoot", _fromRoot], ["entry", _entry], ["count", _asked],
            ["to", _toKey], ["toRoot", _toRoot], ["cell", _cell]
        ]] call _fnc_send
    };

    // Out of a container - also a living person's, whose machine takes it out by the settings for
    // their gear (einv_gui_fnc_personGuard).
    if (isNull _from) exitWith {false};

    private _fromBase = [_from] call EFUNC(storage,rootOf);

    if (isNull _fromBase) exitWith {["Failed"] call _fnc_refuse};

    [createHashMapFromArray [
        ["kind", "move"], ["from", _from], ["fromRoot", _fromBase], ["entry", _entry], ["count", _asked],
        ["to", _toKey], ["toRoot", _toRoot], ["cell", _cell]
    ]] call _fnc_send
};

// ----- Out of a kit, onto the ground -----
if (_fromKit isEqualTo "") exitWith {false};

if (_ground isNotEqualTo "") exitWith {
    [createHashMapFromArray [
        ["kind", "move"], ["from", _fromKey], ["fromRoot", _fromRoot], ["entry", _entry], ["count", _asked],
        ["to", _ground], ["toRoot", objNull], ["cell", []]
    ]] call _fnc_send
};

// ----- Out of a kit, into a container -----
if (isNull _to) exitWith {false};

// Into a living person's container only as the settings for their gear say.
private _toTouch = [_to, "items"] call EFUNC(gui,checkTouch);

if (_toTouch isNotEqualTo "") exitWith {[_toTouch] call _fnc_refuse};
if ([_to, _entry] call EFUNC(storage,backpackIntoBackpack)) exitWith {["NoBackpack"] call _fnc_refuse};

// Free cells are the only limit: nobody said where, so there has to be a free spot.
if (_cell isEqualTo [] && {!([_to, _entry] call EFUNC(storage,hasSpace))}) exitWith {
    ["NoRoom"] call _fnc_refuse
};

private _toRoot = [_to] call EFUNC(storage,rootOf);

if (isNull _toRoot) exitWith {["Failed"] call _fnc_refuse};

[createHashMapFromArray [
    ["kind", "move"], ["from", _fromKey], ["fromRoot", _fromRoot], ["entry", _entry], ["count", _asked],
    ["to", _to], ["toRoot", _toRoot], ["cell", _cell]
]] call _fnc_send
