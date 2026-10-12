#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts the camera where the orbit says every frame, with the soldier in the middle of the free space
 * between the panels (fnc_cameraRect), and works the mouse's gestures: turning (the right button held) and
 * moving the point it looks at (the left button held, see fnc_onMouseDown).
 *
 * The pose is ACE's own: the camera looks at a target point of the unit from DISTANCE away, turned by the
 * direction and the pitch (right drag; ACE's 0.75 of a turn for the width of the screen, 0.75 of 100
 * degrees for the height). It is plain vector maths on the unit's visual position and direction, so the
 * camera follows an animated soldier without a helper object. The soldier is moved into the middle of the
 * rectangle by shifting the camera along its own right and up vectors - which keeps him put while the
 * camera orbits, where an offset in the model's frame would drift.
 *
 * The left button moves the target point inside the soldier's bounding box with ACE's own sums (a drag of
 * the mouse is a step of the size of the box, the point never goes further from the middle than the box is
 * wide or lower than 20 cm above its floor); ACE's setting for an inverted camera turns the direction round.
 *
 * Arguments:
 * 0: Mouse position [x, y] <ARRAY>
 * 1: Time of the frame <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [getMousePosition, diag_tickTime] call einv_arsenal_fnc_cameraFrame;
 *
 * Public: No
 */

params [["_mouse", [0, 0], [[]]], ["_now", 0, [0]]];

private _camera = GVAR(camera);
private _unit = GVAR(center);

if (isNull _camera || {isNull _unit}) exitWith {};

// ----- Turning -----

GVAR(cameraPosition) params ["_distance", "_dirH", "_dirV", "_target"];

if (GVAR(cameraDrag) isNotEqualTo []) then {
    if (inputMouse 1 == 0) then {
        // Let go where no event reached.
        GVAR(cameraDrag) = [];
    } else {
        GVAR(cameraDrag) params ["_lastX", "_lastY"];
        _mouse params ["_mouseX", "_mouseY"];

        _dirH = _dirH + (_mouseX - _lastX) * 270;
        _dirV = (_dirV + (_mouseY - _lastY) * 75) max -89 min 89;

        GVAR(cameraDrag) = _mouse;
    };
};

// ----- Moving the point looked at -----

if (GVAR(cameraPan) isNotEqualTo []) then {
    if (inputMouse 0 == 0) then {
        // Let go where no event reached.
        GVAR(cameraPan) = [];
    } else {
        GVAR(cameraPan) params ["_panX", "_panY"];
        _mouse params ["_mouseX", "_mouseY"];

        private _inverted = missionNamespace getVariable [QACEGVAR(arsenal,camInverted), false];
        private _dX = [_mouseX - _panX, _panX - _mouseX] select _inverted;
        private _dY = [_mouseY - _panY, _panY - _mouseY] select _inverted;

        private _box = boundingBoxReal _unit;
        private _floor = _box select 0 select 2;
        private _top = _box select 1 select 2;
        private _size = sqrt (([_box select 0 select 0, _box select 0 select 1]) distance2D ([_box select 1 select 0, _box select 1 select 1]));

        // A step sideways, along the way the camera looks across, and up or down within the box.
        private _bearing = _dirH - 90;
        private _pointX = (_target select 0) + _dX * _size * sin _bearing;
        private _pointY = (_target select 1) + _dX * _size * cos _bearing;
        private _pointZ = (((_target select 2) - _dY * _size) max _floor) min _top;

        // Not further from the middle than the box is wide.
        private _radius = (sqrt (_pointX ^ 2 + _pointY ^ 2)) min _size;
        private _heading = _pointX atan2 _pointY;

        _target = [_radius * sin _heading, _radius * cos _heading, _pointZ max (_floor + 0.2)];

        GVAR(cameraPan) = _mouse;
    };
};

// Never closer than the soldier fits the free middle.
_distance = _distance max GVAR(cameraMinDistance);

GVAR(cameraPosition) = [_distance, _dirH, _dirV, _target];

// ----- The pose -----

private _direction = getDirVisual _unit + _dirH + 180;
private _pitch = -_dirV;

private _forward = [sin _direction * cos _pitch, cos _direction * cos _pitch, sin _pitch];
private _right = [cos _direction, -(sin _direction), 0];
private _up = _right vectorCrossProduct _forward;

// Where the soldier is to stand on the screen: in the middle of the rectangle. One pixel spans this many
// metres at the target's distance.
private _shiftX = 0;
private _shiftZ = 0;

if (GVAR(cameraRect) isNotEqualTo []) then {
    GVAR(cameraRect) params ["_rectX", "_rectY", "_rectW", "_rectH"];

    private _metresPerPixel = 2 * _distance * ARSENAL_FOV / (safezoneH / pixelH);

    _shiftX = ((safezoneX + safezoneW / 2) - (_rectX + _rectW / 2)) / pixelW * _metresPerPixel;
    _shiftZ = ((_rectY + _rectH / 2) - (safezoneY + safezoneH / 2)) / pixelH * _metresPerPixel;
};

private _focus = _unit modelToWorldVisualWorld _target;
private _position = _focus vectorAdd (_right vectorMultiply _shiftX) vectorAdd (_up vectorMultiply _shiftZ) vectorDiff (_forward vectorMultiply _distance);

_camera setPosASL _position;
_camera setVectorDirAndUp [_forward, _up];

// The weak light between the camera and the soldier, a little above his chest.
if (!isNull GVAR(cameraLight)) then {
    GVAR(cameraLight) setPosASL (_focus vectorDiff (_forward vectorMultiply (_distance * 0.6)) vectorAdd [0, 0, 0.4]);
};
