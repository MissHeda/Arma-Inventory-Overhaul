#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The display closed, in the order of ACE's onArsenalClose: ace_arsenal_displayClosed first, with
 * everything still set; Eden's clone applied or dropped; the camera given back; a Zeus's unit released;
 * face and voice sent to the others; the window engine let go (einv_gui_fnc_onUnload); ACE's session
 * globals cleared and the HUD back; einv_arsenal_closed last.
 *
 * It undoes only what fnc_onLoad did, and only once - a load that failed calls it itself, and the display's
 * own unload event, which comes later, finds nothing left to do.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Exit code - 1 applies in the Eden editor, 2 discards <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, 2] call einv_arsenal_fnc_onUnload;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_exitCode", 2, [0]]];

if (isNull _display || {_display getVariable [QGVAR(ended), false]}) exitWith {};

_display setVariable [QGVAR(ended), true];

// Opened by something else than fnc_openWindow: nothing was started.
if !(_display getVariable [QGVAR(started), false]) exitWith {};

private _center = GVAR(center);
private _box = GVAR(box);
private _source = GVAR(source);

// What the world knows the unit as: the editor's entity, not the copy that stood in for it.
private _unit = [_center, GVAR(edenOrigin)] select (is3DEN && {!isNull GVAR(edenOrigin)});

// 1. Everything is still set, as ACE has it.
if (_display getVariable [QGVAR(announced), false]) then {
    [QACEGVAR(arsenal,displayClosed), []] call CBA_fnc_localEvent;
};

// 2. The Eden editor: the copy's loadout goes on the selected units (Apply) or is dropped.
if (is3DEN) then {
    [_exitCode] call FUNC(edenEnd);
};

// 3. The camera.
call FUNC(cameraStop);

// 4. Zeus: ACE's module and ZEN control the unit remotely for the arsenal and release it here - not when
// the button for ACE's own window closes this one, which opens it for the same unit.
if (!isNil QACEGVAR(arsenal,moduleUsed) && {!GVAR(keepRemote)}) then {
    ACEGVAR(arsenal,moduleUsed) = nil;

    if (!isNull _center) then {
        objNull remoteControl _center;
    };
};

GVAR(keepRemote) = false;

// 5. The view the player had, and the curator's camera where it was.
if (!is3DEN) then {
    if (GVAR(cameraView) isNotEqualTo "") then {
        ACE_player switchCamera GVAR(cameraView);
    };

    if (!isNull curatorCamera && {GVAR(curatorCameraData) isNotEqualTo []}) then {
        GVAR(curatorCameraData) params ["_position", "_dirAndUp"];

        curatorCamera setPosASL _position;
        curatorCamera setVectorDirAndUp _dirAndUp;
    };
};

GVAR(curatorCameraData) = [];

// 6. Face and voice for everyone, also those who join later (not in the editor: nobody else is there).
if (isMultiplayer && {!is3DEN} && {!isNull _center}) then {
    private _face = missionNamespace getVariable [QACEGVAR(arsenal,currentFace), face _center];
    private _voice = missionNamespace getVariable [QACEGVAR(arsenal,currentVoice), ""];
    private _hash = hashValue _center;

    private _id = [QACEGVAR(arsenal,broadcastFace), [_center, _face], QACEGVAR(arsenal,centerFace_) + _hash] call CBA_fnc_globalEventJIP;
    [_id, _center] call CBA_fnc_removeGlobalEventJIP;

    _id = [QACEGVAR(arsenal,broadcastVoice), [_center, _voice], QACEGVAR(arsenal,centerVoice_) + _hash] call CBA_fnc_globalEventJIP;
    [_id, _center] call CBA_fnc_removeGlobalEventJIP;
};

// 7. The window engine lets go - unless the display never became the window (another one is, still).
if ((uiNamespace getVariable [QEGVAR(gui,display), displayNull]) isEqualTo _display) then {
    [_display, _exitCode] call EFUNC(gui,onUnload);
};

// 8. ACE's globals and the HUD.
call FUNC(sessionEnd);

// 9. Closed.
GVAR(isOpen) = false;

// A vanilla session ends with the vanilla arsenal's own event: missions save respawn loadouts there.
if (_source isEqualTo "bi") then {
    [missionNamespace, "arsenalClosed", [displayNull, false]] call BIS_fnc_callScriptedEventHandler;
};

["einv_arsenal_closed", [_unit, _box]] call CBA_fnc_localEvent;

GVAR(box) = objNull;
GVAR(center) = objNull;
GVAR(full) = false;
GVAR(source) = "ace";
