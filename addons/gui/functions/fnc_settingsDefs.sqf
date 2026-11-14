#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The rows of the settings card under the sizes (fnc_openSizeMenu): each player's own CBA settings, the same ones as in CBA's options
 * and always in sync with them (fnc_settingsRow writes to CBA, the card reads what is set). A row whose addon is not loaded is left out.
 *
 * Arguments:
 * None - or ["all"]: the rows that are hidden for now as well (the weapon pictures' own while those are off)
 *
 * Return Value:
 * The rows, in their order <ARRAY>: a caption [""," name"], or
 *   [setting, name, tip, kind, default, data] - kind "check" (no data), "list" (data [values, names]), "step" (data [least, most, step, unit])
 *   or "group": several steps on one line, each pressed on its own (data [[setting, short name, least, most, step, unit, default, tip], ...])
 *
 * Example:
 * private _rows = call aio_gui_fnc_settingsDefs;
 *
 * Public: No
 */

private _rows = [
    ["", LLSTRING(SettingsMenu_Shown)],
    [QGVAR(font), LLSTRING(Setting_Font), LLSTRING(Setting_Font_Desc), "list", "purista", [["purista", "puristaLight", "roboto", "robotoLight", "tahoma", "lucida"], [LLSTRING(Font_Purista), LLSTRING(Font_PuristaLight), LLSTRING(Font_Roboto), LLSTRING(Font_RobotoLight), LLSTRING(Font_Tahoma), LLSTRING(Font_Lucida)]]],
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
        [["left", "right"], [LLSTRING(SettingsMenu_LootLeft), LLSTRING(SettingsMenu_LootRight)]]
    ],
    ["", LLSTRING(SettingsMenu_Tiles)],
    [QGVAR(tileNames), LLSTRING(Setting_TileNames), LLSTRING(Setting_TileNames_Desc), "check", false],
    [QGVAR(weapon3D), LLSTRING(Setting_Weapon3D), LLSTRING(Setting_Weapon3D_Desc), "check", missionNamespace getVariable [QGVAR(weapon3DDefault), false]],
    [QGVAR(weapon3DAuto), LLSTRING(Setting_Weapon3DAuto), LLSTRING(Setting_Weapon3DAuto_Desc), "check", true],
    [
        QGVAR(weapon3DZoom_primary), LLSTRING(Setting_Weapon3D_Primary), LLSTRING(Setting_Weapon3DGroup_Desc), "group", 100, [
            [QGVAR(weapon3DZoom_primary), LLSTRING(Weapon3D_Size), 50, 200, 5, "%", 100, LLSTRING(Setting_Weapon3DZoom_Desc)],
            [QGVAR(weapon3DOffsetX_primary), "X", -50, 50, 5, "%", 0, LLSTRING(Setting_Weapon3DOffsetX_Desc)],
            [QGVAR(weapon3DOffsetY_primary), "Y", -50, 50, 5, "%", 0, LLSTRING(Setting_Weapon3DOffsetY_Desc)]
        ]
    ],
    [
        QGVAR(weapon3DZoom_handgun), LLSTRING(Setting_Weapon3D_Handgun), LLSTRING(Setting_Weapon3DGroup_Desc), "group", 100, [
            [QGVAR(weapon3DZoom_handgun), LLSTRING(Weapon3D_Size), 50, 200, 5, "%", 100, LLSTRING(Setting_Weapon3DZoom_Desc)],
            [QGVAR(weapon3DOffsetX_handgun), "X", -50, 50, 5, "%", 0, LLSTRING(Setting_Weapon3DOffsetX_Desc)],
            [QGVAR(weapon3DOffsetY_handgun), "Y", -50, 50, 5, "%", 0, LLSTRING(Setting_Weapon3DOffsetY_Desc)]
        ]
    ],
    [
        QGVAR(weapon3DZoom_launcher), LLSTRING(Setting_Weapon3D_Launcher), LLSTRING(Setting_Weapon3DGroup_Desc), "group", 100, [
            [QGVAR(weapon3DZoom_launcher), LLSTRING(Weapon3D_Size), 50, 200, 5, "%", 100, LLSTRING(Setting_Weapon3DZoom_Desc)],
            [QGVAR(weapon3DOffsetX_launcher), "X", -50, 50, 5, "%", 0, LLSTRING(Setting_Weapon3DOffsetX_Desc)],
            [QGVAR(weapon3DOffsetY_launcher), "Y", -50, 50, 5, "%", 0, LLSTRING(Setting_Weapon3DOffsetY_Desc)]
        ]
    ],
    [
        QGVAR(weapon3DZoom_primary2), LLSTRING(Setting_Weapon3D_Primary2), LLSTRING(Setting_Weapon3DGroup_Desc), "group", 100, [
            [QGVAR(weapon3DZoom_primary2), LLSTRING(Weapon3D_Size), 50, 200, 5, "%", 100, LLSTRING(Setting_Weapon3DZoom_Desc)],
            [QGVAR(weapon3DOffsetX_primary2), "X", -50, 50, 5, "%", 0, LLSTRING(Setting_Weapon3DOffsetX_Desc)],
            [QGVAR(weapon3DOffsetY_primary2), "Y", -50, 50, 5, "%", 0, LLSTRING(Setting_Weapon3DOffsetY_Desc)]
        ]
    ],
    [
        QGVAR(weapon3DZoom_handgun2), LLSTRING(Setting_Weapon3D_Handgun2), LLSTRING(Setting_Weapon3DGroup_Desc), "group", 100, [
            [QGVAR(weapon3DZoom_handgun2), LLSTRING(Weapon3D_Size), 50, 200, 5, "%", 100, LLSTRING(Setting_Weapon3DZoom_Desc)],
            [QGVAR(weapon3DOffsetX_handgun2), "X", -50, 50, 5, "%", 0, LLSTRING(Setting_Weapon3DOffsetX_Desc)],
            [QGVAR(weapon3DOffsetY_handgun2), "Y", -50, 50, 5, "%", 0, LLSTRING(Setting_Weapon3DOffsetY_Desc)]
        ]
    ],
    [QGVAR(compareTooltip), LLSTRING(Setting_CompareTooltip), LLSTRING(Setting_CompareTooltip_Desc), "check", true],
    [QGVAR(magazineFillBar), LLSTRING(Setting_MagazineFillBar), LLSTRING(Setting_MagazineFillBar_Desc), "check", true],
    [QGVAR(magazineText), LLSTRING(Setting_MagazineText), LLSTRING(Setting_MagazineText_Desc), "check", true],
    ["", LLSTRING(SettingsMenu_Behaviour)],
    [
        QGVAR(doubleClick), LLSTRING(Setting_DoubleClick), LLSTRING(Setting_DoubleClick_Desc), "list", "move",
        [["move", "menu", "none"], [LLSTRING(Setting_DoubleClick_Move), LLSTRING(Setting_DoubleClick_Menu), LLSTRING(Setting_DoubleClick_None)]]
    ],
    [QGVAR(moveToStop), LLSTRING(Setting_MoveToStop), LLSTRING(Setting_MoveToStop_Desc), "check", true],
    [QGVAR(quickTargetIcon), LLSTRING(Setting_QuickTargetIcon), LLSTRING(Setting_QuickTargetIcon_Desc), "check", true],
    [QGVAR(updateCheck), LLSTRING(Setting_UpdateCheck), LLSTRING(Setting_UpdateCheck_Desc), "check", true],
    [QEGVAR(weight,notify), LELSTRING(weight,Setting_Notify), LELSTRING(weight,Setting_Notify_Desc), "check", true],
    [
        QEGVAR(hotbar,hudMode), LELSTRING(hotbar,Setting_HudMode), LELSTRING(hotbar,Setting_HudMode_Desc), "list", 1,
        [[0, 1, 2], [LELSTRING(hotbar,HudMode_Never), LELSTRING(hotbar,HudMode_InUse), LELSTRING(hotbar,HudMode_Always)]]
    ],
    [QEGVAR(hotbar,hudTime), LELSTRING(hotbar,Setting_HudTime), LELSTRING(hotbar,Setting_HudTime_Desc), "step", 4, [1, 15, 1, "s"]],
    [QEGVAR(hotbar,leaderKeys), LELSTRING(hotbar,Setting_LeaderKeys), LELSTRING(hotbar,Setting_LeaderKeys_Desc), "check", true]
];

// The weapon pictures' own rows only while the pictures are on, and their size and place only while they are not put in the
// middle by themselves: twelve values in four rows the card has no room for otherwise (Mia, 0.6.108: "list too long"; 0.7.12: the
// nudges only with "Centre weapon pictures" off). Asked for with ["all"] every row comes - a reset takes the hidden ones back too.
private _all = _this isEqualTo ["all"];
private _real = missionNamespace getVariable [QGVAR(weapon3D), false];
private _auto = missionNamespace getVariable [QGVAR(weapon3DAuto), true];

_rows select {
    ((_x select 0) isEqualTo "" || {!isNil {missionNamespace getVariable (_x select 0)}})
    && {
        _all || {
            ((_x param [3, ""]) isNotEqualTo "group" || {_real && {!_auto}})
            && {(_x select 0) isNotEqualTo QGVAR(weapon3DAuto) || {_real}}
        }
    }
}
