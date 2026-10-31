#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The tile a uniform, vest or backpack opened from inside a container (fnc_openNested) lies on in that
 * container's grid. Its box in the loot column (fnc_drawSection) stands for that tile: pressed, it is
 * lifted as the tile (fnc_onMouseButton) - the same drag, so whatever the engine does with the tile it
 * does with the box: onto a slot or the storage column it is put on, into a crate it moves, outside every
 * panel it goes on the ground - and the mouse over it gets the tile's hint (fnc_updateHover).
 * In the inventory only - the Arsenal's drags are its own -, and only while that tile is on the window
 * and searched: a folded pile has no grid to lift it from.
 *
 * Arguments:
 * 0: Its container object, as the box's slot record keeps it (fnc_drawSlot) <OBJECT>
 *
 * Return Value:
 * [grid index, tile index], [] for none <ARRAY>
 *
 * Example:
 * [_record param [8, objNull]] call einv_gui_fnc_boxTile;
 *
 * Public: No
 */

params [["_object", objNull, [objNull]]];

if (isNull _object || {!(call FUNC(isInventoryMode))}) exitWith {[]};

private _result = [];

{
    private _gridIndex = _forEachIndex;

    if (!(_x getOrDefault ["virtual", true]) && {(_x getOrDefault ["source", ""]) isEqualTo ""}) then {
        private _tileIndex = (_x getOrDefault ["tiles", []]) findIf {
            (_x getOrDefault ["container", objNull]) isEqualTo _object && {!(_x getOrDefault ["hidden", false])}
        };

        if (_tileIndex >= 0) then {
            _result = [_gridIndex, _tileIndex];
        };
    };

    if (_result isNotEqualTo []) exitWith {};
} forEach (uiNamespace getVariable [QGVAR(grids), []]);

_result
