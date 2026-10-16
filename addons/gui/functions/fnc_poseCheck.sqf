#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Looks after the looting pose at each check of the open window (fnc_onFrame, every CHECK_INTERVAL seconds,
 * after the checks whether the window should stay open at all).
 *
 *   - The soldier was taken away from the loot - into a vehicle, handcuffed or surrendering by ACE,
 *     dragging or carrying, or moved more than POSE_LEASH metres from where the window opened: the window
 *     closes (GVAR(closeReason) "taken", so no sound of a container closing and no end move). Seated, the
 *     vehicle moves him and the leash is not asked: the vehicle he sits in (and the crates of its ACE
 *     cargo) goes along, and anything else he opened from the seat is held to the window's reach from
 *     where he sits now (einv_storage_fnc_inReach).
 *   - No pose yet while a search runs (piles nearby being searched): started late, once per window.
 *   - The pose reached: the camera finds the soldier again, kneeling or bent over his gear.
 *   - Out of the pose and back in a plain stance - a weapon came into or left the hands: back into the
 *     pose, POSE_REENTRIES times at most. Anything else is another animation taking over - ACE's
 *     unconscious state, a mod's move: left alone, the pose forgotten.
 *   - A reload in the window (fnc_reloadGesture) stepped out of the pose or plays beside it: nothing pulls
 *     the soldier into the pose before GVAR(reloadHold) - the pose would cut the reload. Back into it then,
 *     which is not one of the weapon changes counted.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * It closed the window <BOOL>
 *
 * Example:
 * [_display] call einv_gui_fnc_poseCheck;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

// The Arsenal and later editor windows have no pose.
if !([] call FUNC(isInventoryMode)) exitWith {false};

private _unit = GVAR(unit);

// Taken away from the loot - into a vehicle, by ACE's captives or carrying, or moved off by anything at all.
// Seated, not by metres: the vehicle he sits in goes along (einv_storage_fnc_inReach is true for it), anything
// else outside is left behind once out of the window's reach.
if (!isNull GVAR(openedOn) && {
    objectParent _unit isNotEqualTo GVAR(openParent)
    || {_unit getVariable [QACEGVAR(captives,isHandcuffed), false]}
    || {_unit getVariable [QACEGVAR(captives,isSurrendering), false]}
    || {_unit getVariable [QACEGVAR(dragging,isDragging), false]}
    || {_unit getVariable [QACEGVAR(dragging,isCarrying), false]}
    || {isNull GVAR(openParent) && {(_unit distance2D (ASLToAGL GVAR(openPos))) > POSE_LEASH}}
    || {!isNull GVAR(openParent) && {!([_unit, GVAR(openedOn)] call EFUNC(storage,inReach))}}
}) exitWith {
    ["taken"] call FUNC(closeDisplay);
    true
};

// While looting, a search that started later brings the pose along (nearby piles) - tried once per window.
if (GVAR(pose) isEqualTo []) exitWith {
    if (
        (missionNamespace getVariable [QGVAR(animation), 0]) == 1 && {!GVAR(poseTried)} && {GVAR(searchQueue) isNotEqualTo []}
        && {diag_tickTime >= GVAR(reloadHold)}
    ) then {
        [_unit, GVAR(openedOn)] call FUNC(poseStart);
    };

    false
};

GVAR(pose) params ["", "", "", "_startedAt", "", "_reached", "_reentries"];

private _anim = animationState _unit;

if ([_anim] call FUNC(isPoseAnim)) exitWith {
    // Arrived: the camera finds the soldier again, kneeling or bent over his gear.
    if (!_reached && {(toLowerANSI (_anim select [0, 5])) isEqualTo "ainvp"}) then {
        GVAR(pose) set [5, true];

        if (!isNull GVAR(camera) && {GVAR(cameraRect) isNotEqualTo []}) then {
            [_unit, GVAR(cameraRect)] call FUNC(cameraStart);
        };
    };

    false
};

// A reload runs (fnc_reloadGesture): the pose waits for it. Once it had its time, the way back into the pose
// below is not counted as a weapon change.
if (GVAR(reloadHold) > 0) then {
    if (diag_tickTime < GVAR(reloadHold)) exitWith {};

    GVAR(reloadHold) = 0;
    _reentries = (_reentries - 1) max 0;
    GVAR(pose) set [6, _reentries];
};

if (diag_tickTime < GVAR(reloadHold)) exitWith {false};

private _late = diag_tickTime - _startedAt > POSE_REACH_TIME;

// Out of the pose and back in a plain stance - a weapon came into or left the hands: back into the pose,
// three times at most. Anything else is someone else's animation: left alone, the pose forgotten.
if ((_reached || _late) && {_reentries < POSE_REENTRIES} && {[_unit] call FUNC(canPose)}) exitWith {
    private _new = [_unit, stance _unit] call FUNC(poseState);

    if (_new isEqualTo "") exitWith {
        GVAR(pose) = [];
        false
    };

    GVAR(pose) set [2, _new];
    GVAR(pose) set [3, diag_tickTime];
    GVAR(pose) set [5, false];
    GVAR(pose) set [6, _reentries + 1];
    _unit playMoveNow _new;
    false
};

if (_reached || _late) then {
    GVAR(pose) = [];
};

false
