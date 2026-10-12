#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The way over from ACE's own window to this one: a small button, [Enhanced Arsenal], at the top right of
 * ACE's display, added when that display opens (ace_arsenal_displayOpened, in XEH_postInit). Pressed, it
 * writes down which box, which unit and whether the box's list is ignored, closes ACE's window and opens
 * this one for the same - directly (fnc_openWindow), never through ACE's openBox, which would show the
 * bare game for a few frames.
 *
 * In a mission ACE's close is let to finish first (its camera guard has to be clear). A Zeus's remote
 * controlled unit stays his: the flag that makes ACE's close release it is taken down for the close and put
 * back for ours. In the Eden editor ACE's window is closed with Apply, so nothing done there is lost, and
 * the entity the editor named is the unit. Should this window not open, ACE's opens again.
 *
 * Arguments:
 * 0: ACE's display <DISPLAY>
 * 1: The button was pressed <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_arsenal_fnc_aceButton;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_pressed", false, [false]]];

if (isNull _display) exitWith {};

// ----- Making the button -----

if (!_pressed) exitWith {
    // Only ACE's own display, and only when this window can open at all.
    if (!GVAR(ready) || {_display isNotEqualTo (findDisplay ARSENAL_IDD)} || {!isNull (_display getVariable [QGVAR(button), controlNull])}) exitWith {};

    // ACE's grid, as its own display is laid out in (z\ace\addons\arsenal\defines.hpp).
    private _gridW = pixelW * pixelGridNoUIScale * pixelScale;
    private _gridH = pixelH * pixelGridNoUIScale * pixelScale;
    private _width = 44 * _gridW;
    private _height = 5 * _gridH;

    private _button = _display ctrlCreate ["RscButtonMenu", -1];

    _button ctrlSetPosition [safeZoneX + safeZoneW - _width - 3 * _gridW, safeZoneY + 1.8 * _gridH, _width, _height];
    _button ctrlSetText LLSTRING(Button_Enhanced);
    _button ctrlSetTooltip LLSTRING(Button_Enhanced_Tooltip);
    _button ctrlSetBackgroundColor [0.075, 0.083, 0.1, 0.85];
    _button ctrlCommit 0;
    _button ctrlAddEventHandler ["ButtonClick", {
        [ctrlParent (_this select 0), true] call FUNC(aceButton);
    }];

    _display setVariable [QGVAR(button), _button];
};

// ----- Pressed -----

private _box = missionNamespace getVariable [QACEGVAR(arsenal,currentBox), objNull];
private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];
private _full = !isNil QACEGVAR(arsenal,ignoredVirtualItems);
private _parent = displayParent _display;

if (isNull _box || {isNull _center} || {!GVAR(ready)} || {GVAR(isOpen)}) exitWith {};

// The Eden editor: the unit is the entity ACE's copy stands in for. Applied, so nothing is lost.
if (is3DEN) exitWith {
    private _entity = missionNamespace getVariable [QACEGVAR(arsenal,centerOrigin), objNull];

    if (isNull _entity) exitWith {};

    _display closeDisplay 1;

    [_entity] spawn {
        params ["_entity"];

        // ACE's close finishes when the frame is done.
        private _until = diag_tickTime + 2;

        waitUntil {isNull (findDisplay ARSENAL_IDD) || {diag_tickTime > _until}};

        isNil {
            if !([_entity, _entity, true, nil, findDisplay 313, "eden"] call FUNC(openWindow)) then {
                call ACEFUNC(arsenal,open3DEN);
            };
        };
    };
};

private _moduleUsed = !isNil QACEGVAR(arsenal,moduleUsed);

// ACE's close would let the unit go.
if (_moduleUsed) then {
    ACEGVAR(arsenal,moduleUsed) = nil;
};

_display closeDisplay 2;

// Open when ACE's close is done - or, should it not finish within two seconds, all the same: the player
// must not be left with no window.
private _open = {
    params ["_box", "_center", "_full", "_parent", "_moduleUsed"];

    if (!alive _center) exitWith {};

    // The camera guard of ACE's openBox is what stands in the way, and ACE's close would have cleared it.
    if (!isNil QACEGVAR(arsenal,camera)) then {
        ACEGVAR(arsenal,camera) = nil;
    };

    if !([_box, _center, _full, nil, _parent] call FUNC(openWindow)) exitWith {
        // This window could not open: ACE's again, with the Zeus flag it had.
        if (_moduleUsed) then {
            ACEGVAR(arsenal,moduleUsed) = true;
        };

        GVAR(forceAce) = diag_frameNo;
        [_box, _center, _full] call ACEFUNC(arsenal,openBox);
    };

    // The module's flag is the session's now: this window's close releases the unit.
    if (_moduleUsed) then {
        ACEGVAR(arsenal,moduleUsed) = true;
    };
};

[
    {isNull (findDisplay ARSENAL_IDD) && {isNil QACEGVAR(arsenal,camera)}},
    _open,
    [_box, _center, _full, _parent, _moduleUsed],
    2,
    _open
] call CBA_fnc_waitUntilAndExecute;
