#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Plays a gesture of the soldier in the window - the upper body only, which lets him screw a suppressor on
 * while he stands bent over his gear (CfgGesturesMale): GestureMountMuzzle / GestureDismountMuzzle. A
 * reload has its own way, out of the pose first (fnc_reloadGesture). An action that
 * is no gesture - launchers reload with a full-body move - is left out, so are the reload gestures lying
 * prone, which map to full-body moves that would throw the pose away, and everything while ACE's own reload
 * runs. Nothing in a window that attached (the Arsenal), without the animation setting, or when the
 * soldier may not be animated at all (fnc_canPose). Played where the unit is local, so everyone sees it.
 *
 * Arguments:
 * 0: The unit <OBJECT>
 * 1: The action, a gesture <STRING>
 *
 * Return Value:
 * It was played <BOOL>
 *
 * Example:
 * [player, "GestureReloadMX"] call einv_gui_fnc_gesture;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_action", "", [""]]];

private _lower = toLowerANSI _action;

// Upper body only (CfgGesturesMale): a reload or a suppressor, never a full-body move - launchers reload
// with ManActReloadAT, a move, and are left out by this.
if ((missionNamespace getVariable [QGVAR(animation), 1]) == 0 || {(_lower select [0, 7]) isNotEqualTo "gesture"}) exitWith {false};
if !([] call FUNC(isInventoryMode)) exitWith {false};
if !([_unit] call FUNC(canPose)) exitWith {false};

// Prone, the reload actions map to full-body moves (RifleReloadProneMX) - they would throw the pose away.
if ((_lower find "reload") >= 0 && {stance _unit isEqualTo "PRONE"}) exitWith {false};

// ACE's own reload runs (weaponState): its gesture stays.
if (missionNamespace getVariable [QACEGVAR(common,isReloading), false]) exitWith {false};

_unit playActionNow _action;

true
