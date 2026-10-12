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

    if ((_setting select [0, 12]) isNotEqualTo "einv_hotbar_") exitWith {};

    GVAR(nextCount) = 0;
    GVAR(hudSignature) = "";

    switch (GVAR(hudMode)) do {
        case 2: {call FUNC(hudPing)};
        case 0: {QGVAR(hud) cutText ["", "PLAIN"]};
        default {};
    };
}] call CBA_fnc_addEventHandler;

// In the vanilla inventory (the replacement switched off) the hotbar has no row to drag onto, so the
// item context menu - the one CBA adds to it - offers it. Not while our own window is open: that
// window shows the options other mods add to the same menu itself, and would show these twice.
{
    _x params ["_name", "_show", "_statement"];

    ["#All", ["CONTAINER"], _name, [], "", [{true}, _show], _statement] call CBA_fnc_addItemContextMenuOption;
} forEach [
    [
        LLSTRING(Menu_BindPlain),
        {
            params ["", "", "_item"];

            call FUNC(isActive)
            && {isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull])}
            && {(GVAR(slots) findIf {_x == _item}) < 0}
            && {(call FUNC(firstFree)) >= 0}
            && {([_item] call FUNC(canBind)) select 0}
        },
        {
            params ["", "", "_item"];

            [call FUNC(firstFree), _item] call FUNC(bind);
            false
        }
    ],
    [
        LLSTRING(Menu_UnbindPlain),
        {
            params ["", "", "_item"];

            call FUNC(isActive)
            && {isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull])}
            && {(GVAR(slots) findIf {_x == _item}) >= 0}
        },
        {
            params ["", "", "_item"];

            [GVAR(slots) findIf {_x == _item}] call FUNC(unbind);
            false
        }
    ]
];

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
