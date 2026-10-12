#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The window closed: the soldier stands up from his gear into the plain state of the stance he had when it
 * opened (fnc_restState), with the weapon in his hands now. Only while he is still bent over his gear - ours,
 * or a gear pose someone started meanwhile, such as ACE's magazine repack: any other animation has taken
 * over already (ACE's unconscious state, a captive's pose, a mod's move) and is never fought. Nothing for a
 * dead or unconscious soldier, one in a vehicle or not local, nor for one taken from the loot (a captive, carrying,
 * dragging - GVAR(closeReason) "taken").
 *
 * Closed by a movement key (GVAR(closeReason) "move"): the key still held walks him out of the pose by
 * itself, so nothing is played; only a tap that moved nothing stands him up, POSE_MOVE_GRACE seconds later.
 *
 * Also forgets the pose, the stance and the reason of this window.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_gui_fnc_poseEnd;
 *
 * Public: No
 */

private _reason = GVAR(closeReason);
private _stance = GVAR(openStance);
private _unit = GVAR(unit);

GVAR(closeReason) = "";
GVAR(openStance) = "";
GVAR(pose) = [];

if ((missionNamespace getVariable [QGVAR(animation), 1]) == 0 || {_stance isEqualTo ""}) exitWith {};
if (isNull _unit || {!local _unit} || {!alive _unit} || {!isNull objectParent _unit}) exitWith {};
if !([_unit] call ACEFUNC(common,isAwake)) exitWith {};

// Taken from the loot (fnc_poseCheck): by ACE's captives or carrying, whose animation may not have started
// yet this frame - standing him up now would play over it.
if (
    _reason isEqualTo "taken"
    || {_unit getVariable [QACEGVAR(captives,isHandcuffed), false]}
    || {_unit getVariable [QACEGVAR(captives,isSurrendering), false]}
    || {_unit getVariable [QACEGVAR(captives,isEscorting), false]}
    || {_unit getVariable [QACEGVAR(dragging,isDragging), false]}
    || {_unit getVariable [QACEGVAR(dragging,isCarrying), false]}
) exitWith {};

// Only while the soldier is still bent over his gear - ours, or a gear pose someone started meanwhile (ACE's
// repack in the window). Anything else has taken over already and is never fought.
if !([animationState _unit] call FUNC(isPoseAnim)) exitWith {};

private _rest = [_unit, _stance] call FUNC(restState);

if (_rest isEqualTo "") exitWith {};

// Closed by a movement key: the held key walks him out by itself. Only a tap that moved nothing stands him up.
if (_reason isEqualTo "move") exitWith {
    [{
        params ["_unit", "_rest", "_token"];

        if (
            GVAR(poseToken) == _token && {alive _unit}
            && {isNull (uiNamespace getVariable [QGVAR(display), displayNull])}
            && {[animationState _unit] call FUNC(isPoseAnim)}
        ) then {
            _unit playMoveNow _rest;
        };
    }, [_unit, _rest, GVAR(poseToken)], POSE_MOVE_GRACE] call FUNC(delay);
};

_unit playMoveNow _rest;
