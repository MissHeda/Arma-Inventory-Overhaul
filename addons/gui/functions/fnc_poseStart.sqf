#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts the soldier into Arma's own inventory pose while the window looks into something, so others see him
 * lower his weapon and look into his gear - kneeling at a body, at a pile on the ground and at a low crate,
 * standing at the rest - and the engine's gear moves, which the game itself plays when a soldier opens his
 * inventory, carry the variants where the hands fiddle. The state follows his stance and the weapon in his
 * hands (fnc_poseState). It is played on the local player's own unit, where it is local: the engine
 * carries it to every machine and to players who join later. No switchMove, no custom animation.
 *
 * The setting einv_gui_animation decides: Off never, While looting (the default) when the window was opened
 * on something or a search runs, Always for the own gear as well. fnc_canPose says whether ACE and the
 * soldier's state allow it at all; a pose refused or taken over by another animation is never forced back
 * (GVAR(poseTried)).
 *
 * Arguments:
 * 0: The unit <OBJECT>
 * 1: What the window was opened on, objNull for nothing <OBJECT> (default: objNull)
 *
 * Return Value:
 * The pose was started <BOOL>
 *
 * Example:
 * [player, cursorObject] call einv_gui_fnc_poseStart;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_target", objNull, [objNull]]];

GVAR(pose) = [];

private _mode = missionNamespace getVariable [QGVAR(animation), 1];

if (_mode == 0) exitWith {false};
if (_mode == 1 && {isNull _target} && {GVAR(searchQueue) isEqualTo []}) exitWith {false};

GVAR(poseTried) = true;

if !([_unit] call FUNC(canPose)) exitWith {false};

private _stance = stance _unit;
private _poseStance = _stance;

// Down on one knee at a body, a pile or a low crate - the soldier looks where the loot is.
if (_stance isEqualTo "STAND" && {[_unit, _target] call FUNC(isLowTarget)}) then {
    _poseStance = "CROUCH";
};

private _state = [_unit, _poseStance] call FUNC(poseState);

if (_state isEqualTo "") exitWith {false};

GVAR(poseToken) = GVAR(poseToken) + 1;
GVAR(pose) = [_unit, GVAR(openStance), _state, diag_tickTime, GVAR(poseToken), false, 0];

// Where the unit is local, so everyone sees it.
if !([animationState _unit] call FUNC(isPoseAnim)) then {
    _unit playMoveNow _state;
};

true
