#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * An item was just found (fnc_animateSearch): its tile is drawn anew where it lies, without its hatching, and
 * the search moves on to the next item - without building the window again. A build for every item
 * found made a crate or vehicle full of loot flicker while it was searched (Mia, 0.2.3): every control
 * was made anew, the columns stood at the top for a frame until their scroll came back, and the camera
 * started again.
 *
 * Nothing but this one tile changes: what lies where, the compartments and the load stay as they are, so
 * the rest of the column, its scroll, the open kit windows and the hover stay too. The tile keeps its
 * place in its grid's list of tiles - a press or a hover that points at it still finds it.
 *
 * Only where that is all that changes: the first item found in a section brings its Take all button, and
 * that line is drawn by the section - then it answers false and the caller builds the window.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The item, as it stood at the head of the search queue (fnc_markHidden), already learnt <ARRAY>
 *
 * Return Value:
 * Done - false: the window has to be built anew <BOOL>
 *
 * Example:
 * [_display, _head] call einv_gui_fnc_revealTile;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_item"];

if (isNull _display) exitWith {false};

private _found = _item call FUNC(findTile);

// Not on the window any more (folded away meanwhile): nothing to draw, the next item comes up. A tile on a page of a tall
// compartment that is not turned to has no controls: it only stops being hatched, for when its page comes.
if (_found isEqualTo []) exitWith {
    _item params ["_itemContainer", "_itemKey", "_itemRow", "_itemCol", "", ["_itemBlock", 0]];

    {
        if ((_x getOrDefault ["container", objNull]) isEqualTo _itemContainer) then {
            {
                if (
                    (_x getOrDefault ["offPage", false]) && {(_x getOrDefault ["row", -1]) == _itemRow} && {(_x getOrDefault ["col", -1]) == _itemCol}
                    && {(_x getOrDefault ["block", 0]) == _itemBlock} && {toLowerANSI (_x getOrDefault ["class", ""]) isEqualTo _itemKey}
                ) then {
                    _x deleteAt "hidden";
                };
            } forEach (_x getOrDefault ["tiles", []]);
        };
    } forEach (uiNamespace getVariable [QGVAR(grids), []]);

    GVAR(searchQueue) = GVAR(searchQueue) select {_x isNotEqualTo _item};
    [_display] call FUNC(updateStatus);
    true
};

_found params ["_grid", "_tile"];

// The first searched tile of a section brings its Take all or Put all in button: the caption line is the
// section's to draw.
private _holder = _grid getOrDefault ["holder", objNull];
private _infos = uiNamespace getVariable [QGVAR(sectionInfo), []];
private _info = _infos param [_infos findIf {(_x getOrDefault ["holder", objNull]) isEqualTo _holder}, createHashMap];

if ((_info getOrDefault ["button", ""]) isEqualTo "" && {(_info getOrDefault ["eligible", ""]) isNotEqualTo ""}) exitWith {false};

private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _gridIndex = _grids find _grid;
private _tiles = _grid get "tiles";
private _tileIndex = _tiles find _tile;

if (_gridIndex < 0 || {_tileIndex < 0}) exitWith {false};

// The hatched tile goes, the found item's tile comes in its place - at the same index of the grid's tiles.
{ctrlDelete _x} forEach (_tile getOrDefault ["controls", []]);

{
    _tile deleteAt _x;
} forEach ["hidden", "controls", "background", "backgrounds", "rect", "color"];

[_display, _grid, _tile, GVAR(theme)] call FUNC(createTile);

// fnc_createTile added it at the end of the list: it stands where it stood already.
_tiles deleteAt (count _tiles - 1);

GVAR(searchQueue) = GVAR(searchQueue) select {_x isNotEqualTo _item};

// The mouse on it is looked at again: the hint names the item now.
if (GVAR(hover) isEqualTo ["tile", _gridIndex, _tileIndex]) then {
    GVAR(hover) = [];
    GVAR(lastMouse) = [];
};

if (GVAR(filter) isNotEqualTo "" || {GVAR(groupFilters) isNotEqualTo []}) then {
    [] call FUNC(applyFilter);
};

[_display] call FUNC(updateStatus);

true
