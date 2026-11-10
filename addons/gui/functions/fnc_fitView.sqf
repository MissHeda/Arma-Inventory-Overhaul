#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a scene's camera has to look and how far off it has to stand so that a box - a weapon with what it carries
 * (fnc_weaponBounds) - lies in the middle of its picture and just fills a part of it: the box's corners seen from the camera's
 * side are put in the middle, and the camera stands so far off that they reach the given share of the view across or up and
 * down, whichever they reach first. Found in a few rounds: moving the camera changes how the corners lie in its view.
 *
 * The camera looks along -[sin dir, cos dir] and down by its pitch, as fnc_cardScene and fnc_inspect3D place it.
 *
 * Arguments:
 * 0: The box's corners in the world (ASL) <ARRAY>
 * 1: The camera's direction round the box, in degrees <NUMBER>
 * 2: Its pitch, in degrees above the box <NUMBER>
 * 3: How far the box may reach across from the middle of the view, as a share of the distance (a tangent) <NUMBER>
 * 4: The same up and down <NUMBER>
 *
 * Return Value:
 * [what to look at (ASL), distance, how wide the box is across the view in metres] <ARRAY>, [] without corners
 *
 * Example:
 * [_corners, 45, 6, 0.4, 0.2] call aio_gui_fnc_fitView;
 *
 * Public: No
 */

params [["_corners", [], [[]]], ["_dir", 0, [0]], ["_pitch", 0, [0]], ["_tanH", 0.4, [0]], ["_tanV", 0.2, [0]]];

if (_corners isEqualTo []) exitWith {[]};

private _forward = [-(sin _dir) * (cos _pitch), -(cos _dir) * (cos _pitch), -(sin _pitch)];
private _right = [-(cos _dir), sin _dir, 0];
private _up = _right vectorCrossProduct _forward;

private _target = [0, 0, 0];

{
    _target = _target vectorAdd _x;
} forEach _corners;

_target = _target vectorMultiply (1 / count _corners);

private _distance = 2;
private _across = 1;

for "_round" from 1 to 5 do {
    private _camera = _target vectorDiff (_forward vectorMultiply _distance);
    private _acrossAll = [];
    private _upAll = [];

    {
        private _offset = _x vectorDiff _camera;
        private _ahead = (_offset vectorDotProduct _forward) max 0.05;

        _acrossAll pushBack ((_offset vectorDotProduct _right) / _ahead);
        _upAll pushBack ((_offset vectorDotProduct _up) / _ahead);
    } forEach _corners;

    private _halfAcross = ((selectMax _acrossAll) - (selectMin _acrossAll)) / 2;
    private _halfUp = ((selectMax _upAll) - (selectMin _upAll)) / 2;

    _target = _target
        vectorAdd (_right vectorMultiply (((selectMax _acrossAll) + (selectMin _acrossAll)) / 2 * _distance))
        vectorAdd (_up vectorMultiply (((selectMax _upAll) + (selectMin _upAll)) / 2 * _distance));
    _across = 2 * _halfAcross * _distance;
    _distance = (_distance * ((_halfAcross / (_tanH max 0.001)) max (_halfUp / (_tanV max 0.001)))) max 0.05;
};

[_target, _distance, _across]
