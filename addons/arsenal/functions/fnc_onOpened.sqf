#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * ACE Arsenal's display opened (ace_arsenal_displayOpened): the grid panel moves in. ACE raises the event
 * before it filled its panels - in the Eden editor even before the copy of the unit it dresses exists -,
 * so the inventory's engine is attached a frame later (einv_gui_fnc_attach, with this addon's hook table
 * and the "draw3d" frame, which runs in the Eden editor too). Whatever the panel draws is made by the
 * engine on ACE's display, on top of ACE's own controls, and goes with it.
 *
 * ACE's keys stay ACE's: the display gets one more key handler (fnc_onKey) that hands the engine R while
 * something is dragged and the drop key over the panel, nothing else, and notes Ctrl - pressed there and let go
 * in a KeyUp handler - for Ctrl and the wheel (fnc_onWheel). A new row picked in ACE's list has its
 * list and "+" looked at again by the grid a frame later (fnc_ungrey), after ACE's own look by weight -
 * ACE greys every row anew at each pick -, and a press on the list is noted, as it may become a drag of
 * the row's item into the panel (fnc_onListPress). The same for the list of Enhanced First Aid Kits' kits tab,
 * which lies over ACE's at the same place while that tab is open (einv_compat_efak_fnc_arsenalControls): its items
 * are dragged into the kit's grid, and its rows greyed by the kit's cells (fnc_ungreyKit). Each list notes which
 * "-" and "+" lie over its row picked, as a press there is theirs.
 *
 * ACE's Close button and Escape are taken over (fnc_interceptClose): the window closes as ever, but asks
 * first when something does not fit the grid of the uniform, vest or backpack, and takes it out on the
 * player's word (fnc_confirmClose).
 *
 * Another window of the engine still open (the inventory, closing for this one) is waited for one frame
 * more; then the panel stays away, with one line in the RPT.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [findDisplay 1127001] call einv_arsenal_fnc_onOpened;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

if (!GVAR(ready) || {isNull _display} || {ctrlIDD _display != ARSENAL_IDD}) exitWith {};

uiNamespace setVariable [QGVAR(display), _display];
uiNamespace setVariable [QGVAR(confirm), controlNull];
uiNamespace setVariable [QGVAR(confirmControls), []];
uiNamespace setVariable [QGVAR(confirmMoved), []];
uiNamespace setVariable [QGVAR(confirmBar), [controlNull, 0]];
uiNamespace setVariable [QGVAR(confirmButtons), []];
GVAR(confirmPress) = -1;

GVAR(openedAt) = diag_tickTime;
GVAR(ungreyQueued) = false;
GVAR(attached) = false;
GVAR(shown) = true;
GVAR(panelRect) = [];
GVAR(hintRect) = [];
GVAR(removeZone) = -1;
GVAR(snapshot) = [objNull, createHashMap];
GVAR(kept) = [];
GVAR(keptAt) = 0;
GVAR(loadoutFrame) = -1;
GVAR(itemsSeen) = false;
GVAR(cargoPending) = false;
GVAR(dirty) = false;
GVAR(dragZone) = "";
GVAR(folded) = createHashMap;
GVAR(foldKeys) = [];
GVAR(foldTab) = "";
GVAR(listPress) = [];
GVAR(listSel) = [];
GVAR(watch) = [];
GVAR(scrollHold) = [];
GVAR(scrollKey) = "";
GVAR(scrollPixels) = 0;
GVAR(ctrlHeld) = false;
GVAR(pictureCache) = createHashMap;
GVAR(stagingCount) = 0;
GVAR(collapsedScroll) = ["", 0];
GVAR(listDragClass) = "";
GVAR(listDragIdc) = ARSENAL_IDC_LIST;
GVAR(unfoldSince) = -1;
GVAR(focusSeen) = [false, "", false];
GVAR(focusBuilt) = [false, "", false];
GVAR(focusKit) = "";
GVAR(kitVerdicts) = [[], createHashMap];
GVAR(kitUngreyAt) = 0;

_display displayAddEventHandler ["KeyDown", {_this call FUNC(onKey)}];
_display displayAddEventHandler ["KeyUp", {(_this + [false]) call FUNC(onKey)}];

// The question of fnc_confirmClose takes the mouse: the clicks on its answers (fnc_onConfirmMouse) and the wheel,
// which would otherwise zoom ACE's camera or scroll the lists under the card. Nothing while it is not up.
_display displayAddEventHandler ["MouseButtonDown", {([true] + _this) call FUNC(onConfirmMouse)}];
_display displayAddEventHandler ["MouseButtonUp", {([false] + _this) call FUNC(onConfirmMouse)}];
_display displayAddEventHandler ["MouseZChanged", {!isNull (uiNamespace getVariable [QGVAR(confirm), controlNull])}];

// The Close button and Escape ask first when something does not fit (fnc_confirmClose).
[_display] call FUNC(interceptClose);

// ACE's list, and the kits tab's list where Enhanced First Aid Kits is loaded, each with the "-" and "+" over its row.
private _lists = [[_display displayCtrl ARSENAL_IDC_LIST, [ARSENAL_IDC_MINUS, ARSENAL_IDC_PLUS]]];

if (!isNil QEFUNC(compat_efak,arsenalControls)) then {
    ([_display] call EFUNC(compat_efak,arsenalControls)) params ["_kitList", "", "_kitArrows"];

    _lists pushBack [_kitList, _kitArrows];
};

{
    _x params ["_list", "_arrows"];

    if (isNull _list) then {continue};

    _list setVariable [QGVAR(arrows), _arrows];

    // The row picked, when and in which list: a drag from the list whose press found no row takes the row picked,
    // only when it was picked since the press (fnc_listDrag).
    _list ctrlAddEventHandler ["LBSelChanged", {
        GVAR(listSel) = [_this select 1, diag_frameNo, ctrlIDC (_this select 0)];

        // One look a frame however many picks ACE's events make in it: each would start a pass of its own,
        // and every pass runs its turn of UNGREY_BUDGET before a newer one takes over.
        if (!GVAR(ungreyQueued)) then {
            GVAR(ungreyQueued) = true;

            [{
                GVAR(ungreyQueued) = false;
                _this call FUNC(ungrey);
            }, [ctrlParent (_this select 0)]] call EFUNC(gui,later);
        };
    }];

    // A press there may become a drag of its row's item into the panel (fnc_onListPress, fnc_listDrag).
    _list ctrlAddEventHandler ["MouseButtonDown", {
        params ["_list", "_button", "", "", ["_shift", false]];

        [_list, _button, _shift] call FUNC(onListPress);
    }];
} forEach _lists;

// The engine a frame later, once ACE's own start is done; once more if another of its windows is still
// closing.
private _fnc_attach = {
    params ["_display", "_tries", "_fnc_attach"];

    if (isNull _display || {GVAR(attached)}) exitWith {};

    private _current = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

    if (!isNull _current && {_current isNotEqualTo _display}) exitWith {
        if (_tries > 0) exitWith {
            [_fnc_attach, [_display, _tries - 1, _fnc_attach]] call EFUNC(gui,later);
        };

        WARNING("Another window of the inventory is open - ACE Arsenal opens without the grid panel.");
    };

    private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

    if (isNull _center) exitWith {};

    private _begin = diag_tickTime;
    private _attached = [_display, _center, objNull, objNull, call FUNC(hooks), "draw3d"] call EFUNC(gui,attach);

    ["gui attach (first build of the panel)", _begin, "", true] call FUNC(noteOpen);

    if !(_attached) exitWith {
        WARNING("The inventory's engine did not attach to ACE Arsenal - it opens without the grid panel.");
    };

    GVAR(attached) = true;

    _begin = diag_tickTime;
    [] call FUNC(snapshot);
    ["first snapshot", _begin] call FUNC(noteOpen);

    [] call FUNC(settle);
};

[_fnc_attach, [_display, 1, _fnc_attach]] call EFUNC(gui,later);
