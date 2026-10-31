#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Sizes the staging space's grid by what lies in it (fnc_staging): STORAGE_COLS wide, always
 * STAGING_FREE_ROWS free rows under the lowest row in use - so there is always room further down, and it
 * grows the further one goes -, at least STAGING_MIN_ROWS and the rows that fill the panel's column down
 * to its hint line (fnc_layout), at most STAGING_MAX_ROWS rows. Whatever found no cell (the layout's
 * "overflow") counts with its height, so it gets rows of its own.
 * Run before every draw of the panel, just before its section (fnc_layout): every move into or out of the
 * staging space draws the panel anew, so the grid follows each one. It shrinks back as things leave, never
 * above the lowest row in use. The rows go on the crate as compartments given exactly (aio_grid as
 * [[cols, rows]], aio_storage_fnc_getBlocks): a text grid would be cut to MAX_ROWS, which bounds every
 * item's size too.
 * The crate is this machine's alone, so the variable is too.
 * Arguments:
 * 0: The staging crate <OBJECT>
 * 1: Rows that fill the panel's column below the sections above it <NUMBER> (default: 0)
 * Return Value:
 * Its grid changed <BOOL>
 * Example:
 * [aio_arsenal_staging, 12] call aio_arsenal_fnc_growStaging;
 * Public: No
 */

params [["_holder", objNull, [objNull]], ["_fill", 0, [0]]];

if (isNull _holder) exitWith {false};

private _layout = [_holder, [_holder] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout);
private _lowest = 0;

{
    if ((_x getOrDefault ["count", 1]) > 0 && {(_x getOrDefault ["block", -1]) >= 0}) then {
        _lowest = _lowest max ((_x getOrDefault ["row", 0]) + (_x getOrDefault ["h", 1]));
    };
} forEach (_layout getOrDefault ["entries", []]);

// What has no cell yet lies under everything once the grid has the rows for it.
{
    _lowest = _lowest + (_x getOrDefault ["h", 1]);
} forEach (_layout getOrDefault ["overflow", []]);

private _rows = ((_lowest + STAGING_FREE_ROWS) max STAGING_MIN_ROWS max _fill) min STAGING_MAX_ROWS;
private _grid = [[STORAGE_COLS, _rows]];

if ((_holder getVariable [QGVARMAIN(grid), []]) isEqualTo _grid) exitWith {false};

_holder setVariable [QGVARMAIN(grid), _grid];

true
