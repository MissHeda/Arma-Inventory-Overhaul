#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a unit leads AI soldiers. Then the keys 4 to 0 may be needed for Arma's command menu, as
 * they always were (fnc_onKey): leading only other players does not count, they have their own keys.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Leads a group with AI soldiers in it <BOOL>
 *
 * Example:
 * [player] call einv_hotbar_fnc_isLeading;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

(leader group _unit) isEqualTo _unit
&& {((units group _unit) findIf {_x isNotEqualTo _unit && {alive _x} && {!isPlayer _x}}) >= 0}
