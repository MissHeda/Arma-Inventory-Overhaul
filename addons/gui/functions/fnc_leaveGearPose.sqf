#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes a soldier out of the engine's inventory pose. The engine's "Gear" action puts him into it (ainv..., e.g.
 * ainvpercmstpsraswrfldnon) and leaves it again only when its own inventory closes - which this mod never lets
 * open, or closes as it loads (fnc_guardVanilla). Left in it, he could not walk until something else (V) moved him
 * (Steam, issue #49: right after the start, before the handler was on the unit). Played back to the same stance on
 * the move (amov...), globally as playMoveNow is.
 *
 * Only the plain inventory pose, ending in "dnon": ACE's treatment moves (ainv..._medic...) begin the same way and
 * are left alone. Not in a vehicle, not dead.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call aio_gui_fnc_leaveGearPose;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!alive _unit} || {!local _unit} || {!isNull objectParent _unit}) exitWith {};

private _pose = toLowerANSI animationState _unit;

if ((_pose select [0, 4]) isNotEqualTo "ainv" || {(_pose select [count _pose - 4]) isNotEqualTo "dnon"}) exitWith {};

_unit playMoveNow ("amov" + (_pose select [4]));
