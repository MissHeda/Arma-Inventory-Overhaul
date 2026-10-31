#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The tile an item of the search queue (fnc_markHidden) lies on now, among the window's grids.
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Class, lower case <STRING>
 * 2: Row <NUMBER>
 * 3: Column <NUMBER>
 * 4: Cells it covers (not looked at) <NUMBER>
 * 5: Compartment <NUMBER> (default: 0)
 * 6: Kit whose grid it lies in - with a container of objNull - "" for a container <STRING> (default: "")
 *
 * Return Value:
 * [grid, tile], [] when it is not on the window - a tile on a page that is not turned to is not <ARRAY>
 *
 * Example:
 * (einv_gui_searchQueue select 0) call einv_gui_fnc_findTile;
 *
 * Public: No
 */

params ["_container", "_key", "_row", "_col", "", ["_block", 0], ["_kit", ""]];

private _result = [];

{
    private _grid = _x;

    if (
        (_grid getOrDefault ["container", objNull]) isEqualTo _container && {(_grid getOrDefault ["kit", ""]) isEqualTo _kit}
        && {!(_grid getOrDefault ["virtual", true])}
    ) then {
        private _tiles = _grid getOrDefault ["tiles", []];
        private _index = _tiles findIf {
            toLowerANSI (_x getOrDefault ["class", ""]) isEqualTo _key
            && {(_x getOrDefault ["row", -1]) == _row}
            && {(_x getOrDefault ["col", -1]) == _col}
            && {(_x getOrDefault ["block", 0]) == _block}
            && {!(_x getOrDefault ["offPage", false])}
        };

        if (_index >= 0) then {
            _result = [_grid, _tiles select _index];
        };
    };

    if (_result isNotEqualTo []) exitWith {};
} forEach (uiNamespace getVariable [QGVAR(grids), []]);

_result
