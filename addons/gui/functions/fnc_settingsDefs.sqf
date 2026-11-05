#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The rows of the settings card under the sizes (fnc_openSizeMenu): each player's own CBA settings, the same ones as in CBA's options
 * and always in sync with them (fnc_settingsRow writes to CBA, the card reads what is set). A row whose addon is not loaded is left out.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The rows, in their order <ARRAY>: a caption [""," name"], or
 *   [setting, name, tip, kind, default, data] - kind "check" (no data), "list" (data [values, names]) or "step" (data [least, most, step])
 *
 * Example:
 * private _rows = call aio_gui_fnc_settingsDefs;
 *
 * Public: No
 */

private _rows = [
    ["", LLSTRING(SettingsMenu_Shown)],
    [QGVAR(showWeight), LLSTRING(Setting_ShowWeight), LLSTRING(Setting_ShowWeight_Desc), "check", true],
    [QGVAR(showGear), LLSTRING(Setting_ShowGear), LLSTRING(Setting_ShowGear_Desc), "check", true],
    [QGVAR(showSmallSlots), LLSTRING(Setting_ShowSmallSlots), LLSTRING(Setting_ShowSmallSlots_Desc), "check", true],
    [QGVAR(showHotbar), LLSTRING(Setting_ShowHotbar), LLSTRING(Setting_ShowHotbar_Desc), "check", true],
    [QGVAR(showFooter), LLSTRING(Setting_ShowFooter), LLSTRING(Setting_ShowFooter_Desc), "check", true],
    [QGVAR(showNearby), LLSTRING(Setting_ShowNearby), LLSTRING(Setting_ShowNearby_Desc), "check", true],
    ["", LLSTRING(SettingsMenu_Place)],
    [
        QGVAR(columnOrder), LLSTRING(Setting_ColumnOrder), LLSTRING(Setting_ColumnOrder_Desc), "list", "equipment,free,loot,storage",
        [
            ["equipment,free,loot,storage", "equipment,loot,storage,free", "free,loot,storage,equipment", "loot,storage,free,equipment", "loot,equipment,free,storage"],
            [LLSTRING(ColumnOrder_Default), LLSTRING(ColumnOrder_Left), LLSTRING(ColumnOrder_Right), LLSTRING(ColumnOrder_Apart), LLSTRING(ColumnOrder_Middle)]
        ]
    ],
    [
        QGVAR(lootSide), LLSTRING(Setting_LootSide), LLSTRING(Setting_LootSide_Desc), "list", "left",
        [["left", "right"], [LLSTRING(Setting_LootSide_Left), LLSTRING(Setting_LootSide_Right)]]
    ],
    ["", LLSTRING(SettingsMenu_Tiles)],
    [QGVAR(tileNames), LLSTRING(Setting_TileNames), LLSTRING(Setting_TileNames_Desc), "check", false],
    [QGVAR(compareTooltip), LLSTRING(Setting_CompareTooltip), LLSTRING(Setting_CompareTooltip_Desc), "check", true],
    [QGVAR(magazineFillBar), LLSTRING(Setting_MagazineFillBar), LLSTRING(Setting_MagazineFillBar_Desc), "check", true],
    [QGVAR(magazineText), LLSTRING(Setting_MagazineText), LLSTRING(Setting_MagazineText_Desc), "check", true],
    ["", LLSTRING(SettingsMenu_Behaviour)],
    [
        QGVAR(doubleClick), LLSTRING(Setting_DoubleClick), LLSTRING(Setting_DoubleClick_Desc), "list", "move",
        [["move", "menu", "none"], [LLSTRING(Setting_DoubleClick_Move), LLSTRING(Setting_DoubleClick_Menu), LLSTRING(Setting_DoubleClick_None)]]
    ],
    [QGVAR(moveToStop), LLSTRING(Setting_MoveToStop), LLSTRING(Setting_MoveToStop_Desc), "check", true],
    [QEGVAR(weight,notify), LELSTRING(weight,Setting_Notify), LELSTRING(weight,Setting_Notify_Desc), "check", true],
    [
        QEGVAR(hotbar,hudMode), LELSTRING(hotbar,Setting_HudMode), LELSTRING(hotbar,Setting_HudMode_Desc), "list", 1,
        [[0, 1, 2], [LELSTRING(hotbar,HudMode_Never), LELSTRING(hotbar,HudMode_InUse), LELSTRING(hotbar,HudMode_Always)]]
    ],
    [QEGVAR(hotbar,hudTime), LELSTRING(hotbar,Setting_HudTime), LELSTRING(hotbar,Setting_HudTime_Desc), "step", 4, [1, 15, 1]],
    [QEGVAR(hotbar,leaderKeys), LELSTRING(hotbar,Setting_LeaderKeys), LELSTRING(hotbar,Setting_LeaderKeys_Desc), "check", true]
];

_rows select {(_x select 0) isEqualTo "" || {!isNil {missionNamespace getVariable (_x select 0)}}}
