#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * ACE's display hands over to this window: the patched onLoad of ace_arsenal_display (CfgAceArsenal.hpp)
 * asks here first. Taken over, the display is disarmed - its other handlers emptied, every control hidden -
 * and closed a frame later, and the Enhanced Arsenal opens on the same parent; the unit of a Zeus is waited
 * for to become local. False when the setting says ACE's window, in Eden, when a piece is missing or ACE's
 * window is asked for once (GVAR(forceAce)): ACE's own onLoad then runs, word for word.
 *
 * The display is never closed inside its own load (ACE waits a frame for the same reason). Until it is,
 * ACE's camera is set to a null object, which keeps ACE's openBox from starting a second display.
 *
 * Arguments:
 * 0: ACE's display <DISPLAY>
 *
 * Return Value:
 * Handed over <BOOL>
 *
 * Example:
 * [_display] call einv_arsenal_fnc_handOver;
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

// A request to leave this display to ACE counts for a few frames, and once, however it ends.
private _forced = GVAR(forceAce);
GVAR(forceAce) = -1;

if (
    isNull _display || {is3DEN}
    || {_forced >= 0 && {diag_frameNo <= _forced + FORCE_ACE_FRAMES}}
    || {(missionNamespace getVariable [QGVAR(window), "enhanced"]) isNotEqualTo "enhanced"}
    || {!GVAR(ready)} || {GVAR(isOpen)}
    || {isNil QACEGVAR(arsenal,center)} || {isNil QACEGVAR(arsenal,currentBox)}
) exitWith {false};

private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];
private _box = missionNamespace getVariable [QACEGVAR(arsenal,currentBox), objNull];

// Zeus: the unit is only the curator's once the network says so. Anyone else's unit is not edited here.
private _zeus = !isNil QACEGVAR(arsenal,moduleUsed) || {!isNull (findDisplay 312)};

if (isNull _center || {isNull _box} || {!local _center && {!_zeus}}) exitWith {false};

// ----- Disarmed: nothing of ACE's runs on this display from here on -----

// The setters replace the handler of the same name, whichever config string won it (ACE Arsenal Extended
// patches the unload). The keys are swallowed for the one frame it lives.
_display setVariable [QGVAR(handedOver), true];

{
    _display displaySetEventHandler [_x, ""];
} forEach ["Unload", "KeyUp", "MouseButtonDown", "MouseButtonUp"];

_display displaySetEventHandler ["KeyDown", "true"];

{
    if ((toLowerANSI ctrlClassName _x) isEqualTo "mousearea") then {
        private _area = _x;

        {
            _area ctrlSetEventHandler [_x, ""];
        } forEach ["MouseMoving", "MouseHolding", "MouseZChanged"];
    };
} forEach (allControls _display);

// Whatever is drawn is gone, the controls patched in by other mods with it.
{
    _x ctrlShow false;
    _x ctrlEnable false;
} forEach (allControls _display);

ACEGVAR(arsenal,camera) = objNull;
ACEGVAR(arsenal,mouseButtonState) = [[], []];

private _full = !isNil QACEGVAR(arsenal,ignoredVirtualItems);
private _parent = displayParent _display;

// ----- A frame later: ACE's display closes, ours opens on the same parent -----

[{
    params ["_display", "_box", "_center", "_full", "_parent"];

    // Its unload handler is empty now, so nothing of ACE's or ACE Arsenal Extended's close runs.
    _display closeDisplay 2;

    // The dummy's lists and search bars set these when they got the focus.
    {
        missionNamespace setVariable [_x, nil];
    } forEach [
        QACEGVAR(arsenal,leftTabFocus), QACEGVAR(arsenal,rightTabFocus), QACEGVAR(arsenal,rightTabLnBFocus),
        QACEGVAR(arsenal,leftSearchbarFocus), QACEGVAR(arsenal,rightSearchbarFocus)
    ];

    if (isNull _parent) then {
        _parent = findDisplay 46;
    };

    // The window opens when the unit is ours; if not, or if it could not open, ACE's own window does
    // (with the Zeus module's flag still set, so ACE's close releases the unit).
    private _fnc_open = {
        params ["_box", "_center", "_full", "_parent"];

        // The unit died or is gone: nothing opens, and what ACE's openBox set is cleaned the way ACE's
        // close would have.
        if (!alive _center) exitWith {
            ACEGVAR(arsenal,currentBox) = objNull;
            ACEGVAR(arsenal,center) = nil;
            ACEGVAR(arsenal,virtualItems) = nil;
            ACEGVAR(arsenal,virtualItemsFlat) = nil;
            ACEGVAR(arsenal,ignoredVirtualItems) = nil;
            ACEGVAR(arsenal,camera) = nil;

            if (!isNil QACEGVAR(arsenal,moduleUsed)) then {
                ACEGVAR(arsenal,moduleUsed) = nil;

                if (!isNull _center) then {
                    objNull remoteControl _center;
                };
            };
        };

        // No longer held back: openBox's guard is the window's own now.
        ACEGVAR(arsenal,camera) = nil;

        if (local _center && {[_box, _center, _full, nil, _parent] call FUNC(openWindow)}) exitWith {};

        ACEGVAR(arsenal,camera) = nil;
        GVAR(forceAce) = diag_frameNo;
        [_box, _center, _full] call ACEFUNC(arsenal,openBox);
    };

    if (local _center || {!alive _center}) exitWith {
        [_box, _center, _full, _parent] call _fnc_open;
    };

    // Zeus: remote control makes the unit the curator's, but not necessarily by now.
    [
        {local (_this select 1) || {!alive (_this select 1)}},
        {
            params ["_fnc_open", "_center", "_box", "_full", "_parent"];

            [_box, _center, _full, _parent] call _fnc_open;
        },
        [_fnc_open, _center, _box, _full, _parent],
        ZEUS_LOCAL_WAIT,
        {
            params ["_fnc_open", "_center", "_box", "_full", "_parent"];

            [_box, _center, _full, _parent] call _fnc_open;
        }
    ] call CBA_fnc_waitUntilAndExecute;
}, [_display, _box, _center, _full, _parent]] call EFUNC(gui,later);

true
