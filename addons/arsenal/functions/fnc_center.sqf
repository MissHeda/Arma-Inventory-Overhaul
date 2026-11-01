#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The soldier the open arsenal dresses: ACE Arsenal's (ace_arsenal_center), or the vanilla Virtual Arsenal's
 * (BIS_fnc_arsenal_center, the player when it names none) while the grid panel lies on that one (GVAR(kind) "bi",
 * fnc_biOpened).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The soldier, objNull for none <OBJECT>
 *
 * Example:
 * call aio_arsenal_fnc_center;
 *
 * Public: No
 */

if (GVAR(kind) isEqualTo "bi") exitWith {
    missionNamespace getVariable ["BIS_fnc_arsenal_center", player]
};

missionNamespace getVariable [QACEGVAR(arsenal,center), objNull]
