#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The soldier reloads: a magazine went into the weapon in his hands through the window (fnc_playReload,
 * once the answer said it is in), and he plays that weapon's reload action as ACE does for its scripted
 * reloads (playActionNow with the weapon's reloadAction) - a swap through the window is no reload of the
 * engine, which would play nothing (a tester, 0.4.7: the sound played, the soldier did not move).
 *
 * Only for the player's own unit, where it is local, alive and awake, on foot, with that weapon in his
 * hands, while ACE's own reload does not run and ACE does not hold him (a captive, surrendering, escorting,
 * dragging or carrying). Not tied to the looting pose's setting: this is the reload, not the looting.
 *
 * Bent over his gear in the looting pose, the inventory states hold the weapon down and a reload would not
 * show; and the pose coming back (fnc_poseCheck) or ending as the window closes (fnc_poseEnd) would cut it.
 * So he first stands out of the pose into the plain state of his stance with the weapon raised
 * (fnc_restState), the action plays once he is out (at most RELOAD_STEP_OUT seconds later), and the pose
 * stays away RELOAD_HOLD seconds (GVAR(reloadHold)) - then he bends over his gear again, and that is not
 * one of the weapon changes the pose counts. Closed meanwhile, the window's end leaves him be: he is out of
 * the pose already, and the action still plays - the pose given back first, then the reload.
 *
 * Arguments:
 * 0: The unit <OBJECT>
 * 1: The weapon's reload action, from its config's reloadAction (or its second muzzle's) <STRING>
 *
 * Return Value:
 * It was played, or will be once he is out of the pose <BOOL>
 *
 * Example:
 * [player, "GestureReloadMX"] call einv_gui_fnc_reloadGesture;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_action", "", [""]]];

if (_action isEqualTo "" || {!([] call FUNC(isInventoryMode))}) exitWith {false};
if (isNull _unit || {_unit isNotEqualTo ACE_player} || {!local _unit} || {!alive _unit} || {!isNull objectParent _unit}) exitWith {false};
if !([_unit] call ACEFUNC(common,isAwake)) exitWith {false};

// ACE's own reload runs: its action stays. ACE's own states keep the animation ACE gave him.
if (
    missionNamespace getVariable [QACEGVAR(common,isReloading), false]
    || {_unit getVariable [QACEGVAR(captives,isHandcuffed), false]}
    || {_unit getVariable [QACEGVAR(captives,isSurrendering), false]}
    || {_unit getVariable [QACEGVAR(captives,isEscorting), false]}
    || {_unit getVariable [QACEGVAR(dragging,isDragging), false]}
    || {_unit getVariable [QACEGVAR(dragging,isCarrying), false]}
) exitWith {false};

GVAR(reloadHold) = diag_tickTime + RELOAD_HOLD;

if !([animationState _unit] call FUNC(isPoseAnim)) exitWith {
    _unit playActionNow _action;
    true
};

// Out of the pose first, weapon raised, in the stance the pose shows (kneeling at a low crate) - read from
// the state's name, AinvP<erc|knl|pne>..., which says it whatever stance makes of a gear state.
private _stance = switch ((toLowerANSI animationState _unit) select [4, 4]) do {
    case "pknl": {"CROUCH"};
    case "ppne": {"PRONE"};
    default {"STAND"};
};

private _rest = [_unit, _stance, true] call FUNC(restState);

if (_rest isEqualTo "") exitWith {
    GVAR(reloadHold) = 0;
    false
};

_unit playMoveNow _rest;
GVAR(reloadHold) = diag_tickTime + RELOAD_STEP_OUT + RELOAD_HOLD;

[{
    params ["_unit"];

    !alive _unit || {!([animationState _unit] call FUNC(isPoseAnim))}
}, {
    params ["_unit", "_action"];

    if (alive _unit && {local _unit} && {isNull objectParent _unit}) then {
        _unit playActionNow _action;
    };
}, [_unit, _action], RELOAD_STEP_OUT] call CBA_fnc_waitUntilAndExecute;

true
