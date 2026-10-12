#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Ctrl+C over a card, an item of the soldier's or a slot: copies the class name to the clipboard.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Something was under the mouse <BOOL>
 *
 * Example:
 * call einv_arsenal_fnc_copyClass;
 *
 * Public: No
 */

private _hover = EGVAR(gui,hover);
private _class = "";

switch (_hover param [0, ""]) do {
    case "tile": {
        private _grid = (uiNamespace getVariable [QEGVAR(gui,grids), []]) param [_hover param [1, -1], createHashMap];
        private _tile = (_grid getOrDefault ["tiles", []]) param [_hover param [2, -1], createHashMap];

        _class = _tile getOrDefault ["class", ""];
    };
    case "slot": {
        private _slot = (uiNamespace getVariable [QEGVAR(gui,slots), []]) param [_hover param [1, -1], []];

        _class = _slot param [1, ""];
    };
    default {};
};

if (_class isEqualTo "") exitWith {false};

// Written through ACE's extension where the game's own does not work (multiplayer clients).
if ([_class] call FUNC(clipboardWrite)) then {
    [format [LLSTRING(Hint_Copied), _class]] call FUNC(message);
};

true
