#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an animation is the soldier bent over his gear: Arma's inventory states (they start with
 * "ainvp" and have no "_amovp" in them - the pose, its variants where the hands fiddle, and ACE's "Gear" of
 * the magazine repack), or the way into them (it starts with "amovp" and has "_ainvp" in it).
 *
 * Arguments:
 * 0: The animation state <STRING>
 *
 * Return Value:
 * It is the pose, or on its way <BOOL>
 *
 * Example:
 * [animationState player] call einv_gui_fnc_isPoseAnim;
 *
 * Public: No
 */

params [["_anim", "", [""]]];

private _lower = toLowerANSI _anim;

(((_lower select [0, 5]) isEqualTo "ainvp") && {(_lower find "_amovp") < 0})
|| {((_lower select [0, 5]) isEqualTo "amovp") && {(_lower find "_ainvp") >= 0}}
