#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Tells the camera where the soldier is to stand on the screen (the "camera" hook), and from what that
 * rectangle holds works out how close the camera may come, so that he never leaves it. An empty rectangle
 * is the middle of the screen; hidden panels give it the whole.
 *
 * The width the soldier needs is the worst over a full orbit - a rifle held sideways included -, from his
 * bounding box: twice the distance of its farthest corner from his axis. With the height, the metres per
 * pixel that fit both into the rectangle with a tenth to spare give the distance, from the same relation
 * the camera uses to put him in the middle of it (fnc_cameraFrame). An empty rectangle needs no distance:
 * the soldier stands behind the panels, which are see-through.
 *
 * Arguments:
 * 0: The free middle of the layout [x, y, w, h], or [] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[0.3, 0.1, 0.4, 0.8]] call einv_arsenal_fnc_cameraRect;
 *
 * Public: No
 */

params [["_rect", [], [[]]]];

if (count _rect != 4) then {
    _rect = [];
};

GVAR(cameraRect) = _rect;

private _unit = GVAR(center);

if (_rect isEqualTo [] || {isNull _unit}) exitWith {
    GVAR(cameraMinDistance) = 0;
};

_rect params ["", "", "_rectW", "_rectH"];

(boundingBoxReal _unit) params ["_low", "_high"];

private _reachX = (abs (_low select 0)) max (abs (_high select 0));
private _reachY = (abs (_low select 1)) max (abs (_high select 1));
private _spanW = 2 * sqrt (_reachX * _reachX + _reachY * _reachY);
private _spanH = (_high select 2) - (_low select 2);

private _metresPerPixel = 1.1 * ((_spanW / (_rectW / pixelW)) max (_spanH / (_rectH / pixelH)));

// The relation fnc_cameraFrame uses, solved for the distance.
GVAR(cameraMinDistance) = _metresPerPixel * (safezoneH / pixelH) / (2 * ARSENAL_FOV);

// Raised at once, also when the camera is already near.
GVAR(cameraPosition) set [0, (GVAR(cameraPosition) select 0) max GVAR(cameraMinDistance)];
