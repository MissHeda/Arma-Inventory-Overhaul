#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The soldier reloads: a magazine went into the weapon in his hands through the window (fnc_playReload,
 * once the answer said it is in), and he plays that weapon's reload action as ACE does for its scripted
 * reloads (playActionNow with the weapon's reloadAction) - a swap through the window is no reload of the
 * engine, which would play nothing (a tester, 0.4.7: the sound played, the soldier did not move).
 * Only for the player's own unit, where it is local, alive and awake, on foot, with that weapon in his
 * hands, while ACE's own reload does not run and ACE does not hold him (a captive, surrendering, escorting,
 * dragging or carrying).
 *
 * Arguments:
 * 0: The unit <OBJECT>
 * 1: The weapon's reload action, from its config's reloadAction (or its second muzzle's) <STRING>
 *
 * Return Value:
 * It was played <BOOL>
 *
 * Example:
 * [player, "GestureReloadMX"] call aio_gui_fnc_reloadGesture;
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

_unit playActionNow _action;

true
