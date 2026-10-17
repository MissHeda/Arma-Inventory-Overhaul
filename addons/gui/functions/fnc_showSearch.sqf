#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts the search on the tile being searched - the first of the queue (fnc_markHidden), as Tarkov
 * shows it: its "?" gives way to a magnifying glass that goes round in a small circle, over a ring
 * that fills while the time runs (fnc_animateSearch moves both). Made after every build of the window,
 * after the tiles of a section were drawn again (fnc_redrawTiles) and after an item was found and its tile
 * drawn anew in place (fnc_revealTile) - so the glass and ring of the item before go first: they lie in
 * the column's group, which a reveal in place does not make anew.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_gui_fnc_showSearch;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

// The last item's glass, ring and track - gone with their group after a build, still there otherwise - and
// its "?" back: a redraw of tiles keeps a tile that did not change (fnc_drawTiles), and the head of the
// queue may be another one now.
private _lastFx = uiNamespace getVariable [QGVAR(searchFx), []];

{ctrlDelete _x} forEach (_lastFx param [5, []]);
(_lastFx param [6, controlNull]) ctrlSetText "?";

uiNamespace setVariable [QGVAR(searchFx), []];

if (GVAR(searchQueue) isEqualTo []) exitWith {};

private _found = (GVAR(searchQueue) select 0) call FUNC(findTile);

if (_found isEqualTo []) exitWith {};

private _tile = _found select 1;
private _background = _tile getOrDefault ["background", controlNull];

if (isNull _background) exitWith {};

// On the tile, in its group, so it scrolls and clips with it.
private _parent = ctrlParentControlsGroup _background;
// Its box: a shaped tile's first surface is only its top row's first run (fnc_createTile).
(_tile getOrDefault ["rect", ctrlPosition _background]) params ["_left", "_top", "_width", "_height"];

private _size = ((_width / pixelW) min (_height / pixelH)) * SEARCH_RING_SIZE;
private _centerX = _left + _width / 2;
private _centerY = _top + _height / 2;
private _ringRect = [_centerX - _size * pixelW / 2, _centerY - _size * pixelH / 2, _size * pixelW, _size * pixelH];
private _glassSize = _size * SEARCH_GLASS_SIZE;

// The "?" gives way: its text only, as it may be the tile's surface as well (fnc_createTile).
private _mark = _tile getOrDefault ["mark", controlNull];

_mark ctrlSetText "";

private _theme = GVAR(theme);

// The track, the whole ring faint; the arc over it; the glass on top.
private _track = [_display, _parent, _ringRect, SEARCH_RING(SEARCH_FRAMES), _theme getOrDefault ["searchTrack", [1, 1, 1, 0.12]]] call FUNC(uiIcon);

private _arc = [_display, _parent, _ringRect, SEARCH_RING(1), _theme getOrDefault ["accent", [1, 1, 1, 1]]] call FUNC(uiIcon);
private _glass = [
    _display, _parent,
    [_centerX - _glassSize * pixelW / 2, _centerY - _glassSize * pixelH / 2, _glassSize * pixelW, _glassSize * pixelH],
    UI_TEX(icon_search_ca), _theme getOrDefault ["text", [1, 1, 1, 1]]
] call FUNC(uiIcon);

uiNamespace setVariable [QGVAR(searchFx), [_arc, _glass, [_centerX, _centerY], _size, 1, [_track, _arc, _glass], _mark]];
