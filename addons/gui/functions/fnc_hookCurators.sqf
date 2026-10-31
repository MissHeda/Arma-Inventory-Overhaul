#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts this mod's handler on every curator module that does not have it yet (fnc_onZeusPlaced on "CuratorObjectPlaced").
 * A game master can be assigned in the middle of a mission and the engine has no event for a new curator, so it is called
 * every few seconds from a per-frame handler; each module is marked on this machine once it has the handler. The event
 * fires where the module is local, which is not the same machine in every setup - so every machine hooks them all.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_gui_fnc_hookCurators;
 *
 * Public: No
 */

{
    if !(_x getVariable [QGVAR(hooked), false]) then {
        _x setVariable [QGVAR(hooked), true];
        _x addEventHandler ["CuratorObjectPlaced", {call FUNC(onZeusPlaced)}];
    };
} forEach allCurators;
