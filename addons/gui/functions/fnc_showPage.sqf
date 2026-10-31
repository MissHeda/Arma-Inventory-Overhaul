#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows another page of a paged compartment (fnc_pageRanges) without building the window: only this box is drawn
 * again - its panel, the tiles of the rows that show now, the squares of the free cells and the bar. Only the page shown
 * has controls: every control the compartment's tiles ever made (the grid's "tileControls", whatever a tile says it holds)
 * and every cell square goes before the new page is drawn, and the marks of the hands' queue are made again for the tiles
 * that show (fnc_drawPending), so nothing of another page stays under or over this one. The tiles of the page left behind
 * give up their controls and stay on the grid bare ("offPage"), so a tile's
 * number in the grid never changes: a drag under way, a press, the selection and the hands' queue still point at the
 * tile they pointed at. Everything else on the window stays - the scroll of the columns, the other boxes, the open kit
 * windows. What lay over the tiles that went comes back as after a redraw of tiles (fnc_redrawTiles): the moves under
 * way and the queue's marks, the selection, the search field's fading; the hover is looked at again and an open menu closed.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The grid of a paged compartment <HASHMAP>
 * 2: The page to show, from 0 <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _grid, 2] call aio_gui_fnc_showPage;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_grid", ["_page", 0, [0]]];

private _ranges = _grid getOrDefault ["pageRanges", []];

if (isNull _display || {_ranges isEqualTo []}) exitWith {};

_page = (_page min (count _ranges - 1)) max 0;

private _window = _ranges select _page;
private _tiles = _grid get "tiles";
private _parent = _grid get "parent";

_grid set ["page", _page];

// The rows are the same: the bar alone changes (a search may have moved the marks).
private _shownTo = _window param [2, _window select 1];

_grid set ["tileTo", _window select 1];

if ((_window select 0) == (_grid get "rowFrom") && {_shownTo == (_grid get "rowTo")}) exitWith {
    [_display, _grid] call FUNC(drawPageBar);
};

// What the page left shows goes: the squares of the cells (and the pieces that round them), the tiles' controls, the panel.
[_grid] call FUNC(clearCells);

private _gone = ["controls", "background", "backgrounds", "corners", "rect", "color", "bar", "barRect", "amount", "amountShort"];

{
    private _tile = _x;

    if (_tile getOrDefault ["offPage", false]) then {continue};

    {ctrlDelete _x} forEach (_tile getOrDefault ["controls", []]);

    {
        _tile deleteAt _x;
    } forEach _gone;

    _tile set ["offPage", true];
    _tile set ["controls", []];
} forEach _tiles;

// Whatever else the tiles made: every control of the compartment's tiles, the ones a tile no longer names too.
{ctrlDelete _x} forEach (_grid getOrDefault ["tileControls", []]);
_grid set ["tileControls", []];

{ctrlDelete _x} forEach (_grid getOrDefault ["panel", []]);

[_grid, _window select 0, _shownTo] call FUNC(setWindow);

(_grid get "rel") params ["_left", "_top"];

_grid set ["panel", [_display, _parent, [_left, _top], _grid get "cols", _window select 0, _shownTo, _grid getOrDefault ["holes", []], GVAR(theme), _grid getOrDefault ["pageHeight", 0]] call FUNC(drawPagePanel)];

// The tiles of the page that shows now: drawn where they lie, in the place they have on the grid already. Each is the very
// HashMap the grid holds (taken by its number, never from a copy of the list - the controls and the box it gets are the grid's
// tile's own, so the search's fading, the hover and the selection find them).
private _count = count _tiles;

for "_index" from 0 to (_count - 1) do {
    private _tile = _tiles select _index;

    if !(_tile getOrDefault ["offPage", false]) then {continue};

    private _row = _tile getOrDefault ["row", 0];

    if (_row < (_window select 0) || {_row >= (_window select 1)}) then {continue};

    _tile deleteAt "offPage";
    [_display, _grid, _tile, GVAR(theme)] call FUNC(createTile);

    // createTile added it at the end of the list: it stands where it stood already.
    _tiles deleteAt (count _tiles - 1);
};

// Every tile of the rows that show has to be drawn now: one that is still bare here would show no fading, no outline and no selection.
private _undrawn = _tiles select {
    (_x getOrDefault ["offPage", false]) && {(_x getOrDefault ["row", 0]) >= (_window select 0)} && {(_x getOrDefault ["row", 0]) < (_window select 1)}
};

if (_undrawn isNotEqualTo []) then {
    INFO_1("A paged box left %1 tiles of its page undrawn",count _undrawn);
};

[_display, _grid] call FUNC(drawCells);
[_display, _grid] call FUNC(drawPageBar);

// What lay over the tiles that went, and the mouse: as a redraw of tiles leaves them.
call FUNC(drawPending);
[] call FUNC(drawSelection);

if (GVAR(filter) isNotEqualTo "" || {GVAR(groupFilters) isNotEqualTo []}) then {
    [] call FUNC(applyFilter);
};

if ((uiNamespace getVariable [QGVAR(menu), []]) isNotEqualTo []) then {
    call FUNC(closeMenu);
};

{ctrlDelete _x} forEach (uiNamespace getVariable [QGVAR(hoverRing), []]);
uiNamespace setVariable [QGVAR(hoverRing), []];

// Where this box's cells lie changed with its window: the hover's picture of the grids is worked out again.
uiNamespace setVariable [QGVAR(hoverGeom), []];
uiNamespace setVariable [QGVAR(hoverHold), []];
GVAR(hover) = [];
GVAR(lastClick) = [[], -1];
GVAR(lastMouse) = [];
