#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The Enhanced Arsenal's display was created, in the order of ACE's onArsenalOpen: the session starts
 * (fnc_sessionStart), ace_arsenal_displayOpened is raised, what is offered is read after the handlers of
 * that event changed it (fnc_readSupply), Eden's clone is made (fnc_edenStart), the camera starts and the
 * display attaches to the inventory's window engine (einv_gui_fnc_attach) with the hooks of this addon. A
 * window that cannot attach closes, and ACE's opens in its place. With ACRE loaded the window is told to
 * ACRE as a display its notifications may show over (fnc_acreDisplay).
 *
 * The display carries what has been done on it, so that fnc_onUnload undoes exactly that: also when this
 * ends early.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_arsenal_fnc_onLoad;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

(uiNamespace getVariable [QGVAR(openArgs), []]) params [
    ["_box", objNull, [objNull]],
    ["_center", objNull, [objNull]],
    ["_full", false, [false]],
    ["_items", createHashMap, [createHashMap]],
    ["_source", "ace", [""]]
];

uiNamespace setVariable [QGVAR(openArgs), []];

// Opened by something else than fnc_openWindow, or with nothing to dress: nothing to show.
if (isNull _display || {isNull _box} || {isNull _center} || {count _items == 0}) exitWith {
    [{
        params ["_display"];

        _display closeDisplay 2;
    }, [_display]] call EFUNC(gui,later);
};

// ----- 1. The session -----

[_box, _center, _full, _items, _source] call FUNC(sessionStart);
_display setVariable [QGVAR(started), true];

// ----- 2. The event ACE raises with its state complete, the unit still the editor's entity, no camera yet -----

[QACEGVAR(arsenal,displayOpened), [_display]] call CBA_fnc_localEvent;
_display setVariable [QGVAR(announced), true];

// Read now that every handler of that event has had its say (a role mod removes classes, ACE Arsenal
// Extended swaps the list).
[true] call FUNC(readSupply);

// ----- 3. The Eden editor: a copy of the entity stands in for it -----

if (is3DEN) then {
    _center = call FUNC(edenStart);

    GVAR(center) = _center;
    ACEGVAR(arsenal,center) = _center;
};

// ----- 4. The game around it -----

cutText ["", "PLAIN"];
showCommandingMenu "";

if (!is3DEN) then {
    GVAR(cameraView) = cameraView;
    _center switchCamera "internal";
};

// Nothing of the game's HUD but what ACE's arsenal leaves (its own list: the same ids ACE uses).
["einv_arsenal", [false, true, true, true, true, true, true, false, true, true]] call ACEFUNC(common,showHud);

// ----- 5. The camera -----

private _camera = [_center] call FUNC(cameraStart);

// ACE's camera is the guard of its openBox and what its feature camera looks at: set while ours is up.
ACEGVAR(arsenal,camera) = _camera;

// ----- 6. The window -----

private _attached = [_display, _center, objNull, objNull, call FUNC(hooks), "draw3d"] call EFUNC(gui,attach);

if (!_attached) exitWith {
    ERROR("The Enhanced Arsenal could not attach to the inventory's window engine - ACE's own window opens.");

    // Taken down the way a close takes it, and the display closed a frame later (not inside its own load).
    [_display, 2] call FUNC(onUnload);

    [{
        params ["_display", "_box", "_center", "_full", "_source"];

        _display closeDisplay 2;

        if (_source isEqualTo "bi") exitWith {
            [LLSTRING(Hint_CannotOpen), false, 4, 2] call ACEFUNC(common,displayText);
        };

        if (_source isEqualTo "eden") exitWith {
            call ACEFUNC(arsenal,open3DEN);
        };

        if (!alive _center) exitWith {};

        GVAR(forceAce) = diag_frameNo;
        [_box, _center, _full] call ACEFUNC(arsenal,openBox);
    }, [_display, _box, _center, _full, _source]] call EFUNC(gui,later);
};

// ----- 7. Open -----

GVAR(isOpen) = true;

// ACRE's notifications show over this window as they do over ACE's.
call FUNC(acreDisplay);

["einv_arsenal_opened", [_display, _center, _box]] call CBA_fnc_localEvent;
