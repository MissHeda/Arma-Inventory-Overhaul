#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A double click on one of several selected tiles, or Delete with a selection: the
 * whole selection moves at once.
 *
 *   Move over - from the unit's own storage to the containers of the loot column in the order it shows
 *               them (a pile on the ground too, like a single quick move; with nothing looted shown, the
 *               ground at the feet - seated, the vehicle), from the loot into the unit's uniform, vest
 *               and backpack. Worked out together (aio_storage_fnc_plan): the largest first, each into
 *               the first container with room, and what finds none stays ("Moved 4 of 6").
 *   Drop      - every selected tile not on the ground yet onto the ground: the surface under the feet,
 *               or the vehicle's cargo while seated.
 *
 * Kits are no targets of a group (a kit decides tile by tile, aio_compat_efak). A tile not searched yet,
 * one a move is under way for and one on a body's doll stay; a living person's gear only as the settings
 * say (fnc_checkTouch).
 *
 * Arguments:
 * 0: Tiles, [[grid index, tile index], ...] - fnc_selectionTiles <ARRAY>
 * 1: Drop them onto the ground instead of moving them over <BOOL> (default: false)
 *
 * Return Value:
 * Something was sent <BOOL>
 *
 * Example:
 * [call aio_gui_fnc_selectionTiles] call aio_gui_fnc_quickMoveGroup;
 *
 * Public: No
 */

disableSerialization;

params [["_tiles", [], [[]]], ["_toGround", false, [false]]];

if (_tiles isEqualTo [] || {!(call FUNC(isInventoryMode))}) exitWith {false};

private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _items = [];
private _side = "";
private _refused = "";

{
    _x params ["_gridIndex", "_tileIndex"];

    private _grid = _grids param [_gridIndex, createHashMap];
    private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
    private _from = _grid getOrDefault ["holder", objNull];

    if (
        count _tile == 0 || {_grid getOrDefault ["virtual", true]} || {_tile getOrDefault ["hidden", false]}
        || {_tile getOrDefault ["pending", false]} || {isNull (_grid getOrDefault ["container", objNull])}
        || {_toGround && {[_grid get "container"] call EFUNC(storage,isGroundHolder)}}
    ) then {continue};

    private _why = [_grid get "container", "items"] call FUNC(checkTouch);

    // Another living player's kit stays where it is, as for a single tile (aio_compat_efak).
    if (_why isEqualTo "" && {!isNil QEFUNC(compat_efak,checkTile)}) then {
        _why = [_tile getOrDefault ["class", ""], _grid get "container"] call EFUNC(compat_efak,checkTile);
    };

    if (_why isNotEqualTo "") then {
        if (_refused isEqualTo "") then {
            _refused = _why;
        };

        continue;
    };

    _tile set ["holder", _from];
    _tile set ["root", _grid getOrDefault ["root", objNull]];

    if (_side isEqualTo "") then {
        _side = _grid getOrDefault ["side", ""];
    };

    _items pushBack _tile;
} forEach _tiles;

if (_items isEqualTo []) exitWith {
    if (_refused isNotEqualTo "") then {
        [_refused] call FUNC(flashHint);
    };

    false
};

// ----- Onto the ground -----
if (_toGround) exitWith {
    [_items apply {[_x, "ground", objNull, []]}, count _items] call FUNC(sendPlan)
};

// ----- To the other side -----
private _unit = GVAR(unit);
private _targets = [];

if (_side isEqualTo "own") then {
    // The loot column's containers, in the order it shows them: the first with room takes what it can.
    private _seen = [];

    {
        private _container = _x getOrDefault ["container", objNull];

        if (
            (_x getOrDefault ["side", ""]) isEqualTo "loot" && {!(_x getOrDefault ["virtual", true])} && {!(_x getOrDefault ["overflow", false])}
            && {(_x getOrDefault ["window", ""]) isEqualTo ""} && {!isNull _container} && {!(_container in _seen)}
        ) then {
            _seen pushBack _container;

            if (([_container, "items"] call FUNC(checkTouch)) isEqualTo "") then {
                _targets pushBack [_container, _x getOrDefault ["root", objNull]];
            };
        };
    } forEach _grids;

    // Nothing looted shown: the ground at the feet, or the vehicle while seated (fnc_sendMoves).
    if (_targets isEqualTo []) then {
        _targets = [["ground", objNull]];
    };
} else {
    _targets = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] select {!isNull _x} apply {[_x, _unit]};
};

([_items, _targets] call EFUNC(storage,plan)) params ["_assigned"];

[_assigned, count _items] call FUNC(sendPlan)
