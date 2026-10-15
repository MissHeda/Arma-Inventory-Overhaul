#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * After the looting pose: a weapon the soldier held raised when the window opened, found lowered once he is
 * out of the pose, is raised again - the pose must never leave him with a lowered weapon he did not lower (a
 * tester, 0.4.7). fnc_poseEnd stands him up with the weapon raised already; this catches what the engine made
 * of the way out all the same - the movement key he held walking him out of the gear state, a gear state that
 * let go late.
 *
 * Raised the way ACE raises a lowered rifle (ace_common_fnc_fixLoweredRifleAnimation): the plain raised state
 * of his stance (fnc_restState), played on his local unit - not the engine action "WeaponInHand", which ACE
 * does not use. Only standing still in a plain state: a stop state would halt a soldier who walks on, so a
 * moving one is looked at again until he stops. Looked at again every POSE_RAISE_STEP seconds while he is
 * still bent over his gear or a reload in the window runs (fnc_reloadGesture), at most the tries given; then
 * decided once. Nothing once another window opened or another pose started, nor for a soldier who is dead,
 * not local, in a vehicle, or whom ACE holds (fnc_canPose).
 *
 * Arguments:
 * 0: The unit <OBJECT>
 * 1: The pose token of the window that closed (GVAR(poseToken)) <NUMBER>
 * 2: Tries left <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, 3, 20] call einv_gui_fnc_raiseWeapon;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_token", -1, [0]], ["_tries", 0, [0]]];

if (GVAR(poseToken) != _token || {!isNull (uiNamespace getVariable [QGVAR(display), displayNull])}) exitWith {};
if (isNull _unit || {!local _unit} || {!alive _unit} || {!isNull objectParent _unit}) exitWith {};

private _anim = toLowerANSI animationState _unit;

// Not yet: still in the gear state or on the way out of it (a "_" in the name - an idle's variants have one
// too, and are no way anywhere), a reload running, or walking on.
if (
    diag_tickTime < GVAR(reloadHold) || {[_anim] call FUNC(isPoseAnim)}
    || {(_anim find "_") >= 0 && {(_anim select [0, 5]) isNotEqualTo "aidlp"}}
    || {(_anim select [8, 4]) isNotEqualTo "mstp"}
) exitWith {
    if (_tries > 1) then {
        [{_this call FUNC(raiseWeapon)}, [_unit, _token, _tries - 1], POSE_RAISE_STEP] call FUNC(delay);
    };
};

if (!weaponLowered _unit || {!([_unit] call FUNC(canPose))}) exitWith {};

private _stance = switch (_anim select [4, 4]) do {
    case "pknl": {"CROUCH"};
    case "ppne": {"PRONE"};
    default {"STAND"};
};

private _raised = [_unit, _stance, true] call FUNC(restState);

if (_raised isNotEqualTo "" && {(toLowerANSI _raised) isNotEqualTo _anim}) then {
    _unit playMoveNow _raised;
};
