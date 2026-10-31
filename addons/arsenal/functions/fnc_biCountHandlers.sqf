#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A frame after every postInit has run: counts the handlers that mods registered for the vanilla arsenal's
 * arsenalOpened and arsenalPreOpen events, so a handler a mission adds later can be told from them
 * (fnc_biMissionHooks). A mod's handler is there from its preInit or postInit; a mission adds its own when
 * it starts, which is after.
 *
 * The vanilla functions keep a handler's code in a list on the mission namespace and put -1 in its place
 * when it is removed; only code counts. A mod that removes and adds its handler again, as some weapon packs
 * do, keeps its count.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_arsenal_fnc_biCountHandlers;
 *
 * Public: No
 */

GVAR(biModHandlers) = ["arsenalOpened", "arsenalPreOpen"] apply {
    private _handlers = missionNamespace getVariable ["BIS_fnc_addScriptedEventHandler_" + _x, []];

    count (_handlers select {_x isEqualType {}})
};
