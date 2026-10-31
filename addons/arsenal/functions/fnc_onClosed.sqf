#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * ACE Arsenal's display closes (ace_arsenal_displayClosed, raised first thing in its unload, while ACE's
 * unit is still known): the engine lets go of it (aio_gui_fnc_onUnload - the next window, the inventory,
 * has no hooks again), the panel's state is forgotten, and a helper that carried a vanilla box's items
 * (fnc_openBI) is deleted a frame later, once ACE is done with it. So is the staging space (fnc_staging)
 * with whatever still lies in it: it was for this fitting only, as its caption and the hint line said. A kit of
 * Enhanced First Aid Kits lying there gives its instance back to that mod's pool first
 * (aio_compat_efak_fnc_arsenalFree).
 *
 * If the soldier walks off with more in a uniform, vest or backpack than its grid has room for - a loadout
 * brought it, say - and the window closed some way fnc_confirmClose could not ask first (a script closed
 * it), it is taken out of the containers a frame later (fnc_dropOverflow, the unit being local here), the
 * RPT names what went and ACE's text on the screen says it once (what the player agreed to in the question
 * needs neither - nothing is left by then). A unit that is not local here keeps the old way: the surplus moves
 * on to the next of his containers with free cells (aio_storage op "migrate") and what has nowhere to go is
 * said (fnc_reportOverflow). Not in the Eden editor, where ACE dressed a copy.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_arsenal_fnc_onClosed;
 *
 * Public: No
 */

disableSerialization;

// The engine is let go of whether or not its frame already saw the display go: only this takes its hooks
// away.
if (GVAR(attached)) then {
    GVAR(attached) = false;
    call EFUNC(gui,onUnload);
};

uiNamespace setVariable [QGVAR(display), displayNull];

// A drag of the question's card ends with the window.
["end"] call EFUNC(gui,dragHandle);

uiNamespace setVariable [QGVAR(confirm), controlNull];
uiNamespace setVariable [QGVAR(confirmControls), []];
uiNamespace setVariable [QGVAR(confirmMoved), []];
uiNamespace setVariable [QGVAR(confirmBar), [controlNull, 0]];
uiNamespace setVariable [QGVAR(confirmButtons), []];
GVAR(confirmPress) = -1;

GVAR(panelRect) = [];
GVAR(hintRect) = [];
GVAR(removeZone) = -1;
GVAR(snapshot) = [objNull, createHashMap];
GVAR(cargoPending) = false;
GVAR(dirty) = false;
GVAR(dragZone) = "";
GVAR(listPress) = [];
GVAR(listSel) = [];
GVAR(watch) = [];
GVAR(scrollHold) = [];
GVAR(ctrlHeld) = false;
GVAR(picturePass) = GVAR(picturePass) + 1;
GVAR(stagingCount) = 0;
GVAR(listDragClass) = "";
GVAR(unfoldSince) = -1;
GVAR(focusSeen) = [false, "", false];
GVAR(focusBuilt) = [false, "", false];
GVAR(focusKit) = "";
GVAR(kitVerdicts) = [[], createHashMap];

// Where the kit of Enhanced First Aid Kits' kits tab lay is forgotten (aio_compat_efak_fnc_arsenalKit).
if (!isNil QEFUNC(compat_efak,arsenalKit)) then {
    [] call EFUNC(compat_efak,arsenalKit);
};

// Kits of Enhanced First Aid Kits that lie in the staging space go with it: their instances back to that mod's pool,
// unless one of the class lies on the soldier (aio_compat_efak_fnc_arsenalFree).
private _soldier = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

if (!isNull GVAR(staging) && {!isNull _soldier} && {!isNil QEFUNC(compat_efak,arsenalFree)}) then {
    [
        ((getItemCargo GVAR(staging)) param [0, []]) + ([GVAR(staging)] call EFUNC(storage,hiddenClasses)),
        [uniformContainer _soldier, vestContainer _soldier, backpackContainer _soldier]
    ] call EFUNC(compat_efak,arsenalFree);
};

{
    if (!isNull _x) then {
        [{deleteVehicle (_this select 0)}, [_x]] call EFUNC(gui,later);
    };
} forEach [GVAR(biHelper), GVAR(staging)];

GVAR(biHelper) = objNull;
GVAR(staging) = objNull;

private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

if (isNull _center || {is3DEN} || {!GVAR(ready)}) exitWith {};

[{
    params ["_center"];

    // The arsenal is gone and with it the question: what still lies beyond the grid of a container is taken
    // out, as the window would have done on the player's word, and said once.
    if (local _center) then {
        private _gone = [_center] call FUNC(dropOverflow);

        if (count _gone > 0) then {
            private _list = [];

            {
                _list pushBack (format ["%1 x%2", ([_x] call EFUNC(items,getInfo)) get "name", _y]);
            } forEach _gone;

            private _names = _list joinString ", ";

            INFO_1("ACE Arsenal closed with things that did not fit - removed: %1.",_names);

            private _text = format [LLSTRING(Removed), _names];

            if (isNil QACEFUNC(common,displayText)) then {
                hint _text;
            } else {
                [_text, false, 5, 1] call ACEFUNC(common,displayText);
            };
        };
    } else {
        // Not this machine's unit: its surplus moves on to the next container with room.
        [_center] call EFUNC(storage,requestMigrate);
    };

    [_center, displayNull] call FUNC(reportOverflow);
}, [_center]] call EFUNC(gui,later);
