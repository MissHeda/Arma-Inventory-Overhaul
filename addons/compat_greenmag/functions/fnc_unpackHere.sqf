#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * "Unpack" of a GreenMag Rework box of rounds in the window - its row of the right-click menu and its double click: the box opens
 * and its rounds lie where it lay. In the player's own uniform, vest or backpack the box is taken out of its tile and the rounds are
 * put on the cells it took, a stack per cell (as many as a stack holds, aio_items), the rest wherever the layout finds room. Anywhere
 * else - a crate, the ground, a box the window cannot point at - GreenMag's own unpack takes over, which gives the rounds to the
 * player.
 *
 * The tile is the one the menu was opened for (aio_gui_menuFor - also for the double click, fnc_doubleClickRule).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Container <OBJECT>
 * 2: The box's class <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, vestContainer player, "gmr_pack_556x45_basic_30"] call aio_compat_greenmag_fnc_unpackHere;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_container", objNull, [objNull]], ["_item", "", [""]]];

if (isNil "gmr_handling_fnc_unpack" || {_item isEqualTo ""}) exitWith {};

// The tile the menu was opened for, when it is this box in this container.
(missionNamespace getVariable [QEGVAR(gui,menuFor), []]) params [["_kind", ""], ["_gridIndex", -1], ["_tileIndex", -1]];

private _grid = (uiNamespace getVariable [QEGVAR(gui,grids), []]) param [_gridIndex, createHashMap];
private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
private _own = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] - [objNull];

private _here = _kind isEqualTo "tile"
    && {(_tile getOrDefault ["class", ""]) == _item}
    && {(_grid getOrDefault ["container", objNull]) isEqualTo _container}
    && {(_grid getOrDefault ["kit", ""]) isEqualTo ""}
    && {_container in _own}
    && {local _container}
    && {!(_tile getOrDefault ["pending", false])}
    && {!(_tile getOrDefault ["hidden", false])};

if (!_here) exitWith {
    [_unit, _item, true, _container] call gmr_handling_fnc_unpack;
    [] call EFUNC(gui,requestRebuild);
};

private _facts = [_item] call gmr_main_fnc_itemInfo;
private _rounds = _facts param [GMR_ITEM_ROUNDS, 0];
private _round = _facts param [GMR_ITEM_ROUND, ""];

if (_rounds < 1 || {_round isEqualTo ""}) exitWith {};

// One of a stack (stripper clips lie five to a tile): only that one leaves, the stack keeps its cells, the rounds find room.
if ((_tile getOrDefault ["count", 1]) > 1) exitWith {
    if (([_container, _tile, 1] call EFUNC(storage,removeEntry)) isEqualTo []) exitWith {
        ["Failed"] call EFUNC(gui,flashHint);
    };

    if (([_container, _round, _rounds] call EFUNC(storage,addNew)) isNotEqualTo "") then {
        [_unit, _round, _rounds] call gmr_main_fnc_giveItem;
    };

    [] call EFUNC(gui,requestRebuild);
};

// The box out, its record first: its cells are free for the rounds.
[_container, _tile, []] call EFUNC(storage,setPlace);

if (([_container, _tile, -1] call EFUNC(storage,removeEntry)) isEqualTo []) exitWith {
    ["Failed"] call EFUNC(gui,flashHint);
};

// A stack on each of the box's cells, row by row, as long as rounds are left; what is left over finds room of its own.
private _stack = (([_round] call EFUNC(items,getInfo)) getOrDefault ["stack", 1]) max 1;
private _left = _rounds;
private _col = _tile getOrDefault ["col", 0];
private _row = _tile getOrDefault ["row", 0];
private _block = _tile getOrDefault ["block", 0];

for "_r" from 0 to ((_tile getOrDefault ["h", 1]) - 1) do {
    for "_c" from 0 to ((_tile getOrDefault ["w", 1]) - 1) do {
        if (_left > 0) then {
            private _count = _left min _stack;

            if (([_container, _round, _count, [_col + _c, _row + _r, _block, 1, 1]] call EFUNC(storage,addNew)) isEqualTo "") then {
                _left = _left - _count;
            };
        };
    };
};

if (_left > 0 && {([_container, _round, _left] call EFUNC(storage,addNew)) isNotEqualTo ""}) then {
    // No room left in this container: GreenMag gives the rest to the player, the ground as its last place.
    [_unit, _round, _left] call gmr_main_fnc_giveItem;
};

[] call EFUNC(gui,requestRebuild);
