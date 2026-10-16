#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What a double click on a tile does, and what the quick move key does (fnc_onKeyDown): on a tile of a selection
 * of several all of them move over (fnc_quickMoveGroup); on the ground what can be worn is put on
 * (fnc_quickEquip); a kit of Enhanced First Aid Kits or Enhanced Utility Pouches opens in a window of its own
 * or closes (einv_compat_efak_fnc_toggle - only when that addon is loaded, and only while that mod's double
 * click setting is on), so does a uniform, vest or backpack lying in a container (fnc_openNested) - anything
 * else moves over (fnc_quickMove). Never other mods' context menu, which the vanilla inventory opens on a
 * double click.
 *
 * Arguments:
 * 0: Index of the grid the tile lies on <NUMBER>
 * 1: Index of the tile <NUMBER>
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * [2, 5] call einv_gui_fnc_quickAction;
 *
 * Public: No
 */

params ["_gridIndex", "_tileIndex"];

private _selected = if (call FUNC(isInventoryMode)) then {call FUNC(selectionTiles)} else {[]};

if (count _selected >= 2 && {[_gridIndex, _tileIndex] in _selected}) exitWith {
    [_selected] call FUNC(quickMoveGroup);
    true
};

// On the ground: what can be worn is put on - only in the inventory, on a pile's grid, on a searched tile
// that is not under way.
private _grid = (uiNamespace getVariable [QGVAR(grids), []]) param [_gridIndex, createHashMap];
private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];

private _onGround = count _tile > 0 && {call FUNC(isInventoryMode)} && {!(_grid getOrDefault ["virtual", true])}
    && {!(_tile getOrDefault ["hidden", false])} && {!(_tile getOrDefault ["pending", false])}
    && {[_grid getOrDefault ["container", objNull]] call EFUNC(storage,isGroundHolder)};

// Worn or carried in a slot of its own - never a part of a weapon, which is a slot id with an underscore.
private _wearSlot = ["", [GVAR(unit), _tile getOrDefault ["class", ""]] call EFUNC(storage,slotFor)] select _onGround;

if (_wearSlot isNotEqualTo "" && {(_wearSlot find "_") < 0}) exitWith {
    [_gridIndex, _tileIndex] call FUNC(quickEquip);
    true
};

private _handled = !isNil QEFUNC(compat_efak,toggle) && {[_gridIndex, _tileIndex, true] call EFUNC(compat_efak,toggle)};

if (!_handled && {!([_gridIndex, _tileIndex] call FUNC(openNested))}) then {
    [_gridIndex, _tileIndex] call FUNC(quickMove);
};

true
