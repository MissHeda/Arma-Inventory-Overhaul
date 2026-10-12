#include "script_component.hpp"

// ACE Arsenal, kept to the grid. The first handlers answer events ACE raises itself in its own window: at
// worst, after an update of ACE, an event no longer comes and its arsenal goes back to weight alone. All of
// them are local, raised on the machine whose player has the arsenal open.
//
// Our own window raises ACE's lifecycle, gear and loadout events as well and trims,
// reports and gives back by itself, so every handler that serves ACE's window exits while it is open
// (GVAR(isOpen), still true at ace_arsenal_displayClosed). Otherwise the loadout events of ours would be
// answered with ACE's on-screen texts. ACE's display onLoad is patched to hand over to it (CfgAceArsenal.hpp);
// nothing else of ACE's is replaced.

if (!hasInterface) exitWith {};

// The right panel was filled: a uniform, vest or backpack opened in the left panel, a search, a sort,
// another one put on. Note what it holds for the next add. A new container in the same panel means
// another one was just put on, and ACE carried the items over by their weight only.
[QACEGVAR(arsenal,rightPanelFilled), {
    if (GVAR(isOpen)) exitWith {};

    params ["_display"];

    GVAR(snapshot) params [["_index", -1], ["_container", objNull]];

    call FUNC(rememberCargo);

    GVAR(snapshot) params [["_indexNow", -1], ["_containerNow", objNull]];

    if (_index >= 0 && {_index == _indexNow} && {_container isNotEqualTo _containerNow}) then {
        [missionNamespace getVariable [QACEGVAR(arsenal,center), objNull], _display] call FUNC(reportOverflow);
    };
}] call CBA_fnc_addEventHandler;

// "Remove all" empties the open uniform, vest or backpack without an event and without filling the
// right panel again, so the last look would still count what was in it. Looked at again by its
// button - a frame later, once ACE's own handler has emptied the container.
[QACEGVAR(arsenal,displayOpened), {
    if (GVAR(isOpen)) exitWith {};

    params [["_display", displayNull, [displayNull]]];

    private _button = _display displayCtrl ARSENAL_IDC_REMOVE_ALL;

    if (isNull _button) exitWith {};

    _button ctrlAddEventHandler ["ButtonClick", {
        [FUNC(rememberCargo)] call CBA_fnc_execNextFrame;
    }];
}] call CBA_fnc_addEventHandler;

// Added to (or taken out of) a uniform, vest or backpack: what has no room comes back out.
[QACEGVAR(arsenal,cargoChanged), {
    if (GVAR(isOpen)) exitWith {};

    _this call FUNC(onCargoChanged);
    call FUNC(rememberCargo);
}] call CBA_fnc_addEventHandler;

// A whole loadout came in: from the clipboard - not the editor's list of default loadouts - or from
// the loadouts screen. Said in place of ACE's own "imported" or "loaded" when something does not fit.
[QACEGVAR(arsenal,loadoutImported), {
    if (GVAR(isOpen)) exitWith {};

    params ["_display", ["_toDefaults", false, [false]]];

    if (_toDefaults) exitWith {};

    call FUNC(rememberCargo);
    [missionNamespace getVariable [QACEGVAR(arsenal,center), objNull], _display] call FUNC(reportOverflow);
}] call CBA_fnc_addEventHandler;

[QACEGVAR(arsenal,onLoadoutLoad), {
    if (GVAR(isOpen)) exitWith {};

    call FUNC(rememberCargo);
    [missionNamespace getVariable [QACEGVAR(arsenal,center), objNull], findDisplay ARSENAL_IDD] call FUNC(reportOverflow);
}] call CBA_fnc_addEventHandler;

// Closing: said once more on the screen if the soldier walks off with more than the grid holds. The
// unit is read now - ACE forgets it later on the way out - and checked once the arsenal is gone.
[QACEGVAR(arsenal,displayClosed), {
    GVAR(snapshot) = [];

    // Still true at this event: our own window trims and reports by itself.
    if (GVAR(isOpen)) exitWith {};

    private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

    if (isNull _center) exitWith {};

    [{
        params ["_center"];
        [_center, displayNull] call FUNC(reportOverflow);
    }, [_center]] call CBA_fnc_execNextFrame;
}] call CBA_fnc_addEventHandler;

// ----- The Enhanced Arsenal -----

// ACE's own window gets its [Enhanced Arsenal] button from a handler registered in XEH_preInit: the Eden
// editor runs no postInit.

// The list of a box changed, or the box left ACE's arsenal system, while the window is open (ACE raises both
// on every machine; the functions answer only for their own box).
[QACEGVAR(arsenal,refresh), {
    if (!GVAR(isOpen)) exitWith {};

    _this call FUNC(onBoxRefresh);
}] call CBA_fnc_addEventHandler;

[QACEGVAR(arsenal,boxRemoved), {
    if (!GVAR(isOpen)) exitWith {};

    _this call FUNC(onBoxRemoved);
}] call CBA_fnc_addEventHandler;

// A shared or default loadout changed - another player's, or the editor's: the list in the Loadouts view is
// drawn again on its next frame. ACE tells with events for the shared ones (they arrive with a null control)
// and with network events for the default ones.
{
    [_x, {
        GVAR(loadoutsDirty) = true;
    }] call CBA_fnc_addEventHandler;
} forEach [
    QACEGVAR(arsenal,loadoutShared), QACEGVAR(arsenal,loadoutUnshared),
    QACEGVAR(arsenal,addDefaultLoadout), QACEGVAR(arsenal,removeDefaultLoadout), QACEGVAR(arsenal,renameDefaultLoadout)
];

// The rules for sizes and names changed: the catalog's rows were read by the old ones. The window builds
// itself anew (einv_gui), the rows are read again as they are needed.
[QEGVAR(items,rulesChanged), {
    GVAR(rows) = createHashMap;
    GVAR(lists) = createHashMap;
}] call CBA_fnc_addEventHandler;

// The vanilla Virtual Arsenal: once every addon's postInit has run, the handlers mods put on its events are
// counted, so a handler a mission adds later can be told from them (fnc_biCountHandlers).
[FUNC(biCountHandlers), []] call CBA_fnc_execNextFrame;
