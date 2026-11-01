#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts the modding view's points onto the 3D picture (fnc_drawHotspots): each part's place in the scene
 * (fnc_weaponPoints) seen from the camera. Filmed with the main view (Modify, fnc_inspect3D), the game says where:
 * worldToScreen, into the card's space. Into Picture-in-Picture's texture by hand, as it has no worldToScreen. The camera's
 * frame: forward to what it aims at, right level with the ground, up square to both; a point's place across and up
 * divided by how far ahead it is, against the field of view - INSPECT_3D_FOV the tangent of half the view's height,
 * twice that across, as the texture is twice as wide as high (INSPECT_3D_RES). Then into the picture's area.
 *
 * The boxes lie in two rows off the weapon, as in Tarkov's weapon builds: the parts above it - sights, muzzle, rail - in a
 * row over the highest of the places, the bipod and the magazines in one under the lowest; along its row each box sits
 * over (or under) its own place as far as the boxes left of it let it, the row kept inside the picture. A line runs from
 * the box to a dot on the place. A part whose place turns away behind the camera or out of the picture is hidden with its
 * line and dot, as is a box that would lie on the 2D/3D switch - a focused button is drawn over everything, and a box
 * lying there took its clicks. Run every frame the inspect card is open (fnc_onFrame), whether the view changed or not:
 * placed only when it changed, boxes made in the same frame stayed hidden now and then.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_gui_fnc_placeHotspots;
 *
 * Public: No
 */

disableSerialization;

private _spots = (uiNamespace getVariable [QGVAR(hotspots), []]) select {_x get "floating"};

if (_spots isEqualTo []) exitWith {};

private _scene = GVAR(scene3D);

if (count _scene == 0 || {!("cameraPos" in _scene)}) exitWith {};

private _points = [_scene] call FUNC(weaponPoints);

// The holder's model is still loading: the points are asked for again next frame.
if (isNil "_points") exitWith {};

private _cameraPos = _scene get "cameraPos";
private _target = _scene get "target";

(uiNamespace getVariable [QGVAR(hotspotView), [[], []]]) params [["_view", []], ["_blocked", []]];

if (count _view < 4) exitWith {};

_view params ["_viewX", "_viewY", "_viewW", "_viewH"];

private _forward = vectorNormalized (_target vectorDiff _cameraPos);
private _right = vectorNormalized (_forward vectorCrossProduct [0, 0, 1]);
private _up = _right vectorCrossProduct _forward;
private _tanV = INSPECT_3D_FOV;
private _tanH = INSPECT_3D_FOV * ((INSPECT_3D_RES select 0) / (INSPECT_3D_RES select 1));
private _main = (_scene getOrDefault ["main", []]) isNotEqualTo [];
(ctrlPosition (uiNamespace getVariable [QGVAR(inspectGroup), controlNull])) params [["_cardX", 0], ["_cardY", 0]];

// ----- Each part's place in the card, the middle of its dot -----
private _onCard = [];

{
    private _point = _points getOrDefault [_x get "part", []];
    private _at = [];

    if (count _point == 3) then {
        if (_main) then {
            private _onScreen = worldToScreen (ASLToAGL _point);

            if (_onScreen isEqualTo []) exitWith {};

            _at = [(_onScreen select 0) - _cardX, (_onScreen select 1) - _cardY];
        } else {
            private _offset = _point vectorDiff _cameraPos;
            private _ahead = _offset vectorDotProduct _forward;

            if (_ahead <= 0.01) exitWith {};

            _at = [
                _viewX + _viewW * (0.5 + ((_offset vectorDotProduct _right) / (_ahead * _tanH)) / 2),
                _viewY + _viewH * (0.5 - ((_offset vectorDotProduct _up) / (_ahead * _tanV)) / 2)
            ];
        };
    };

    // Outside the picture it is no place to point at.
    if (_at isNotEqualTo [] && {
        (_at select 0) < _viewX || {(_at select 0) > _viewX + _viewW} || {(_at select 1) < _viewY} || {(_at select 1) > _viewY + _viewH}
    }) then {
        _at = [];
    };

    _onCard pushBack _at;
} forEach _spots;

private _known = _onCard select {_x isNotEqualTo []};

// ----- The boxes in two rows, over the weapon and under it, each under or over its own place as far as they let each other -----
private _boxW = ((_spots select 0) get "rel") select 2;
private _boxH = ((_spots select 0) get "rel") select 3;
private _gapX = SQUARE(TEXT_UNIT * 0.25);
private _lift = TEXT_UNIT * 2.2;
private _highest = _viewY + _viewH;
private _lowest = _viewY;

{
    _highest = _highest min (_x select 1);
    _lowest = _lowest max (_x select 1);
} forEach _known;

private _rowAbove = ((_highest - _lift - _boxH) max (_viewY + pixelH * 2)) min (_viewY + _viewH - _boxH);
private _rowBelow = ((_lowest + _lift) min (_viewY + _viewH - _boxH - pixelH * 2)) max _viewY;

{
    _x params ["_below", "_rowY"];

    // This row's boxes from the left, each as near its place as the one before leaves room, then the row pushed back into
    // the picture from the right edge.
    private _row = [];

    {
        private _at = _onCard select _forEachIndex;

        if (_at isNotEqualTo [] && {(_x get "below") isEqualTo _below}) then {
            _row pushBack [_at select 0, _forEachIndex];
        };
    } forEach _spots;

    _row sort true;

    private _lefts = [];
    private _next = _viewX + pixelW * 2;

    {
        private _left = ((_x select 0) - _boxW / 2) max _next;

        _lefts pushBack _left;
        _next = _left + _boxW + _gapX;
    } forEach _row;

    private _over = (_next - _gapX) - (_viewX + _viewW - pixelW * 2);

    if (_over > 0) then {
        private _room = _viewX + _viewW - pixelW * 2;

        for "_i" from (count _lefts - 1) to 0 step -1 do {
            private _left = (_lefts select _i) min (_room - _boxW);

            _lefts set [_i, _left];
            _room = _left - _gapX;
        };
    };

    {
        _x params ["", "_index"];

        private _spot = _spots select _index;
        private _rect = [_lefts select _forEachIndex, _rowY, _boxW, _boxH];

        _spot set ["rel", _rect];
        (_spot get "ctrl") ctrlSetPosition _rect;
        (_spot get "ctrl") ctrlCommit 0;
    } forEach _row;
} forEach [[false, _rowAbove], [true, _rowBelow]];

// ----- Shown with their line and dot, or hidden with them -----
private _fnc_overlaps = {
    params ["_a", "_b"];

    (_a select 0) < (_b select 0) + (_b select 2) && {(_b select 0) < (_a select 0) + (_a select 2)}
    && {(_a select 1) < (_b select 1) + (_b select 3)} && {(_b select 1) < (_a select 1) + (_a select 3)}
};

{
    private _spot = _x;
    private _at = _onCard select _forEachIndex;
    private _ctrl = _spot get "ctrl";
    private _line = _spot getOrDefault ["line", []];
    private _dot = _spot getOrDefault ["dot", controlNull];
    private _show = _at isNotEqualTo [] && {_blocked findIf {[_spot get "rel", _x] call _fnc_overlaps} < 0};

    _ctrl ctrlShow _show;
    _dot ctrlShow _show;

    {_x ctrlShow _show} forEach _line;

    if (!_show) then {continue};

    (_spot get "rel") params ["_boxX", "_boxY", "_width", "_height"];
    _at params ["_atX", "_atY"];

    // The line from the middle of the box's edge facing the weapon to the dot: down (or up) to halfway, across, on to the dot.
    private _fromX = _boxX + _width / 2;
    private _fromY = [_boxY + _height, _boxY] select (_spot get "below");
    private _halfY = (_fromY + _atY) / 2;

    {
        _x params ["_piece", "_rect"];

        _piece ctrlSetPosition _rect;
        _piece ctrlCommit 0;
    } forEach [
        [_line select 0, [_fromX, _fromY min _halfY, pixelW, abs (_halfY - _fromY) max pixelH]],
        [_line select 1, [_fromX min _atX, _halfY, (abs (_atX - _fromX)) max pixelW, pixelH]],
        [_line select 2, [_atX, _halfY min _atY, pixelW, abs (_atY - _halfY) max pixelH]]
    ];

    (ctrlPosition _dot) params ["", "", "_dotW", "_dotH"];

    _dot ctrlSetPosition [_atX - _dotW / 2, _atY - _dotH / 2];
    _dot ctrlCommit 0;
} forEach _spots;
