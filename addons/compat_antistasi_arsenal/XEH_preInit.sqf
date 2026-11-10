#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// For everyone alike: whether the grid panel lies beside Antistasi's arsenal. Off, JNA's arsenal is left as it is.
[
    QGVAR(panel),
    "CHECKBOX",
    [LLSTRING(Setting_Panel), LLSTRING(Setting_Panel_Desc)],
    true
] call EFUNC(main,addSetting);

// JNA's stock as the grid panel's pool: the vanilla arsenal JNA opens is claimed (never sent to ACE Arsenal or blocked),
// its cargo lists are read, and every add and take of the panel is settled with the server's stock.
[createHashMapFromArray [
    ["name", "Antistasi (JNA)"],
    ["claims", FUNC(claims)],
    ["panel", {missionNamespace getVariable [QGVAR(panel), true]}],
    ["rowClass", FUNC(rowClass)],
    ["available", FUNC(available)],
    ["census", FUNC(census)],
    ["settle", FUNC(settle)]
]] call EFUNC(arsenal,registerPool);

ADDON = true;
