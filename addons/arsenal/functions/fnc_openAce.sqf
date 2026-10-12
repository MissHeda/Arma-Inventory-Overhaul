#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The button for ACE's own window: opens the same box in it. In a mission this window closes and ACE's
 * opens a frame later, with a Zeus's unit still released by ACE's close; in the Eden editor this one
 * applies and ACE's opens for the same entity.
 *
 * ACE's window is opened for ACE (GVAR(forceAce)), set right before openBox: the hand-over of ACE's display
 * is told to leave it alone. Not for a vanilla box that is not a full arsenal - ACE's window cannot show
 * its cargo (the button is not drawn then).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_openAce;
 *
 * Public: No
 */

if (!GVAR(isOpen) || {GVAR(source) isEqualTo "bi" && {!GVAR(full)}}) exitWith {};

// Eden: this window applies what was done (nothing is lost) and ACE's takes the entity the menu named, which
// the menu's data still holds.
if (is3DEN) exitWith {
    [1] call FUNC(close);

    [{
        call ACEFUNC(arsenal,open3DEN);
    }, []] spawn {
        params ["_code", "_args"];

        // The display closes when the frame is done.
        private _until = diag_tickTime + 2;

        waitUntil {isNull (findDisplay IDD_ARSENAL) || {diag_tickTime > _until}};

        isNil {_args call _code};
    };
};

private _box = GVAR(box);
private _center = GVAR(center);
private _full = GVAR(full);
private _moduleUsed = !isNil QACEGVAR(arsenal,moduleUsed);

// A Zeus's unit is not released by this close: ACE's does that when it ends.
GVAR(keepRemote) = _moduleUsed;

[2] call FUNC(close);

// Once this window is gone, with ACE's camera guard (nil'd by the close) clear again; a second at most.
[
    {isNull (findDisplay IDD_ARSENAL)},
    {
        params ["_box", "_center", "_full", "_moduleUsed"];

        if (!alive _center) exitWith {};

        // The module's flag stays set through ACE's window, so its close releases the unit.
        if (_moduleUsed) then {
            ACEGVAR(arsenal,moduleUsed) = true;
        };

        GVAR(forceAce) = diag_frameNo;
        [_box, _center, _full] call ACEFUNC(arsenal,openBox);
    },
    [_box, _center, _full, _moduleUsed],
    2
] call CBA_fnc_waitUntilAndExecute;
