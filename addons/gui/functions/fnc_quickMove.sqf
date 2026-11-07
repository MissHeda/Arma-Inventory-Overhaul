#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A double click: moves an item to the other side without dragging (Ctrl+click
 * selects since 0.2.1; several selected tiles move together, fnc_quickMoveGroup). From the unit's own uniform, vest or
 * backpack it goes to what is being looted - the first container shown there with room - then into a
 * kit open in a window, the topmost window first. With neither shown it moves within the unit's own gear: out of
 * the backpack into the vest, then the uniform, out of the vest or the uniform into the backpack, then the other
 * one - dropping is the drop key's; seated, it goes into the vehicle's cargo. From the loot it goes into the unit's
 * uniform, vest or backpack, the first of them with room. The layout finds it a cell - the authority's,
 * once the move arrives there (fnc_applyMove, fnc_sendMoves).
 *
 * Kits are Enhanced First Aid Kits' and its pouches' (aio_compat_efak - only when that addon is
 * loaded): out of an open kit an item goes into the unit's own gear, the kit's "take into" choice first
 * (aio_compat_efak_fnc_takeOut); into one only what that kit takes (aio_compat_efak_fnc_canDrop).
 *
 * A living person's container the player may not put into (fnc_checkTouch) is passed over; when the
 * loot is nothing else, the hint says why - the ground is only for when nothing is being looted. A tile
 * not searched yet, or one a move is under way for, stays.
 *
 * When something is being looted but all of it is locked to the player (a locked section of the loot
 * column, aio_locks), the ground is no place for it either: the hint says "Locked".
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
 * [0, 3] call aio_gui_fnc_quickMove;
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

// The container the player picked (a click on a free cell of it, fnc_quickTarget) comes first, from whichever side: with no room
// the hint says so - it was asked for by name.
([[_from]] call FUNC(quickTarget)) params [["_picked", objNull]];

if (!isNull _picked) exitWith {
    private _intoBackpack = [_picked, _tile] call EFUNC(storage,backpackIntoBackpack);

    if (_intoBackpack || {!([_picked, _tile, true] call FUNC(roomFor))}) exitWith {
        [["NoRoom", "NoBackpack"] select _intoBackpack] call FUNC(flashHint);
        false
    };

    [_from, _picked, _tile, -1, [], createHashMapFromArray [["roomChecked", true]]] call FUNC(applyMove)
};

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

// From the player's own gear with no container picked: onto the ground (Mia, after 0.6.79: "always on the ground") - a container,
// the vest or a crate, is picked by a click on it (fnc_pickTarget). Seated, the vehicle's cargo, which the server finds for a seated
// unit; on foot the pile at the feet (fnc_dropToGround) - or what a window that attached does with it (the "ground" hook).
if ((["ground", [[_gridIndex, _tileIndex], -1], false] call FUNC(hook)) isEqualTo true) exitWith {true};

if (!isNull objectParent _unit) exitWith {
    [_from, "ground", _tile, -1, []] call FUNC(applyMove)
};

[_gridIndex, _tileIndex] call FUNC(dropToGround)
