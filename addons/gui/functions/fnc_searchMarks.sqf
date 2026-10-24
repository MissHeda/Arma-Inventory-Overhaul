#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Every frame while something is searched (fnc_animateSearch): the hidden item each box is at right now shows it - an
 * accent outline round its tile and a bar along its foot that fills as its time runs. A click on a hidden item
 * (fnc_searchFirst) moves it there at once, so the click is seen to do something. GVAR(searchMarks) holds one mark per run,
 * [entry, the tile's first control, outline and track controls, fill control, the fill's full width]; a mark whose entry no
 * box is at any more goes, and one whose tile was drawn anew (its first control gone) is made again over the new tile. Only
 * the fill's width changes from frame to frame.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Now, diag_tickTime <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, diag_tickTime] call einv_gui_fnc_searchMarks;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_now"];

private _marks = [];

{
    _x params ["", "_head", "_started", "_took"];

    // The seal has no tile: the caption's chip tells it.
    if ((_head select 1) isEqualTo "") then {continue};

    private _at = GVAR(searchMarks) findIf {(_x select 0) isEqualTo _head};
    private _mark = [];

    if (_at >= 0) then {
        _mark = GVAR(searchMarks) deleteAt _at;

        // The tile was drawn anew, or the window built again: made again over the new one.
        if (isNull (_mark select 1) || {isNull (_mark select 3)}) then {
            {ctrlDelete _x} forEach (_mark select 2);
            ctrlDelete (_mark select 3);
            _mark = [];
        };
    };

    if (_mark isEqualTo []) then {
        private _found = _head call FUNC(findTile);

        if (_found isEqualTo []) then {continue};

        _found params ["_grid", "_tile"];

        private _first = (_tile getOrDefault ["controls", []]) param [0, controlNull];

        if (isNull _first) then {continue};

        private _parent = _grid get "parent";
        private _accent = GVAR(theme) getOrDefault ["accent", [1, 1, 1, 1]];

        (_tile getOrDefault ["rect", [0, 0, 0, 0]]) params ["_left", "_top", "_width", "_height"];

        // Along the foot, inside the outline: a few pixels high, a little in from the sides.
        private _barH = (pixelH * 4) max (_height * 0.08);
        private _barX = _left + pixelW * 4;
        private _barW = (_width - pixelW * 8) max pixelW;
        private _barY = _top + _height - _barH - pixelH * 4;
        private _controls = [_display, _parent, [_left, _top, _width, _height], _accent, [], 2] call FUNC(uiOutline);

        _controls append ([_display, _parent, [_barX, _barY, _barW, _barH], [0, 0, 0, 0.55]] call FUNC(uiPanel));

        private _fill = ([_display, _parent, [_barX, _barY, _barW, _barH], _accent] call FUNC(uiPanel)) select 0;

        _mark = [_head, _first, _controls, _fill, _barW];
    };

    private _fill = _mark select 3;

    _fill ctrlSetPositionW (((_mark select 4) * (((_now - _started) / (_took max 0.05)) max 0 min 1)) max pixelW);
    _fill ctrlCommit 0;

    _marks pushBack _mark;
} forEach GVAR(searchRuns);

// What no box is at any more: found, stopped, or the box gone.
{
    {ctrlDelete _x} forEach (_x select 2);
    ctrlDelete (_x select 3);
} forEach GVAR(searchMarks);

GVAR(searchMarks) = _marks;
