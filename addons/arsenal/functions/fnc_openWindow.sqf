#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens the Enhanced Arsenal for a unit. The guards are ACE's openBox's: a man on foot (the Eden editor
 * excepted), local, no arsenal open already; an inventory window still open is closed first and this runs
 * again a frame later. Then the items it offers - a copy of the box's list, ACE's whole config for a full
 * arsenal, or the classes of a vanilla box mapped into ACE's structure - and the display on the right
 * parent: the one given, the curator's, the game's, or Eden's. The display's load (fnc_onLoad) does the
 * rest.
 *
 * Called from a scheduled script it runs again unscheduled, like ACE's openBox. The window opening a frame
 * later, after the inventory closed, still answers true; should it not open then, ACE's own window does
 * (a vanilla box says it could not open).
 *
 * Arguments:
 * 0: Box the items come from, or the unit itself for a full arsenal <OBJECT>
 * 1: Unit the window dresses <OBJECT>
 * 2: Offer every item in the game, whatever the box holds <BOOL> (default: false)
 * 3: Classes of a vanilla box, mapped into ACE's structure (fnc_biItems); nil for an ACE box <ARRAY>
 *    (default: nil)
 * 4: Display to open it on <DISPLAY> (default: displayNull)
 * 5: Where the items come from - "ace", "bi" or "eden" <STRING> (default: "ace")
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * [_box, player] call einv_arsenal_fnc_openWindow;
 *
 * Public: No
 */

params [
    ["_box", objNull, [objNull]],
    ["_center", objNull, [objNull]],
    ["_full", false, [false]],
    ["_classes", nil, [[]]],
    ["_parent", displayNull, [displayNull]],
    ["_source", "ace", [""]]
];

// The second run after an inventory window was closed for this one (below).
private _retry = GVAR(reopening);
GVAR(reopening) = false;

if (
    !hasInterface || {isNull _box} || {isNull _center} || {!(_center isKindOf "CAManBase")}
    || {!isNull objectParent _center && {!is3DEN}} || {!local _center}
    || {GVAR(isOpen)} || {!isNil QACEGVAR(arsenal,camera)}
) exitWith {false};

// Not in the scheduled environment: the display's load wants the frame to itself, and in the Eden editor
// there is no other.
if (canSuspend) exitWith {
    if (is3DEN) then {
        private _args = _this;
        private _result = false;

        isNil {_result = _args call FUNC(openWindow)};

        _result
    } else {
        [FUNC(openWindow), _this] call CBA_fnc_directCall
    };
};

// An inventory window (or any other of the engine) is open: it goes first, and this opens the window a frame
// later. Only once - a window that stays open must not make this wait for ever.
if (!isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull])) exitWith {
    if (_retry) exitWith {false};

    GVAR(reopening) = true;
    (uiNamespace getVariable [QEGVAR(gui,display), displayNull]) closeDisplay 2;

    [{
        params ["_args"];

        if (_args call FUNC(openWindow)) exitWith {};

        // The window could not open after all: ACE's opens in its place, a vanilla box says so.
        _args params [["_box", objNull], ["_center", objNull], ["_full", false], "", "", ["_source", "ace"]];

        if (_source isEqualTo "ace") exitWith {
            GVAR(forceAce) = diag_frameNo;
            [_box, _center, _full] call ACEFUNC(arsenal,openBox);
        };

        [LLSTRING(Hint_CannotOpen), false, 4, 2] call ACEFUNC(common,displayText);
    }, [_this]] call EFUNC(gui,later);

    true
};

// What it offers.
private _items = createHashMap;

switch (true) do {
    // Everything in the game.
    case _full: {
        _items = +(uiNamespace getVariable [QACEGVAR(arsenal,configItems), createHashMap]);
    };
    // A vanilla box: ACE's own function classifies the names on a helper that is gone again at once (it
    // takes the base weapons, config-cases the names and drops what the game does not know).
    case (!isNil "_classes"): {
        private _helper = "Land_HelipadEmpty_F" createVehicleLocal [0, 0, 0];
        [_helper, _classes, false] call ACEFUNC(arsenal,addVirtualItems);

        private _list = _helper getVariable QACEGVAR(arsenal,virtualItems);

        if (!isNil "_list") then {
            _items = +_list;
        };

        deleteVehicle _helper;
    };
    // An ACE box.
    default {
        private _list = _box getVariable QACEGVAR(arsenal,virtualItems);

        if (!isNil "_list") then {
            _items = +_list;
        };
    };
};

if (count _items == 0) exitWith {
    [localize "STR_ace_arsenal_noVirtualItems", false, 5, 1] call ACEFUNC(common,displayText);

    false
};

// The parent, in ACE's order: the curator's display, the game's, and in the Eden editor its own.
if (isNull _parent) then {
    _parent = findDisplay 312;

    if (isNull _parent) then {
        _parent = findDisplay 46;
    };

    if (is3DEN) then {
        _parent = findDisplay 313;
    };
};

if (isNull _parent) exitWith {
    [localize "STR_ace_arsenal_CantOpenDisplay", false, 5, 1] call ACEFUNC(common,displayText);

    false
};

// The display takes its arguments from here (fnc_onLoad runs while createDisplay is still working).
uiNamespace setVariable [QGVAR(openArgs), [_box, _center, _full, _items, _source]];

private _display = _parent createDisplay "EINV_ArsenalDisplay";

if (isNull _display) exitWith {
    uiNamespace setVariable [QGVAR(openArgs), []];

    false
};

true
