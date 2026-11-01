#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts the modding view's points onto the 3D picture (fnc_drawHotspots): each part's place in the scene
 * (fnc_weaponPoints) seen from the camera, by hand - a picture-in-picture camera has no worldToScreen. The camera's
 * frame: forward to what it aims at, right level with the ground, up square to both; a point's place across and up
 * divided by how far ahead it is, against the field of view - INSPECT_3D_FOV the tangent of half the view's height,
 * twice that across, as the texture is twice as wide as high (INSPECT_3D_RES). Then into the picture's area.
 *
 * A point that turns away behind the camera or out of the picture is hidden, as is one that would lie on the 2D/3D
 * switch - a focused button is drawn over everything, and a point lying there took its clicks. Points that fall on
 * each other are moved apart, the later one down. Run every frame the inspect card is open (fnc_onFrame): nothing is
 * done while the view stands as it stood, the points are known (or no longer looked for) and the card did not move.
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
private _signature = [_cameraPos, _target, count _points];

if (_signature isEqualTo (uiNamespace getVariable [QGVAR(hotspotLast), []])) exitWith {};

uiNamespace setVariable [QGVAR(hotspotLast), _signature];

(uiNamespace getVariable [QGVAR(hotspotView), [[], []]]) params [["_view", []], ["_blocked", []]];

if (count _view < 4) exitWith {};

_view params ["_viewX", "_viewY", "_viewW", "_viewH"];

private _forward = vectorNormalized (_target vectorDiff _cameraPos);
private _right = vectorNormalized (_forward vectorCrossProduct [0, 0, 1]);
private _up = _right vectorCrossProduct _forward;
private _tanV = INSPECT_3D_FOV;
private _tanH = INSPECT_3D_FOV * ((INSPECT_3D_RES select 0) / (INSPECT_3D_RES select 1));
private _placed = [];

private _fnc_overlaps = {
    params ["_a", "_b"];

    (_a select 0) < (_b select 0) + (_b select 2) && {(_b select 0) < (_a select 0) + (_a select 2)}
    && {(_a select 1) < (_b select 1) + (_b select 3)} && {(_b select 1) < (_a select 1) + (_a select 3)}
};

{
    private _spot = _x;
    private _ctrl = _spot get "ctrl";
    private _point = _points getOrDefault [_spot get "part", []];

    (_spot get "rel") params ["", "", "_spotW", "_spotH"];

    private _show = false;

    if (count _point == 3) then {
        private _offset = _point vectorDiff _cameraPos;
        private _ahead = _offset vectorDotProduct _forward;

        if (_ahead <= 0.01) exitWith {};

        private _across = (_offset vectorDotProduct _right) / (_ahead * _tanH);
        private _upward = (_offset vectorDotProduct _up) / (_ahead * _tanV);
        private _rect = [
            _viewX + _viewW * (0.5 + _across / 2) - _spotW / 2,
            _viewY + _viewH * (0.5 - _upward / 2) - _spotH / 2,
            _spotW, _spotH
        ];

        // Apart from the ones placed before it: below the one it falls on.
        {
            if ([_rect, _x] call _fnc_overlaps) then {
                _rect set [1, (_x select 1) + (_x select 3) + pixelH * 2];
            };
        } forEach _placed;

        _rect params ["_rectX", "_rectY"];

        if (_rectX < _viewX || {_rectY < _viewY} || {_rectX + _spotW > _viewX + _viewW} || {_rectY + _spotH > _viewY + _viewH}) exitWith {};
        if (_blocked findIf {[_rect, _x] call _fnc_overlaps} >= 0) exitWith {};

        _ctrl ctrlSetPosition [_rectX, _rectY, _spotW, _spotH];
        _ctrl ctrlCommit 0;
        _spot set ["rel", _rect];
        _placed pushBack _rect;
        _show = true;
    };

    _ctrl ctrlShow _show;
} forEach _spots;
