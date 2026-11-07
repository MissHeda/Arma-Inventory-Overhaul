#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * ACE Arsenal in this mod's look (Mia, after 0.6.85: "ACE custom"): the same window, the same lists in the same order, ACE's own
 * controls and every mod that adds to them (ACE Arsenal Extended's options included) - only drawn on this mod's glass. ACE's square
 * backgrounds (the two list blocks, the menu bar's buttons, the stats, info, actions and message boxes, the search fields and sort
 * boxes) are made see-through, and under each lies a panel of the inventory's theme with its round corners (aio_gui_theme); the
 * lists' frames go; their words take the theme's text colour and font.
 *
 * The panels lie on the display under ACE's (its parent - the mission's, Eden's or Zeus'), so they are drawn below ACE's controls
 * and never take a click. Each frame they follow ACE's controls: where each is, whether it is shown and how faded (ACE's Hide,
 * Backspace, and its loadouts screen). They go when the arsenal closes.
 *
 * The player's setting aio_arsenal_aceStyle: "aio" this look, "ace" ACE's own, as before.
 *
 * Arguments:
 * 0: What to do: "apply" [ACE Arsenal's display], "frame", "remove" <STRING>
 * 1: Arguments <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * ["apply", [_display]] call aio_arsenal_fnc_aceSkin;
 *
 * Public: No
 */

disableSerialization;

params [["_mode", "", [""]], ["_arguments", [], [[]]]];

// A control's place on the screen: its own in its group, plus each group's above it.
private _fnc_screenRect = {
    params ["_control"];

    private _rect = ctrlPosition _control;
    private _group = ctrlParentControlsGroup _control;

    while {!isNull _group} do {
        (ctrlPosition _group) params ["_groupX", "_groupY"];

        _rect set [0, (_rect select 0) + _groupX];
        _rect set [1, (_rect select 1) + _groupY];
        _group = ctrlParentControlsGroup _group;
    };

    _rect
};

// Shown on the screen: it and every group above it.
private _fnc_shown = {
    params ["_control"];

    private _shown = ctrlShown _control;
    private _group = ctrlParentControlsGroup _control;

    while {_shown && {!isNull _group}} do {
        _shown = ctrlShown _group;
        _group = ctrlParentControlsGroup _group;
    };

    _shown
};

switch (_mode) do {
    case "apply": {
        _arguments params [["_display", displayNull, [displayNull]]];

        ["remove"] call FUNC(aceSkin);

        if (isNull _display || {(missionNamespace getVariable [QGVAR(aceStyle), "aio"]) isNotEqualTo "aio"}) exitWith {};

        private _under = displayParent _display;

        if (isNull _under) then {
            _under = findDisplay 46;
        };

        if (isNull _under) exitWith {};

        private _theme = missionNamespace getVariable [QEGVAR(gui,theme), createHashMap];
        private _panel = _theme getOrDefault ["panel", [0.08, 0.09, 0.11, 0.85]];
        private _button = _theme getOrDefault ["button", [1, 1, 1, 0.08]];
        private _field = _theme getOrDefault ["slot", [1, 1, 1, 0.06]];
        private _text = _theme getOrDefault ["text", [1, 1, 1, 1]];
        private _font = _theme getOrDefault ["font", "PuristaMedium"];
        private _radius = (_theme getOrDefault ["radius", 0]) max 0;
        private _clear = [0, 0, 0, 0];

        // [ACE's control, the colour under it, how round]: the blocks behind the lists, the boxes, the buttons and fields.
        private _specs = [
            [4, _panel, _radius], [6, _panel, _radius],
            [56, _panel, _radius], [55, _button, _radius * 0.6], [1101, _panel, _radius], [1104, _panel, _radius * 0.6],
            [90010, _panel, _radius], [90011, _panel, _radius], [9, _panel, _radius],
            [18, _field, _radius * 0.6], [19, _field, _radius * 0.6],
            [16, _field, _radius * 0.6], [161, _field, _radius * 0.6], [17, _field, _radius * 0.6], [171, _field, _radius * 0.6],
            [1001, _button, _radius * 0.6], [1002, _button, _radius * 0.6], [1003, _button, _radius * 0.6],
            [1004, _button, _radius * 0.6], [1005, _button, _radius * 0.6], [1006, _button, _radius * 0.6],
            [52, _button, _radius * 0.6], [53, _button, _radius * 0.6]
        ];

        private _pairs = [];

        {
            _x params ["_idc", "_colour", "_round"];

            private _control = _display displayCtrl _idc;

            if (isNull _control) then {continue};

            private _rect = [_control] call _fnc_screenRect;
            private _made = [_under, controlNull, _rect, _colour, _round min ((_rect select 3) / 2)] call EFUNC(gui,uiPanel);

            // Not the window's: a build of the panel sweeps what it made at the top level (aio_gui_fnc_uiCreate) - these stay.
            uiNamespace setVariable [QEGVAR(gui,created), (uiNamespace getVariable [QEGVAR(gui,created), []]) - _made];

            _control ctrlSetBackgroundColor _clear;
            _pairs pushBack [_control, _made, _rect];
        } forEach _specs;

        // The lists' frames go; the lists themselves lie on the block's panel.
        {
            private _frame = _display displayCtrl _x;

            if (!isNull _frame) then {
                _frame ctrlSetTextColor _clear;
            };
        } forEach [3, 5];

        {
            private _list = _display displayCtrl _x;

            if (!isNull _list) then {
                _list ctrlSetBackgroundColor _clear;
                _list ctrlSetFont _font;
                _list ctrlSetTextColor _text;
            };
        } forEach [13, 14, 15];

        uiNamespace setVariable [QGVAR(skinPairs), _pairs];

        GVAR(skinFrame) = [{["frame"] call FUNC(aceSkin)}, 0] call CBA_fnc_addPerFrameHandler;
    };

    case "frame": {
        private _pairs = uiNamespace getVariable [QGVAR(skinPairs), []];

        if (_pairs isEqualTo []) exitWith {};

        {
            _x params ["_control", "_made", "_rect"];

            if (isNull _control) then {
                {_x ctrlShow false} forEach _made;
                continue;
            };

            private _shown = [_control] call _fnc_shown;
            private _now = [_control] call _fnc_screenRect;

            // Moved or sized by ACE (its Hide, a resized window): the panel goes with it.
            if (_now isNotEqualTo _rect) then {
                (_now select [0, 2]) params ["_toX", "_toY"];
                (_rect select [0, 2]) params ["_fromX", "_fromY"];

                {
                    private _at = ctrlPosition _x;

                    _x ctrlSetPosition [(_at select 0) + _toX - _fromX, (_at select 1) + _toY - _fromY];
                    _x ctrlCommit 0;
                } forEach _made;

                _x set [2, _now];
            };

            {
                if (ctrlShown _x isNotEqualTo _shown) then {
                    _x ctrlShow _shown;
                };

                if (ctrlFade _x != ctrlFade _control) then {
                    _x ctrlSetFade (ctrlFade _control);
                    _x ctrlCommit 0;
                };
            } forEach _made;
        } forEach _pairs;
    };

    case "remove": {
        if (!isNil QGVAR(skinFrame)) then {
            [GVAR(skinFrame)] call CBA_fnc_removePerFrameHandler;
            GVAR(skinFrame) = nil;
        };

        {
            {ctrlDelete _x} forEach (_x select 1);
        } forEach (uiNamespace getVariable [QGVAR(skinPairs), []]);

        uiNamespace setVariable [QGVAR(skinPairs), []];
    };
};
