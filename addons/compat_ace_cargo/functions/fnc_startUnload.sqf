#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Starts unloading a loaded thing from the window - the Unload button of its cargo card. ACE's own
 * progress bar is not used: it closes every dialog first, which would close this window. Instead the button
 * becomes a bar of the time ACE takes (ace_cargo_loadTimeCoefficient times the size, fnc_getDelayItem),
 * kept up by fnc_unloadFrame, and at its end ACE unloads it the way its own menu does (fnc_finishUnload).
 *
 * Checked first as ACE checks on the click: the card's own rules (fnc_rowState), then the whole of
 * ace_cargo_fnc_canUnloadItem with the search for a free place. With no time to wait, it unloads at once.
 *
 * Arguments:
 * 0: Vehicle or crate it is loaded in <OBJECT>
 * 1: The loaded thing - an object, or a class name <OBJECT or STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_vehicle, _crate] call einv_compat_ace_cargo_fnc_startUnload;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull]], ["_item", objNull, [objNull, ""]]];

if (isNull _holder) exitWith {};

private _unit = ACE_player;
private _state = [_holder, _item, _unit] call FUNC(rowState);

if !(_state get "canUnload") exitWith {
    [_state get "unloadTip"] call EFUNC(gui,flashHint);
};

// The whole check, with the search for a free place - once, as ACE does on the click.
if !([_item, _holder, _unit] call ACEFUNC(cargo,canUnloadItem)) exitWith {
    [[localize "STR_ACE_Cargo_UnloadingFailed", [_item, true] call ACEFUNC(cargo,getNameItem)] call FUNC(aceText)] call EFUNC(gui,flashHint);
};

// ACE's time for it; its own function is not public, so should it be gone the same product is worked out here.
private _duration = if (isNil QACEFUNC(cargo,getDelayItem)) then {
    (missionNamespace getVariable [QACEGVAR(cargo,loadTimeCoefficient), 5]) * (_item call ACEFUNC(cargo,getSizeItem))
} else {
    [_item, false] call ACEFUNC(cargo,getDelayItem)
};

if (_duration <= 0) exitWith {
    [_holder, _item] call FUNC(finishUnload);
};

// One at a time, and the old bar's handler is gone before a new one starts.
["", false] call FUNC(stopUnload);

GVAR(unloading) = [_item, _holder, CBA_missionTime, _duration];
GVAR(unloadPFH) = [FUNC(unloadFrame), 0, []] call CBA_fnc_addPerFrameHandler;

// The crate is handled: it sounds like being opened. A thing not made yet has only the lift.
if (_item isEqualType objNull) then {
    ["open", "", _item] call EFUNC(gui,playSound);
} else {
    ["lift"] call EFUNC(gui,playSound);
};

private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

if (!isNull _display) then {
    [_display] call EFUNC(gui,build);
};
