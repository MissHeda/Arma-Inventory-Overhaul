#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Delete, Drop, a drag let go outside every panel: puts an item on the ground - on foot the surface
 * under the feet, where the server uses the pile already there or makes one (op putGround); seated, the
 * vehicle's cargo, as vanilla does. With nothing under the feet (swimming, falling) it stays, and the
 * hint says so (fnc_sendMoves).
 *
 * Out of an open kit of Enhanced First Aid Kits too (einv_compat_efak - only when that addon is loaded):
 * by the kit's own ops, at the kit's authority - out of a kit in a living person's gear only as the
 * window's settings for it say (einv_compat_efak_fnc_checkTouch). Something already on the ground, not
 * searched yet or under way stays.
 *
 * Arguments:
 * 0: Grid index <NUMBER>
 * 1: Tile index <NUMBER>
 * 2: How many of a stack, -1 for all of it <NUMBER> (default: -1)
 *
 * Return Value:
 * Asked for <BOOL>
 *
 * Example:
 * [0, 3] call einv_gui_fnc_dropToGround;
 *
 * Public: No
 */

disableSerialization;

params ["_gridIndex", "_tileIndex", ["_count", -1]];

private _grid = (uiNamespace getVariable [QGVAR(grids), []]) param [_gridIndex, createHashMap];
private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
private _from = _grid getOrDefault ["container", objNull];
private _kit = _grid getOrDefault ["kit", ""];

if (
    count _tile == 0 || {isNull _from && {_kit isEqualTo ""}} || {_grid getOrDefault ["virtual", true]}
    || {_tile getOrDefault ["hidden", false]} || {_tile getOrDefault ["pending", false]}
) exitWith {false};

// A window that attached takes the item itself instead of the ground (the "ground" hook: the Arsenal gives
// it back), told where it is, [grid index, tile index], and how many, -1 for all.
if ((["ground", [[_gridIndex, _tileIndex], _count], false] call FUNC(hook)) isEqualTo true) exitWith {true};

if (_kit isNotEqualTo "") exitWith {
    private _why = if (isNil QEFUNC(compat_efak,checkTouch)) then {""} else {[_kit] call EFUNC(compat_efak,checkTouch)};

    if (_why isNotEqualTo "") exitWith {
        [_why] call FUNC(flashHint);
        false
    };

    // The kit's grid stands for the kit as a holder of the storage (its layout key).
    private _holder = _grid getOrDefault ["holder", _grid getOrDefault ["layoutKey", ""]];

    if !(_holder isEqualType "" && {_holder isNotEqualTo ""}) exitWith {false};

    [[createHashMapFromArray [
        ["kind", "move"], ["from", _holder], ["fromRoot", _grid getOrDefault ["root", objNull]],
        ["entry", _tile], ["count", _count], ["to", "ground"], ["cell", []]
    ]]] call FUNC(sendMoves)
};

// Already on the ground.
if ([_from] call EFUNC(storage,isGroundHolder)) exitWith {false};

[_from, "ground", _tile, _count, []] call FUNC(applyMove)
