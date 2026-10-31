#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the mission has handlers of its own on the vanilla arsenal's events: more of them than were
 * counted at the start (fnc_biCountHandlers). Such a mission restricts the vanilla arsenal there - it edits
 * the catalog, the tabs and the buttons - and keeps it: ACE Arsenal would lose all of that.
 *
 * Handlers a mission adds before the first frame after postInit (an object's init field, a function of its
 * own that runs at preInit) are counted as the mods'; a mission like that says so itself with
 * aio_arsenal_biPassThrough.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The mission hooks the vanilla arsenal <BOOL>
 *
 * Example:
 * call aio_arsenal_fnc_biMissionHooks;
 *
 * Public: No
 */

private _now = ["arsenalOpened", "arsenalPreOpen"] apply {
    private _handlers = missionNamespace getVariable ["BIS_fnc_addScriptedEventHandler_" + _x, []];

    count (_handlers select {_x isEqualType {}})
};

GVAR(biModHandlers) params [["_opened", 0], ["_preOpen", 0]];

(_now select 0) > _opened || {(_now select 1) > _preOpen}
