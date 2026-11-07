#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * ACE Arsenal in this mod's look (Mia, after 0.6.85: "ACE custom"): the same window, the same lists in the same order, ACE's own
 * controls and every mod that adds to them (ACE Arsenal Extended's options included) - only drawn on this mod's glass. ACE's square
 * backgrounds (the two list blocks, the menu bar's buttons, the stats, info, actions and message boxes, the search fields and sort
 * boxes) are made see-through, and under each lies a panel of the inventory's theme with its round corners (aio_gui_theme); the
 * lists' frames go; their words take the theme's text colour and font.
 *
 * The panels lie in controls groups this mod puts into ACE's background layer (aio_compat_ace_arsenal: aio_skin_0 ... - empty and
 * nought wide until used), the one layer drawn under all of ACE's controls: a control made at run time lies over everything, and
 * panels on the display under ACE's were not drawn at all (0.6.86, Mia). Each panel is the inspect card's: the theme's fill with a
 * faint round outline. Each frame they follow ACE's controls: where each is, whether it is shown and how faded (ACE's Hide,
 * Backspace, its loadouts screen). They are emptied when the arsenal closes. Without that addon (no ACE Arsenal) nothing is done.
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

        // The groups in ACE's background layer (aio_compat_ace_arsenal).
        private _groups = [];

        for "_i" from 0 to 27 do {
            private _group = _display displayCtrl (99000 + _i);

            if (!isNull _group) then {_groups pushBack _group};
        };

        if (_groups isEqualTo []) exitWith {};

        private _theme = missionNamespace getVariable [QEGVAR(gui,theme), createHashMap];
        private _panel = _theme getOrDefault ["panel", [0.08, 0.09, 0.11, 0.85]];
        private _button = _theme getOrDefault ["button", [1, 1, 1, 0.08]];
        private _field = _theme getOrDefault ["slot", [1, 1, 1, 0.06]];
        private _text = _theme getOrDefault ["text", [1, 1, 1, 1]];
        private _font = _theme getOrDefault ["font", "PuristaMedium"];
        // Round as the inspect card's boxes, whatever the theme's own corners (a sharp theme gave ACE's look back - seen in game, 0.6.88).
        private _unit = safezoneH / 40;
        private _radius = (_theme getOrDefault ["radius", 0]) max (_unit * 0.45);
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
        private _outline = [1, 1, 1, 0.16];

        {
            _x params ["_idc", "_colour", "_round"];

            private _control = _display displayCtrl _idc;

            if (isNull _control || {_groups isEqualTo []}) then {continue};

            private _group = _groups deleteAt 0;
            private _rect = [_control] call _fnc_screenRect;
            _rect params ["", "", "_w", "_h"];

            _group ctrlSetPosition _rect;
            _group ctrlCommit 0;
            _group ctrlShow true;

            private _radiusHere = _round min (_h / 2);
            private _made = [_display, _group, [0, 0, _w, _h], _colour, _radiusHere] call EFUNC(gui,uiPanel);

            _made append ([_display, _group, [0, 0, _w, _h], _outline, _radiusHere] call EFUNC(gui,uiRing));

            _control ctrlSetBackgroundColor _clear;
            _pairs pushBack [_control, [_group], _rect, _made];
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

        // ACE paints its backgrounds again (on a fill, a tab): what lies on the panels is kept see-through every frame.
        uiNamespace setVariable [QGVAR(skinClear), (_pairs apply {_x select 0}) + ([13, 14, 15] apply {_display displayCtrl _x})];

        GVAR(skinFrame) = [{["frame"] call FUNC(aceSkin)}, 0] call CBA_fnc_addPerFrameHandler;
    };

    case "frame": {
        private _pairs = uiNamespace getVariable [QGVAR(skinPairs), []];

        if (_pairs isEqualTo []) exitWith {};

        {
            if (!isNull _x) then {_x ctrlSetBackgroundColor [0, 0, 0, 0]};
        } forEach (uiNamespace getVariable [QGVAR(skinClear), []]);

        {
            _x params ["_control", "_made", "_rect"];

            if (isNull _control) then {
                {_x ctrlShow false} forEach _made;
                continue;
            };

            private _shown = [_control] call _fnc_shown;
            private _now = [_control] call _fnc_screenRect;

            // Moved by ACE (its Hide, a resized window): the panel's group goes with it.
            if ((_now select [0, 2]) isNotEqualTo (_rect select [0, 2])) then {
                {
                    _x ctrlSetPosition [_now select 0, _now select 1];
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
            _x params ["", "_groups", "", ["_inside", []]];

            {ctrlDelete _x} forEach _inside;

            {
                _x ctrlSetPosition [0, 0, 0, 0];
                _x ctrlCommit 0;
            } forEach _groups;
        } forEach (uiNamespace getVariable [QGVAR(skinPairs), []]);

        uiNamespace setVariable [QGVAR(skinPairs), []];
    };
};
