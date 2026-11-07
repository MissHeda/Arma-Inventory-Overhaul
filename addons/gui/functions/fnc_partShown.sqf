#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a part of the equipment column (fnc_drawEquipmentCards) is drawn at all: what the player switched off, and the hotbar where
 * that addon is loaded and on, in the inventory only. A part placed on its own in the edit mode (fnc_columnRects) gets its panel only
 * when it is drawn (fnc_layoutGlass), and a frame in the edit mode (fnc_openLayoutEditor) likewise.
 *
 * Arguments:
 * 0: The part: "weight", "weapons", "gear" or "hotbar" <STRING>
 *
 * Return Value:
 * Drawn <BOOL>
 *
 * Example:
 * ["hotbar"] call aio_gui_fnc_partShown;
 *
 * Public: No
 */

params [["_part", "", [""]]];

switch (_part) do {
    case "weight": {missionNamespace getVariable [QGVAR(showWeight), true]};
    case "weapons": {true};
    case "gear": {(missionNamespace getVariable [QGVAR(showGear), true]) || {missionNamespace getVariable [QGVAR(showSmallSlots), true]}};
    case "hotbar": {
        call FUNC(isInventoryMode) && {!isNil QEFUNC(hotbar,drawStrip)} && {call EFUNC(hotbar,isActive)}
            && {missionNamespace getVariable [QGVAR(showHotbar), true]}
    };
    default {false};
}
