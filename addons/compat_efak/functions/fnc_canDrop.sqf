#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether what is dragged may go into a kit, and if not why - for the footprint while dragging
 * (aio_gui_fnc_updateDrag), Ctrl+click (aio_gui_fnc_quickMove) and the move itself (fnc_drop). Asked
 * in this order, the first answer wins:
 *   from that kit itself      - yes within its open grid, a rearrange; no onto its own tile, where
 *                               it lies already ("NoRoom")
 *   someone else's kit        - only as Enhanced First Aid Kits allows it (fnc_mayReach)
 *   from a body's slot        - no: only the player's own gear goes straight into a kit
 *   a living person's gear    - out of their container, or into a kit lying in their gear, only as
 *                               the window's settings for them say and while they are in reach
 *                               (aio_gui_fnc_checkTouch, fnc_checkTouch)
 *   a uniform, vest or
 *   backpack with contents    - no: their contents would be lost, the kit keeps only the class
 *   an empty magazine         - no: the kit would hand it back full (fnc_changeKit)
 *   packing switched off     - only what came out of this kit since the window was opened
 *                               (fnc_repackable), as that mod's kit window allows; in ACE Arsenal's
 *                               window instead whether the kit may be filled there and, out of
 *                               another kit, whether that one lets things out (fnc_arsenalEditable)
 *   the kit                   - what it takes and has room for (fnc_canPack): that mod's
 *                               capacity, or the free cells of a grid a rule or its config gives
 *                               it (fnc_roomMode)
 * Its reasons are that mod's words wherever it has them.
 *
 * Arguments:
 * 0: Where it comes from, [container, kit] - [objNull, ""] for a slot <ARRAY>
 * 1: Kit it would go into <STRING>
 * 2: Entry - a tile's, or a slot's (aio_storage_fnc_getSlot) <HASHMAP>
 * 3: How many of a stack, -1 for all of it <NUMBER> (default: -1)
 * 4: The slot it comes from, [unit, slot id] - [] for a tile <ARRAY> (default: [])
 * 5: Where the kit lies, [container, kit] - [] for where it was found as an open kit (GVAR(holders)) or
 *    a kit section of the ACE Arsenal's panel (GVAR(arsenalHolders))
 *    <ARRAY> (default: [])
 *
 * Return Value:
 * [fits, reason - "" when it fits] <ARRAY>
 *
 * Example:
 * [[backpackContainer player, ""], "efak_IFAK_7", _entry] call aio_compat_efak_fnc_canDrop;
 *
 * Public: No
 */

params [
    ["_source", [objNull, ""], [[]]],
    ["_kit", "", [""]],
    ["_entry", createHashMap, [createHashMap]],
    ["_count", -1, [0]],
    ["_slotSource", [], [[]]],
    ["_holder", [], [[]]]
];

_source params ["", ["_fromKit", "", [""]]];

if (_kit isEqualTo "") exitWith {[false, "Failed"]};

// Out of this very kit: within its open grid only where it lies changes. Its own tile is where it lies
// already - no room there, as for a tile out of an opened backpack dropped on that backpack.
if (_fromKit isNotEqualTo "" && {_fromKit == _kit}) exitWith {
    [[false, "NoRoom"], [true, ""]] select (_holder isEqualTo [])
};

if (_holder isEqualTo []) then {
    _holder = GVAR(holders) getOrDefault [toLowerANSI _kit, GVAR(arsenalHolders) getOrDefault [toLowerANSI _kit, [objNull, ""]]];
};

if !([_holder param [0, objNull]] call FUNC(mayReach)) exitWith {[false, LLSTRING(NotYours)]};
if (_slotSource isNotEqualTo [] && {(_slotSource param [0, objNull]) isNotEqualTo EGVAR(gui,unit)}) exitWith {[false, LLSTRING(OwnGearOnly)]};

private _touch = [_source param [0, objNull], "items"] call EFUNC(gui,checkTouch);

if (_touch isEqualTo "") then {
    _touch = [_kit, _holder] call FUNC(checkTouch);
};

if (_touch isNotEqualTo "") exitWith {[false, _touch]};

private _class = _entry getOrDefault ["class", ""];
private _stack = _entry getOrDefault ["count", 1];
private _n = 1;

if (_slotSource isEqualTo []) then {
    _n = [_count, _stack] select (_count < 1 || {_count > _stack});
};

// A kit holds only the class of a uniform, vest or backpack - whatever is in one would be gone.
private _inside = _entry getOrDefault ["container", objNull];

if (!isNull _inside && {([_inside] call EFUNC(storage,getContents)) isNotEqualTo []}) exitWith {[false, LLSTRING(EmptyFirst)]};

// A kit notes only the rounds of an opened magazine and takes any other for a full one: an empty one
// would come back out full (fnc_changeKit).
if (([_class] call EFAKFUNC(core,getMagazineSize)) > 1 && {(_entry getOrDefault ["ammo", 0]) < 1}) exitWith {
    [false, LLSTRING(EmptyMagazine)]
};

private _wait = call FUNC(notReady);

if (_wait isNotEqualTo "") exitWith {[false, _wait]};

// In ACE Arsenal's window (the one window attached with hooks) the kits tab's rules decide, as for a row of a list
// (fnc_canPackNew) and a tile taken out there (fnc_discard) - not the packing-off rule of that mod's kit window in the
// field, which turned the staging space away from a kit ACE's list could fill: the kit takes things in there, and the
// kit it comes out of, if any, lets them out (fnc_arsenalEditable).
if !([] call EFUNC(gui,isInventoryMode)) exitWith {
    private _locked = [_kit, true] call FUNC(arsenalEditable);

    if (_locked isEqualTo "" && {_fromKit isNotEqualTo ""}) then {
        _locked = [_fromKit, false] call FUNC(arsenalEditable);
    };

    if (_locked isNotEqualTo "") exitWith {[false, _locked]};

    [_kit, _class, _n, _entry getOrDefault ["ammo", -1]] call FUNC(canPack)
};

// What it held when the window first touched it, for the packing-off rule.
[_kit] call FUNC(snapshot);

if (!([_kit] call EFAKFUNC(core,canPackInto)) && {_n > ([_kit, _class, _entry getOrDefault ["ammo", 0]] call FUNC(repackable))}) exitWith {
    [false, localize "STR_efak_core_Error_PackingDisabled"]
};

[_kit, _class, _n, _entry getOrDefault ["ammo", -1]] call FUNC(canPack)
