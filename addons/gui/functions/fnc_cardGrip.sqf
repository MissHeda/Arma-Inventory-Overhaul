#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Moves a weapon card of the equipment column to another place by its grip (fnc_drawEquipmentCards): press on the
 * six dots at the right end of its header, move the mouse up or down, let go. While it is held a line in the accent
 * colour shows between which cards it will go; let go where it already is and nothing changes. The order is each
 * player's own, kept in the profile (GVAR(weaponOrder)). The second primary's card, where no two-primary mod gives
 * the unit that slot, is not shown and keeps its place in the order for when one does.
 *
 * Three steps: "begin" from the grip's press, "move" and "end" from the frame (fnc_onFrame) for as long as it is
 * held - the release is seen there whichever control it happens over. What the cards drew this build is in
 * GVAR(cardSpans): [slot, anchor as fnc_gridOrigin takes it, width, height] each, top down.
 *
 * Arguments:
 * 0: Step, "begin", "move" or "end" <STRING>
 * 1: For "begin": the card's slot <STRING>; 2: the line's colour <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["begin", "handgun", [0.84, 0.54, 0.1, 1]] call aio_gui_fnc_cardGrip;
 *
 * Public: No
 */

disableSerialization;

params [["_step", "", [""]], ["_slot", "", [""]], ["_color", [1, 1, 1, 1], [[]]]];

// The cards as they lie on the screen now (the column may have scrolled): [slot, x, y, width, height] each.
private _fnc_spans = {
    (uiNamespace getVariable [QGVAR(cardSpans), []]) apply {
        _x params ["_spanSlot", "_anchor", "_spanW", "_spanH"];

        ([_anchor] call FUNC(gridOrigin)) params ["_spanX", "_spanY"];

        [_spanSlot, _spanX, _spanY, _spanW, _spanH]
    }
};

switch (_step) do {
    case "begin": {
        private _display = uiNamespace getVariable [QGVAR(display), displayNull];

        if (isNull _display || {((call _fnc_spans) findIf {(_x select 0) isEqualTo _slot}) < 0}) exitWith {};

        private _line = [_display, "AIO_PanelRect", controlNull, [0, 0, 0, 0]] call FUNC(uiCreate);
        _line ctrlSetBackgroundColor _color;

        uiNamespace setVariable [QGVAR(cardDrag), [_slot, _line, -1]];

        ["move"] call FUNC(cardGrip);
    };

    case "move": {
        (uiNamespace getVariable [QGVAR(cardDrag), []]) params [["_held", ""], ["_line", controlNull], ["_target", -1]];

        private _spans = call _fnc_spans;

        // The window was built again meanwhile and took the line with it: the drag ends with nothing moved.
        if (isNull _line || {_spans isEqualTo []}) exitWith {
            uiNamespace setVariable [QGVAR(cardDrag), []];
        };

        // The gap the mouse is nearest: before the first card whose middle lies below it.
        getMousePosition params ["", "_mouseY"];

        _target = _spans findIf {_mouseY < (_x select 2) + (_x select 4) / 2};

        if (_target < 0) then {
            _target = count _spans;
        };

        private _first = _spans select 0;
        private _lineY = if (_target < count _spans) then {
            ((_spans select _target) select 2) - pixelH * 4
        } else {
            private _last = _spans select -1;
            (_last select 2) + (_last select 4) + pixelH * 2
        };

        _line ctrlSetPosition [_first select 1, _lineY, _first select 3, pixelH * 2];
        _line ctrlCommit 0;

        uiNamespace setVariable [QGVAR(cardDrag), [_held, _line, _target]];
    };

    case "end": {
        (uiNamespace getVariable [QGVAR(cardDrag), []]) params [["_held", ""], ["_line", controlNull], ["_target", -1]];

        uiNamespace setVariable [QGVAR(cardDrag), []];
        ctrlDelete _line;

        private _shown = (uiNamespace getVariable [QGVAR(cardSpans), []]) apply {_x select 0};
        private _from = _shown find _held;

        if (_from < 0 || {_target < 0}) exitWith {};

        // Let go below itself, the card leaves its own place first.
        if (_target > _from) then {
            _target = _target - 1;
        };

        if (_target == _from) exitWith {};

        _shown deleteAt _from;
        _shown insert [_target, [_held]];

        // A card not shown keeps its place in the order.
        private _order = +_shown;

        {
            if !(_x in _order) then {
                _order insert [_forEachIndex min count _order, [_x]];
            };
        } forEach GVAR(weaponOrder);

        GVAR(weaponOrder) = _order;
        profileNamespace setVariable [QGVAR(weaponOrder), +_order];
        saveProfileNamespace;

        [] call FUNC(buildSoon);
    };
};
