#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows how far the repack is on the tiles drawn for it (fnc_drawJob): each magazine's bar as long as its
 * rounds are, its rounds text, and the ring on the magazine being filled right now. Called after every step
 * of ACE's schedule and by fnc_drawJob. It skips whatever the overlay does not hold - after a tile was
 * lost the overlay is empty until the deferred stop.
 *
 * The ring is made as the search's is (aio_gui_fnc_showSearch): the track faint, the arc over it filling
 * with the time (fnc_onFrame), as big as SEARCH_RING_SIZE of the tile's shorter side, in the tile's group.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_magazines_fnc_showProgress;
 *
 * Public: No
 */

disableSerialization;

private _job = GVAR(job);

if (count _job == 0) exitWith {};

private _fx = uiNamespace getVariable [QGVAR(fx), createHashMap];
private _counts = _job get "counts";
private _capacity = _job get "capacity";

{
    _x params ["_fill", "_barW", "_amount", "_short"];

    private _rounds = _counts param [_forEachIndex, 0];

    if (!isNull _fill) then {
        _fill ctrlShow (_rounds > 0);
        _fill ctrlSetPositionW ((_barW * _rounds / _capacity) max pixelW);
        _fill ctrlCommit 0;
    };

    if (!isNull _amount) then {
        _amount ctrlSetText (if (_short) then {str _rounds} else {format ["%1/%2", _rounds, _capacity]});
    };
} forEach (_fx getOrDefault ["parts", []]);

// The ring sits on the magazine being filled.
private _receiving = _job get "receiving";

if (_receiving == (_fx getOrDefault ["ringOn", -1])) exitWith {};

{
    ctrlDelete _x;
} forEach (_fx getOrDefault ["ring", []]);

_fx set ["ring", []];
_fx set ["ringOn", -1];

private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];
private _place = (_fx getOrDefault ["tiles", []]) param [_receiving, []];

if (isNull _display || {_place isEqualTo []}) exitWith {};

_place params ["_parent", "_rect"];
_rect params ["_left", "_top", "_width", "_height"];

private _size = ((_width / pixelW) min (_height / pixelH)) * SEARCH_RING_SIZE;
private _ringRect = [_left + _width / 2 - _size * pixelW / 2, _top + _height / 2 - _size * pixelH / 2, _size * pixelW, _size * pixelH];
private _theme = EGVAR(gui,theme);

private _track = [
    _display, _parent, _ringRect, REPACK_RING(SEARCH_FRAMES), _theme getOrDefault ["searchTrack", [1, 1, 1, 0.12]]
] call EFUNC(gui,uiIcon);

private _step = (_fx getOrDefault ["step", 0]) max 1;
private _arc = [
    _display, _parent, _ringRect, REPACK_RING(_step), _theme getOrDefault ["accent", [1, 1, 1, 1]]
] call EFUNC(gui,uiIcon);

_fx set ["ring", [_track, _arc]];
_fx set ["ringOn", _receiving];

(_fx get "controls") append [_track, _arc];
