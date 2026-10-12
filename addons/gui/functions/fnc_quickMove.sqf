#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A double click, or "Move over" in the menu: moves an item to the other side without dragging (Ctrl+click
 * selects since 0.2.1; several selected tiles move together, fnc_quickMoveGroup). From the unit's own uniform, vest or
 * backpack it goes to what is being looted - the first container shown there with room - then into a
 * kit open in a window, the topmost window first, and to the ground only when neither is shown: the
 * surface under the feet, or the vehicle's cargo while seated. From the loot it goes into the unit's
 * uniform, vest or backpack, the first of them with room. The layout finds it a cell - the authority's,
 * once the move arrives there (fnc_applyMove, fnc_sendMoves).
 *
 * Kits are Enhanced First Aid Kits' and its pouches' (einv_compat_efak - only when that addon is
 * loaded): out of an open kit an item goes into the unit's own gear, the kit's "take into" choice first
 * (einv_compat_efak_fnc_takeOut); into one only what that kit takes (einv_compat_efak_fnc_canDrop).
 *
 * A living person's container the player may not put into (fnc_checkTouch) is passed over; when the
 * loot is nothing else, the hint says why - the ground is only for when nothing is being looted. A tile
 * not searched yet, or one a move is under way for, stays.
 *
 * When something is being looted but all of it is locked to the player (a locked section of the loot
 * column, einv_locks), the ground is no place for it either: the hint says "Locked".
 *
 * By weight: the first container with room for all of it by weight and by the grid takes it. A stack
 * that fits nowhere whole goes in part, as much as the first container with a free spot can carry by
 * weight, and the hint says "Moved 3 of 10 - the rest is too heavy for ..." once the move went through.
 * Nothing fitting at all says how much room the best container has left (fnc_weightText), a backpack that
 * has nowhere but backpacks to go says that.
 *
 * Arguments:
 * 0: Grid index <NUMBER>
 * 1: Tile index <NUMBER>
 *
 * Return Value:
 * Moved - or asked for <BOOL>
 *
 * Example:
 * [0, 3] call einv_gui_fnc_quickMove;
 *
 * Public: No
 */

disableSerialization;

params ["_gridIndex", "_tileIndex"];

private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _grid = _grids param [_gridIndex, createHashMap];
private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
private _from = _grid getOrDefault ["container", objNull];
private _kit = _grid getOrDefault ["kit", ""];

if (
    count _tile == 0 || {isNull _from && {_kit isEqualTo ""}} || {_grid getOrDefault ["virtual", true]}
    || {_tile getOrDefault ["hidden", false]} || {_tile getOrDefault ["pending", false]}
) exitWith {false};

// Out of an open kit: into the player's own gear.
if (_kit isNotEqualTo "") exitWith {
    !isNil QEFUNC(compat_efak,takeOut) && {[_kit, _tile] call EFUNC(compat_efak,takeOut)}
};

private _unit = GVAR(unit);
private _own = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] select {!isNull _x};

// Which of the containers takes it, and how much: [container, count - -1 for all of it, why not - a text
// for the hint, "" for none]. The first with room by weight and a free spot takes all of it; failing that
// a stack goes in part into the first with a free spot that carries some by weight; failing that, why
// not is how much room the best of them has left, or that a backpack does not go into a backpack.
private _fnc_pick = {
    params ["_targets"];

    private _stack = _tile getOrDefault ["count", 1];
    private _partial = [];
    private _whole = objNull;
    private _bestFree = -1;
    private _noBackpack = false;

    {
        if (_x isEqualTo _from || {!([_x, _tile] call EFUNC(storage,hasSpace))}) then {continue};

        private _room = [_x, _tile] call EFUNC(storage,roomByWeight);

        if (_room get "fits") exitWith {
            _whole = _x;
        };

        if ((_room get "reason") isEqualTo "NoBackpack") then {
            _noBackpack = true;
            continue
        };

        if (_partial isEqualTo [] && {_stack > 1} && {(_room get "maxCount") >= 1}) then {
            _partial = [_x, _room get "maxCount"];
        };

        _bestFree = _bestFree max (_room get "free");
    } forEach _targets;

    if (!isNull _whole) exitWith {[_whole, -1, ""]};
    if (_partial isNotEqualTo []) exitWith {[_partial select 0, _partial select 1, ""]};

    private _why = "";

    if (_bestFree >= 0) then {
        _why = ["everywhere", _tile, _bestFree] call FUNC(weightText);
    } else {
        if (_noBackpack) then {
            _why = "NoBackpack";
        };
    };

    [objNull, -1, _why]
};

// Moves it into the container the pick named. A part of a stack says so once the move went through
// (fnc_build writes the pending hint into the new footer; fnc_afterAction drops it for a refusal).
private _fnc_move = {
    params ["_target", "_count"];

    if (_count > 0) then {
        GVAR(pendingHint) = [[["movedSome", _target, _count, _tile getOrDefault ["count", 1]] call FUNC(weightText), "text2"]];
    };

    private _asked = [_from, _target, _tile, _count, []] call FUNC(applyMove);

    // Refused on the spot: the refusal's hint is the one to show.
    if (!_asked) then {
        GVAR(pendingHint) = [];
    };

    _asked
};

if !(_from in _own) exitWith {
    ([_own] call _fnc_pick) params ["_target", "_count", "_why"];

    if (isNull _target) exitWith {
        [["NowhereToGo", _why] select (_why isNotEqualTo "")] call FUNC(flashHint);
        false
    };

    [_target, _count] call _fnc_move
};

// From the player's own gear: the loot containers in the order the column shows them, then the open
// kits - the topmost window first, as the player sees them lying over each other. The kit the item is
// cannot take itself.
private _loot = [];
private _kits = [];
private _class = _tile getOrDefault ["class", ""];

private _order = +GVAR(windowOrder);
reverse _order;

{
    private _key = _x;

    {
        private _gridKit = _x getOrDefault ["kit", ""];

        if (
            (_x getOrDefault ["window", ""]) isEqualTo _key && {!(_x getOrDefault ["virtual", true])}
            && {_gridKit isNotEqualTo ""} && {!(_gridKit in _kits)} && {_gridKit != _class}
        ) then {
            _kits pushBack _gridKit;
        };
    } forEach _grids;
} forEach _order;

{
    private _container = _x getOrDefault ["container", objNull];
    private _gridKit = _x getOrDefault ["kit", ""];

    if (_x getOrDefault ["virtual", true]) then {continue};

    if (_gridKit isNotEqualTo "") then {
        if (!(_gridKit in _kits) && {_gridKit != _class}) then {
            _kits pushBack _gridKit;
        };

        continue;
    };

    if (!isNull _container && {!(_container in _own)} && {!(_container in _loot)}) then {
        _loot pushBack _container;
    };
} forEach _grids;

// Nothing looted and no kit open: the ground - the server finds the pile at the feet or makes one.
if (_loot isEqualTo [] && {_kits isEqualTo []}) exitWith {
    // Something is being looted, all of it locked to the player (einv_locks): not the ground then either.
    if ((GVAR(context) getOrDefault ["lootSections", []]) findIf {_x getOrDefault ["locked", false]} >= 0) exitWith {
        ["Locked"] call FUNC(flashHint);
        false
    };

    // A window that attached takes it itself (the "ground" hook: the Arsenal gives it back).
    if ((["ground", [[_gridIndex, _tileIndex], -1], false] call FUNC(hook)) isEqualTo true) exitWith {true};

    [_from, "ground", _tile, -1, []] call FUNC(applyMove)
};

// Only what the player may put into - a living person's container as the settings say. Refused there,
// the hint says why.
private _refused = "";

_loot = _loot select {
    private _why = [_x, "items"] call FUNC(checkTouch);

    if (_why isNotEqualTo "" && {_refused isEqualTo ""}) then {
        _refused = _why;
    };

    _why isEqualTo ""
};

([_loot] call _fnc_pick) params ["_target", "_count", "_weightWhy"];

if (!isNull _target) exitWith {
    [_target, _count] call _fnc_move
};

private _kitIndex = -1;

if (!isNil QEFUNC(compat_efak,canDrop)) then {
    _kitIndex = _kits findIf {(([[_from, ""], _x, _tile, -1] call EFUNC(compat_efak,canDrop)) select 0)};
};

if (_kitIndex < 0 || {isNil QEFUNC(compat_efak,drop)}) exitWith {
    // Every container shown was a living person's the player may not put into: that is why. Too heavy for
    // all of them: how much room the best has left.
    private _why = ["NowhereToGo", _refused] select (_loot isEqualTo [] && {_refused isNotEqualTo ""});

    if (_weightWhy isNotEqualTo "") then {
        _why = _weightWhy;
    };

    [_why] call FUNC(flashHint);
    false
};

[[_from, ""], [objNull, _kits select _kitIndex], _tile, -1, [], []] call EFUNC(compat_efak,drop)
