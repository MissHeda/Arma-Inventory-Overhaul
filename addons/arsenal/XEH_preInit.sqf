#include "script_component.hpp"
#include "defines.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// ----- ACE Arsenal's grid panel -----

// The ACE functions and data this addon relies on exist (fnc_compatCheck) - false until that has looked;
// then ACE Arsenal opens without the panel and the vanilla Virtual Arsenal stays vanilla. The inventory's
// engine is attached to ACE's display, whose panels are shown (Backspace hides them).
GVAR(ready) = false;
GVAR(attached) = false;
GVAR(shown) = true;

// ACE's display while it is open - a display, so in uiNamespace.
uiNamespace setVariable [QGVAR(display), displayNull];

// Where the last build put the panel, [x, y, w, h] on the screen, [] for nowhere; the hint line at its
// bottom; which of the engine's zones is ACE's list (a drop there, or anywhere outside the panel, takes the
// item out); and what the drag stood over, for its hint once ("remove", "cancel" for an item out of ACE's
// list over no grid, "" for none).
GVAR(panelRect) = [];
GVAR(hintRect) = [];
GVAR(removeZone) = -1;
GVAR(dragZone) = "";

// What the open uniform, vest or backpack held at the last look: [container, lowercase class -> count]
// (fnc_snapshot).
GVAR(snapshot) = [objNull, createHashMap];

// Following ACE's events: ace_arsenal_itemsChanged came since the last ace_arsenal_cargoChanged (an ACE
// that has it); a cargoChanged waits for its pass a frame later; that pass is asked for already
// (fnc_settle); the panel is to be built again once nothing of it is held (fnc_onFrame).
GVAR(itemsSeen) = false;
GVAR(cargoPending) = false;
GVAR(settleQueued) = false;
GVAR(dirty) = false;

// The staging space under the container's grid (fnc_staging), a crate of this machine's own while ACE's
// window is open, and how much lies in it at the last build, for the hint line.
GVAR(staging) = objNull;
GVAR(stagingCount) = 0;

// The panel's folded sections while ACE's window is open, container class (or "staging") -> true, and
// which class each section of the last build showed, [[container, class], ...] (fnc_layout, the "fold"
// hook).
GVAR(folded) = createHashMap;
GVAR(foldKeys) = [];

// A left press on a row of ACE's list that may yet become a drag of its item, [where, shift, frame, row]
// or [] (fnc_onListPress, fnc_onFrame); the row the list picked last, [row, frame] or [] (fnc_listDrag); a move
// into or out of the staging space waited for, to tell ACE, [container, class, count before, until] or []
// (fnc_onDrop); where the column stood when Ctrl and the wheel changed a tile, [pixels, until frame] or []
// (fnc_onWheel); Ctrl held (fnc_onKey).
GVAR(listPress) = [];
GVAR(listSel) = [];
GVAR(watch) = [];
GVAR(scrollHold) = [];
GVAR(ctrlHeld) = false;

// What of ACE's internals was found missing and said in the RPT already, once each.
GVAR(missingSaid) = [];

// ----- The vanilla Virtual Arsenal -----

// This open goes to the vanilla window (a mission hooks it, the unit is not the player's); the player left
// it alone this time; the catalog as BI built it, to tell what a mission changed; how many handlers mods
// had on its events when the game started (fnc_biCountHandlers), [arsenalOpened, arsenalPreOpen]; and the
// helper that carries a vanilla box's items into ACE Arsenal (fnc_openBI).
GVAR(biLetThrough) = false;
GVAR(biLeave) = [];
GVAR(biCatalogBase) = [];
GVAR(biModHandlers) = [0, 0];
GVAR(biHelper) = objNull;

// Checked once: ACE's pieces this addon relies on, and that BIS_fnc_arsenal is the one with our file.
call FUNC(compatCheck);
call FUNC(biInit);

// ACE Arsenal's events, all local to the machine whose player has it open. Registered here, not in
// postInit: the Eden editor runs no postInit, and its ACE Arsenal gets the panel too.
if (hasInterface) then {
    // The display: the panel moves in a frame later, and out with it.
    [QACEGVAR(arsenal,displayOpened), {
        _this call FUNC(onOpened);
    }] call CBA_fnc_addEventHandler;

    [QACEGVAR(arsenal,displayClosed), {
        call FUNC(onClosed);
    }] call CBA_fnc_addEventHandler;

    // A tab of the left bar filled (also after ACE's refresh, a loadout imported or loaded), the list of
    // the right filled (a filter, another container put on): the panel shows what is open now.
    {
        [_x, {
            if (GVAR(attached)) then {
                [] call FUNC(settle);
            };
        }] call CBA_fnc_addEventHandler;
    } forEach [
        QACEGVAR(arsenal,leftPanelFilled), QACEGVAR(arsenal,rightPanelFilled),
        QACEGVAR(arsenal,loadoutImported), QACEGVAR(arsenal,onLoadoutLoad)
    ];

    // Backspace hides ACE's panels: the panel goes with them.
    [QACEGVAR(arsenal,showToggle), {
        params ["", ["_shown", true, [true]]];

        GVAR(shown) = _shown;

        if (GVAR(attached)) then {
            [] call FUNC(settle);
        };
    }] call CBA_fnc_addEventHandler;

    // ACE's "+" and "-", and what really changed.
    [QACEGVAR(arsenal,cargoChanged), {
        _this call FUNC(onCargoChanged);
    }] call CBA_fnc_addEventHandler;

    [QACEGVAR(arsenal,itemsChanged), {
        _this call FUNC(onItemsChanged);
    }] call CBA_fnc_addEventHandler;
};

#include "initSettings.inc.sqf"

ADDON = true;
