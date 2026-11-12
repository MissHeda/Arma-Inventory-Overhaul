#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A scene's camera for a view of a weapon (fnc_weaponView): from the side view turned and pitched as the view says, the weapon's
 * box (fnc_weaponBounds) fitted to the picture from there (fnc_fitView), then moved and zoomed by the view. The weapon card
 * (fnc_cardScene) and the inspect card (fnc_inspect3D) both ask here, each with its own picture's shape - so a weapon turned and
 * zoomed in the one looks the same in the other, as far as their shapes allow.
 *
 * The move is in half a picture's width and height at the fitted distance, so it is the same share of either picture.
 *
 * Arguments:
 * 0: The box's corners in the world (ASL) <ARRAY>
 * 1: The camera's direction for the side view, the muzzle to the left, in degrees <NUMBER>
 * 2: The view [turn, pitch, zoom, across, up] <ARRAY>
 * 3: What the picture holds across from its middle, as a share of the distance (a tangent) <NUMBER>
 * 4: The same up and down <NUMBER>
 * 5: How much of the picture the fitted weapon fills, 0 to 1 <NUMBER> (default: 0.85)
 * 6: The least fitted distance - a small weapon is not blown up to the picture <NUMBER> (default: 0)
 *
 * Return Value:
 * [what to look at (ASL), distance, direction, pitch, how wide the weapon is across the view in metres] <ARRAY>, [] without corners
 *
 * Example:
 * [_corners, -180, [0, 6, 1, 0, 0], 0.4, 0.2] call aio_gui_fnc_viewCamera;
 *
 * Public: No
 */

params [
    ["_corners", [], [[]]], ["_sideDir", 0, [0]], ["_view", WEAPON_VIEW_PLAIN, [[]]], ["_tanH", 0.4, [0]], ["_tanV", 0.2, [0]],
    ["_room", 0.85, [0]], ["_least", 0, [0]]
];

if (_corners isEqualTo []) exitWith {[]};

_view params [["_turn", 0, [0]], ["_pitch", CARD_3D_PITCH, [0]], ["_zoom", 1, [0]], ["_across", 0, [0]], ["_above", 0, [0]]];

private _dir = _sideDir + _turn;

_pitch = (_pitch max -85) min 85;

([_corners, _dir, _pitch, _tanH * _room, _tanV * _room] call FUNC(fitView)) params ["_target", "_distance", "_wide"];

_distance = _distance max _least;

private _forward = [-(sin _dir) * (cos _pitch), -(cos _dir) * (cos _pitch), -(sin _pitch)];
private _right = [-(cos _dir), sin _dir, 0];
private _up = _right vectorCrossProduct _forward;

_target = _target
    vectorAdd (_right vectorMultiply (_across * _distance * _tanH))
    vectorAdd (_up vectorMultiply (_above * _distance * _tanV));

[_target, _distance / ((_zoom max WEAPON_VIEW_ZOOM_MIN) min WEAPON_VIEW_ZOOM_MAX), _dir, _pitch, _wide]
