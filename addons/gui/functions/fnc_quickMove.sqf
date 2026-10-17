#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A double click: moves an item to the other side without dragging (Ctrl+click
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
 * Free cells decide: the first container with a free spot for all of it takes it, whatever it weighs. A
 * backpack that has nowhere but backpacks to go says that. The room is asked of fnc_roomFor, not laid out
 * anew for every press, and the move is told it was checked (applyMove's option "roomChecked").
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

// Which of the containers takes it: [container, why not - "NoBackpack" when the only room is in a backpack
// and it is one, "" for none]. The first with a free spot takes all of it.
private _fnc_pick = {
    params ["_targets"];

    private _whole = objNull;
    private _noBackpack = false;

    {
        if (_x isEqualTo _from) then {continue};

        // The room is asked of fnc_roomFor, which keeps what it worked out while the container stays as it is and
        // counts the room it gives away: a held key asks this at every repeat. A backpack for a backpack takes none.
        private _backpack = [_x, _tile] call EFUNC(storage,backpackIntoBackpack);

        if (!([_x, _tile, !_backpack] call FUNC(roomFor))) then {continue};

        if (_backpack) then {
            _noBackpack = true;
        } else {
            _whole = _x;
        };

        if (!isNull _whole) exitWith {};
    } forEach _targets;

    [_whole, ["", "NoBackpack"] select (isNull _whole && {_noBackpack})]
};

if !(_from in _own) exitWith {
    ([_own] call _fnc_pick) params ["_target", "_why"];

    if (isNull _target) exitWith {
        [["NowhereToGo", _why] select (_why isNotEqualTo "")] call FUNC(flashHint);
        false
    };

    [_from, _target, _tile, -1, [], createHashMapFromArray [["roomChecked", true]]] call FUNC(applyMove)
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

    // A window that attached takes it itself (the "ground" hook: the Arsenal takes it out).
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

([_loot] call _fnc_pick) params ["_target", "_packWhy"];

if (!isNull _target) exitWith {
    [_from, _target, _tile, -1, [], createHashMapFromArray [["roomChecked", true]]] call FUNC(applyMove)
};

private _kitIndex = -1;

if (!isNil QEFUNC(compat_efak,canDrop)) then {
    _kitIndex = _kits findIf {(([[_from, ""], _x, _tile, -1] call EFUNC(compat_efak,canDrop)) select 0)};
};

if (_kitIndex < 0 || {isNil QEFUNC(compat_efak,drop)}) exitWith {
    // Every container shown was a living person's the player may not put into: that is why. A backpack with
    // only backpacks to go into: that.
    private _why = ["NowhereToGo", _refused] select (_loot isEqualTo [] && {_refused isNotEqualTo ""});

    if (_packWhy isNotEqualTo "") then {
        _why = _packWhy;
    };

    [_why] call FUNC(flashHint);
    false
};

[[_from, ""], [objNull, _kits select _kitIndex], _tile, -1, [], []] call EFUNC(compat_efak,drop)
