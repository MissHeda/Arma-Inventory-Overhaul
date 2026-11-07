#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The least a column or a part of the equipment column can be made in the edit mode (fnc_openLayoutEditor, fnc_columnRects). A grid
 * column cannot be narrower than its grid, ten cells wide at the tile scale (COLUMN_W): the tile scale is what makes it narrower. Its
 * height is free, it scrolls. A part on its own (fnc_drawEquipmentCards) needs the height of what it holds, with its panel's padding:
 * the weight card, a weapon card, the gear's two rows, the hotbar's row.
 *
 * Arguments:
 * 0: The column or part: "equipment", "storage", "loot", "weight", "weapons", "gear" or "hotbar" <STRING>
 * 1: A grid column's width <NUMBER>
 *
 * Return Value:
 * [width, height] <ARRAY>
 *
 * Example:
 * ["storage", 0.4] call aio_gui_fnc_columnMinimum;
 *
 * Public: No
 */

params ["_id", "_columnW"];

private _pad = UNIT * 0.8;
private _label = TEXT_UNIT * 0.8;

switch (_id) do {
    // The weapons, and what of the weight, the gear and the hotbar still stands in it - not placed on its own.
    case "equipment": {
        private _placed = ((missionNamespace getVariable [QGVAR(layoutRects), ""]) splitString ";") apply {(_x splitString ":") param [0, ""]};
        private _height = UNIT * 6;

        {
            _x params ["_part", "_partH"];

            if (!(_part in _placed) && {[_part] call FUNC(partShown)}) then {
                _height = _height + _partH;
            };
        } forEach [["weight", UNIT * 2.4], ["gear", UNIT * 7], ["hotbar", UNIT * 2.6]];

        [SQUARE(UNIT * 12), _height]
    };
    case "weight": {[SQUARE(UNIT * 8), TEXT_UNIT * 2.2 + _pad]};
    case "weapons": {[SQUARE(UNIT * 10), _label + TEXT_UNIT * 0.74 + UNIT * 2.6 + _pad]};
    case "gear": {[SQUARE(UNIT * 10), _label + TEXT_UNIT * 0.62 + UNIT * (2.4 + 0.3 + 1.2) + _pad]};
    case "hotbar": {[SQUARE(UNIT * 8), _label + UNIT * 1.2 + _pad]};
    default {[_columnW, UNIT * 8]};
}
