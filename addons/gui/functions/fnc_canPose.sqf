#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the soldier may be put into the looting pose or taken out of it: a living, awake, local unit on
 * foot in a plain state - standing, kneeling or lying, still or moving, the weapon raised, lowered or
 * none - or already in the inventory pose. ACE's own states win, always: a captive, someone surrendering,
 * escorting a captive, dragging or carrying keeps the animation ACE gave him. Not swimming, not with a
 * bipod deployed, not with the binocular in his hands, and not on a ladder, on a parachute, in a cutscene
 * move or between two states (a "_" in the name of the animation).
 *
 * Arguments:
 * 0: The unit <OBJECT>
 *
 * Return Value:
 * It may <BOOL>
 *
 * Example:
 * [player] call einv_gui_fnc_canPose;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!local _unit} || {!alive _unit} || {!isNull objectParent _unit}) exitWith {false};

if !([_unit] call ACEFUNC(common,isAwake)) exitWith {false};

// ACE's own states win: a captive, someone surrendering, escorting, dragging or carrying keeps ACE's animation.
if (
    _unit getVariable [QACEGVAR(captives,isHandcuffed), false]
    || {_unit getVariable [QACEGVAR(captives,isSurrendering), false]}
    || {_unit getVariable [QACEGVAR(captives,isEscorting), false]}
    || {_unit getVariable [QACEGVAR(dragging,isDragging), false]}
    || {_unit getVariable [QACEGVAR(dragging,isCarrying), false]}
) exitWith {false};

if (([_unit] call ACEFUNC(common,isSwimming)) || {isWeaponDeployed _unit}) exitWith {false};

if (currentWeapon _unit isNotEqualTo "" && {currentWeapon _unit isEqualTo binocular _unit}) exitWith {false};

// Plain on foot only: standing, kneeling or lying, still or moving, weapon raised, lowered or none - or
// already in the inventory pose. Not a ladder, a parachute, a cutscene move, ACE's carry or surrender
// states, nor anything on its way between two states (a "_" in the name).
private _anim = toLowerANSI animationState _unit;

if ((_anim select [0, 5]) isEqualTo "ainvp") exitWith {true};

((_anim select [0, 5]) in ["amovp", "aidlp"])
&& {(_anim select [12, 4]) in ["sras", "slow", "snon"]}
&& {(_anim select [0, 5]) isEqualTo "aidlp" || {(_anim find "_") < 0}}
