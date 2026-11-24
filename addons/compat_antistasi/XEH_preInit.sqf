#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// Antistasi's files as this addon runs them, compiled once (fnc_patched).
GVAR(patched) = createHashMap;

// Mag Repack's window ends as Antistasi made them and as this addon wraps them (fnc_wrapMagRepack), and the places
// noted when it opened.
GVAR(mrCreate) = {};
GVAR(mrDestroy) = {};
GVAR(mrLayout) = [];

GVAR(mrCreateWrapper) = {
    GVAR(mrLayout) = [player] call FUNC(layoutOf);
    _this call GVAR(mrCreate)
};

GVAR(mrDestroyWrapper) = {
    private _result = _this call GVAR(mrDestroy);

    if (GVAR(mrLayout) isNotEqualTo []) then {
        [player, GVAR(mrLayout)] call FUNC(restorePlaces);
        GVAR(mrLayout) = [];
    };

    if (!isNil "_result") then {_result}
};

// Antistasi is not a required addon (config.cpp): without it nothing here does anything.
GVAR(loaded) = isClass (configFile >> "CfgPatches" >> "A3A_core");

if (!GVAR(loaded)) exitWith {
    ADDON = true;
};

if (hasInterface) then {
    // The rebels' money on the window's footer, as Antistasi writes it on the vanilla inventory (fnc_moneyText).
    EGVAR(gui,footerInfo) pushBack FUNC(moneyText);

    // A body or an enemy box looked into through the window: Antistasi's undercover check, as its InventoryOpened
    // handler does for what the engine opens (fnc_onLooked).
    [QEGVAR(gui,containerOpened), {_this call FUNC(onLooked)}] call CBA_fnc_addEventHandler;

    // Where things lie goes along with Antistasi's personal save, and Strict mode's hidden holder with it
    // (fnc_onSave, fnc_onLoad). Here rather than in the postInit: the load may come early.
    [A3A_EVENT_PLAYER_SAVE, {_this call FUNC(onSave)}] call CBA_fnc_addEventHandler;
    [A3A_EVENT_PLAYER_LOAD, {_this call FUNC(onLoad)}] call CBA_fnc_addEventHandler;
};

ADDON = true;
