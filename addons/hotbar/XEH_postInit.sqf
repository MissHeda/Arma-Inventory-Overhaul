#include "script_component.hpp"
#include "defines.hpp"

// Nothing here runs on a dedicated server or a headless client: the bar is the player's own, on the
// player's own machine, and puts nothing on the network.
if (!hasInterface) exitWith {};

call FUNC(loadSlots);

#include "initKeybinds.inc.sqf"

// A new body (respawn, team switch, Zeus remote control) has other things on it: the counts are read
// again at once, and the bar shows them.
["unit", {
    GVAR(nextCount) = 0;
    call FUNC(hudPing);
}] call CBA_fnc_addPlayerEventHandler;

["loadout", {
    GVAR(nextCount) = 0;
}] call CBA_fnc_addPlayerEventHandler;

// A setting of the hotbar changed: what the bar shows is read again; "always" shows it now, "never"
// takes it off the screen.
["CBA_SettingChanged", {
    params ["_setting"];

    if ((_setting select [0, 11]) isNotEqualTo "aio_hotbar_") exitWith {};

    GVAR(nextCount) = 0;
    GVAR(hudSignature) = "";

    switch (GVAR(hudMode)) do {
        case 2: {call FUNC(hudPing)};
        case 0: {QGVAR(hud) cutText ["", "PLAIN"]};
        default {};
    };
}] call CBA_fnc_addEventHandler;

// Once the settings are in: "always" shows the bar from the start, and the keys the slots share with
// other mods and Arma's command menus are said once the keybinds of all mods are in too.
private _fnc_settingsIn = {
    if (GVAR(hudMode) == 2) then {
        call FUNC(hudPing);
    };

    [FUNC(checkKeys), [], 5] call CBA_fnc_waitAndExecute;
};

// CBA raises its event a frame after every postInit has run; cba_settings_ready is set just before it.
if (isNil "cba_settings_ready") then {
    ["CBA_settingsInitialized", _fnc_settingsIn] call CBA_fnc_addEventHandler;
} else {
    call _fnc_settingsIn;
};
