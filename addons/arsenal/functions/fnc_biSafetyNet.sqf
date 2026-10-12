#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The vanilla arsenal opened though nothing here let it (arsenalOpened): a display created directly, or
 * BIS_fnc_arsenal's entry lost to another mod. Its display is closed a frame later and this addon blocks or
 * opens its own, unless the vanilla one is meant to stay.
 *
 * The vanilla one stays when the setting says so, in the editor, in BI's showcase, in Warlords, for a
 * mission that opted out or hooks the arsenal itself (the same rules as fnc_handleBIOpen), and when
 * fnc_handleBIOpen already let this open through (GVAR(biLetThrough)). The display is closed from outside,
 * a frame later, with exit code 2: the vanilla arsenal has run its own start by then, so its exit tears it
 * down properly. Closing it from its own load would leave a camera nobody removes.
 *
 * Registered at preInit for every mission; also registered here are the openings and closings that the
 * "leave it alone" mode reports from (fnc_biLeaveAlone) and the end of the mark of a vanilla open.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_biSafetyNet;
 *
 * Public: No
 */

// The vanilla arsenal opened.
[missionNamespace, "arsenalOpened", {
    if (!hasInterface || {is3DEN}) exitWith {};

    private _mode = missionNamespace getVariable [QGVAR(biArsenal), "vanilla"];
    private _passThrough = missionNamespace getVariable "einv_arsenal_biPassThrough";

    if (
        _mode isEqualTo "vanilla" || {GVAR(biLetThrough)} || {!GVAR(ready)} || {_passThrough isEqualTo true}
        || {missionName isEqualTo "Arsenal" && {!isNil "arsenal_fnc_opened"}}
        || {!isNil "BIS_WL_arsenalEnabled"}
        || {_mode isEqualTo "enhanced" && {isNil "_passThrough"} && {call FUNC(biMissionHooks)}}
    ) exitWith {};

    // What the vanilla arsenal was opened for, before it forgets.
    private _center = missionNamespace getVariable ["BIS_fnc_arsenal_center", player];
    private _cargo = missionNamespace getVariable ["BIS_fnc_arsenal_cargo", objNull];
    private _full = missionNamespace getVariable ["BIS_fnc_arsenal_fullArsenal", false];

    [{
        params ["_center", "_cargo", "_full", "_mode"];

        // Init has run: the vanilla display goes with its own exit.
        private _display = uiNamespace getVariable ["RscDisplayArsenal", displayNull];

        if (!isNull _display) then {
            _display closeDisplay 2;
        };

        // Not in Zeus: it is never stopped.
        if (_mode isEqualTo "block" && {isNull (findDisplay 312)}) exitWith {
            call FUNC(showBlocked);
        };

        if (isNull _center || {!local _center}) exitWith {};

        ([_cargo, _full, _center] call FUNC(biItems)) params ["_all", "_classes"];

        private _box = [_cargo, _center] select isNull _cargo;

        if (_all) then {
            [_box, _center, true, nil, displayNull, "bi"] call FUNC(openWindow);
        } else {
            [_box, _center, false, _classes, displayNull, "bi"] call FUNC(openWindow);
        };
    }, [_center, _cargo, _full, _mode]] call EFUNC(gui,later);
}] call BIS_fnc_addScriptedEventHandler;

// The "leave it alone" mode reports what does not fit once the vanilla arsenal closed.
[missionNamespace, "arsenalPreOpen", {
    params [["_display", displayNull], ["_center", objNull, [objNull]]];

    if ((missionNamespace getVariable [QGVAR(biArsenal), "vanilla"]) isEqualTo "vanilla") then {
        ["open", _center] call FUNC(biLeaveAlone);
    };
}] call BIS_fnc_addScriptedEventHandler;

[missionNamespace, "arsenalClosed", {
    // The vanilla window is gone: the next open is judged anew.
    GVAR(biLetThrough) = false;

    ["closed", objNull] call FUNC(biLeaveAlone);
}] call BIS_fnc_addScriptedEventHandler;
