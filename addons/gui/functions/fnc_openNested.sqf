#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens a uniform, vest or backpack that lies in a container - a backpack in a crate, a vest on the
 * ground - as a section of its own in the loot column, the way Tarkov opens a container in a window;
 * or closes it again. Things move in and out of it like in any container. Searched as the container
 * it lies in is (fnc_isSearched).
 *
 * Opening and closing sound as the container it is: fabric and buckles for a backpack, a vest, a uniform
 * (fnc_playSound "open", "close").
 *
 * Kept in GVAR(opened) as [class, container object, container it lies in]; one that is gone - moved,
 * so the engine made a new object for it - drops out at the next build. Opening tags the container
 * object with the item's class (einv_storage_itemClass), for its compartments.
 *
 * Arguments:
 * 0: Grid index <NUMBER>
 * 1: Tile index <NUMBER>
 *
 * Return Value:
 * Opened or closed <BOOL>
 *
 * Example:
 * [1, 4] call einv_gui_fnc_openNested;
 *
 * Public: No
 */

disableSerialization;

params ["_gridIndex", "_tileIndex"];

private _grid = (uiNamespace getVariable [QGVAR(grids), []]) param [_gridIndex, createHashMap];
private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
private _object = _tile getOrDefault ["container", objNull];
private _from = _grid getOrDefault ["container", objNull];

if (isNull _object || {isNull _from} || {_tile getOrDefault ["hidden", false]} || {_grid getOrDefault ["virtual", true]}) exitWith {false};

private _class = _tile getOrDefault ["class", ""];
private _index = GVAR(opened) findIf {(_x select 1) isEqualTo _object};

if (_index >= 0) then {
    GVAR(opened) deleteAt _index;
} else {
    // The container object of a uniform or vest is only its Supply class, and lying in a container it
    // is nobody's - which uniform or vest it is, only its tile knows. Its compartments go by that
    // class (einv_storage_fnc_getBlocks), so it is tagged with it. On this machine only, like the
    // layouts; a moved one is a new object and gets tagged anew when it is opened again.
    _object setVariable [QEGVAR(storage,itemClass), _class];
    GVAR(opened) pushBack [_class, _object, _from];
};

// Open or close, as the container it is: fabric and buckles for a backpack, a vest, a uniform.
[["open", "close"] select (_index >= 0), _class, _object] call FUNC(playSound);

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (!isNull _display) then {
    [_display] call FUNC(build);
};

true
