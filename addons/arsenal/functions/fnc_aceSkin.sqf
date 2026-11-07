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
 * The player's setting aio_arsenal_aceStyle: "aio" this look, "ace" ACE's own, as before - with ACE's own white bar for the
 * picked row drawn here, as the addon makes ACE's see-through. In this look also: round tiles under the tabs, the open one lit in
 * the accent colour; the picked row round in the accent colour; the menu bar's buttons solid; and a card over the menu bar with
 * the picked item's facts as the inventory's hint line says them (fnc_aceInfo).
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

// ACE's grid unit, for the rows of its lists (sizeEx 7 GRID_H, no rowHeight of their own).
private _gridH = pixelH * pixelGridNoUIScale * 0.25; // ACE's pixelScale is a macro of its own, 0.25 - no command

// A list's picked row on the screen: [x, y, w, h], or [] when none is picked or it is scrolled out of sight.
private _fnc_pickedRow = {
    params ["_list"];

    private _nbox = ctrlType _list == 102;
    private _picked = [lbCurSel _list, lnbCurSelRow _list] select _nbox;
    private _count = [lbSize _list, (lnbSize _list) select 0] select _nbox;

    if (_picked < 0 || {_count == 0} || {!([_list] call _fnc_shown)}) exitWith {[]};

    private _rect = [_list] call _fnc_screenRect;
    _rect params ["_listX", "_listY", "_listW", "_listH"];

    private _rowH = 7 * _gridH;
    private _visible = floor (_listH / _rowH);
    private _top = round (((ctrlScrollValues _list) param [0, 0]) * ((_count - _visible) max 0));
    private _row = _picked - _top;

    if (_row < 0 || {_row >= _visible}) exitWith {[]};

    [_listX, _listY + _row * _rowH, _listW, _rowH]
};

switch (_mode) do {
    case "apply": {
        _arguments params [["_display", displayNull, [displayNull]]];

        ["remove"] call FUNC(aceSkin);

        if (isNull _display) exitWith {};

        // The groups in ACE's background layer (aio_compat_ace_arsenal); without it nothing is done.
        private _groups = [];

        for "_i" from 0 to (SKIN_GROUPS - 1) do {
            private _group = _display displayCtrl (SKIN_IDC + _i);

            if (!isNull _group) then {_groups pushBack _group};
        };

        if (_groups isEqualTo []) exitWith {};

        private _aio = (missionNamespace getVariable [QGVAR(aceStyle), "aio"]) isEqualTo "aio";
        private _theme = missionNamespace getVariable [QEGVAR(gui,theme), createHashMap];
        private _panel = _theme getOrDefault ["panel", [0.08, 0.09, 0.11, 0.85]];
        private _tile = _theme getOrDefault ["slot", [1, 1, 1, 0.06]];
        private _accent = (_theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]) select [0, 3];
        private _text = _theme getOrDefault ["text", [1, 1, 1, 1]];
        private _font = _theme getOrDefault ["font", "PuristaMedium"];
        // Round as the inspect card's boxes, whatever the theme's own corners (a sharp theme gave ACE's look back - seen in game, 0.6.88).
        private _unit = safezoneH / 40;
        private _radius = (_theme getOrDefault ["radius", 0]) max (_unit * 0.45);
        private _small = _radius * 0.6;
        private _clear = [0, 0, 0, 0];
        private _outline = [1, 1, 1, 0.16];
        // The menu bar's buttons solid, all as Close is (Mia, 0.6.89: "not see-through").
        private _solid = [0.07, 0.07, 0.08, 0.96];

        // [ACE's control, the colour under it, how round, outlined]. In order: what comes later lies over what came before - a tab's
        // lit background over its tile.
        private _specs = [];

        if (_aio) then {
            _specs = [
                [4, _panel, _radius, true], [6, _panel, _radius, true],
                [56, _panel, _radius, true], [55, _tile, _small, false], [1101, _panel, _radius, true], [1104, _panel, _small, false],
                [90010, _panel, _radius, true], [90011, _panel, _radius, true], [9, _panel, _radius, true],
                [7, _panel, _small, true], [8, _panel, _small, true],
                [18, _tile, _small, true], [19, _tile, _small, true],
                [16, _tile, _small, false], [161, _tile, _small, false], [17, _tile, _small, false], [171, _tile, _small, false],
                [1001, _solid, _small, true], [1002, _solid, _small, true], [1003, _solid, _small, true],
                [1004, _solid, _small, true], [1005, _solid, _small, true], [1006, _solid, _small, true],
                [52, _tile, _small, false], [53, _tile, _small, false]
            ];

            // The tabs: a round tile under each button, and over it the lit one in the accent colour, shown as ACE shows its own
            // white square for the open tab (its fade, mirrored each frame).
            private _tabs = [
                2002, 2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018, 2020, 2022, 2024, 2026, 2029, 2031, 2033, 2035, 2037,
                22, 24, 26, 28, 3002, 3004, 30, 32, 34, 36, 38
            ];

            {
                _specs pushBack [_x, _tile, _small, false];
            } forEach _tabs;

            {
                _specs pushBack [_x - 1, _accent + [0.85], _small, false];
            } forEach _tabs;
        };

        private _pairs = [];

        {
            _x params ["_idc", "_colour", "_round", "_lined"];

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

            if (_lined) then {
                _made append ([_display, _group, [0, 0, _w, _h], _outline, _radiusHere] call EFUNC(gui,uiRing));
            };

            _control ctrlSetBackgroundColor _clear;
            _pairs pushBack [_control, [_group], _rect, _made];
        } forEach _specs;

        // The picked row of each list: ACE's own bar is see-through (aio_compat_ace_arsenal), this lies under the row instead - round
        // in the accent colour in this look, ACE's white bar in its own.
        private _pickers = [];

        {
            private _list = _display displayCtrl _x;

            if (isNull _list || {_groups isEqualTo []}) then {continue};

            private _group = _groups deleteAt 0;
            private _rowH = 7 * _gridH;
            private _listW = (ctrlPosition _list) select 2;

            _group ctrlSetPosition [0, 0, _listW, _rowH];
            _group ctrlCommit 0;

            private _made = if (_aio) then {
                [_display, _group, [0, 0, _listW, _rowH], _accent + [0.35], _small min (_rowH / 2)] call EFUNC(gui,uiPanel)
            } else {
                [_display, _group, [0, 0, _listW, _rowH], [1, 1, 1, 0.5], 0] call EFUNC(gui,uiPanel)
            };

            _group ctrlShow false;
            _pickers pushBack [_list, _group, _made, ""];
        } forEach [13, 14, 15];

        if (_aio) then {
            // The lists' frames go; the lists themselves lie on the block's panel, in the theme's words.
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

            // The picked item's facts, as the inventory's hint line says them (fnc_aceInfo): a round card over the menu bar.
            private _bar = _display displayCtrl 10;

            if (!isNull _bar) then {
                ([_bar] call _fnc_screenRect) params ["_barX", "_barY", "_barW"];

                private _cardH = 6 * _gridH;
                private _padX = 2 * _gridH * pixelW / pixelH;
                private _cardRect = [_barX, _barY - _cardH - 2 * _gridH, _barW, _cardH];
                private _card = [_display, controlNull, _cardRect, _solid, _small min (_cardH / 2)] call EFUNC(gui,uiPanel);

                _card append ([_display, controlNull, _cardRect, _outline, _small min (_cardH / 2)] call EFUNC(gui,uiRing));

                private _line = _display ctrlCreate ["AIO_ArsenalInfo", -1];
                _line ctrlSetPosition [(_cardRect select 0) + _padX, (_cardRect select 1) + 1.2 * _gridH, (_cardRect select 2) - 2 * _padX, _cardH - 1.5 * _gridH];
                _line ctrlCommit 0;
                _card pushBack _line;

                {
                    _x ctrlShow false;
                    _x ctrlEnable false;
                } forEach _card;

                // Not the window's: a build of the panel sweeps what it made at the top level (aio_gui_fnc_uiCreate).
                uiNamespace setVariable [QEGVAR(gui,created), (uiNamespace getVariable [QEGVAR(gui,created), []]) - _card];
                uiNamespace setVariable [QGVAR(skinInfo), [_card, _line, "-"]];
            };
        };

        uiNamespace setVariable [QGVAR(skinPairs), _pairs];
        uiNamespace setVariable [QGVAR(skinPickers), _pickers];

        // ACE paints its backgrounds again (on a fill, a tab): what lies on the panels is kept see-through every frame.
        uiNamespace setVariable [QGVAR(skinClear), (_pairs apply {_x select 0}) + ([[], [13, 14, 15] apply {_display displayCtrl _x}] select _aio)];

        GVAR(skinPicked) = "";
        GVAR(skinFrame) = [{["frame"] call FUNC(aceSkin)}, 0] call CBA_fnc_addPerFrameHandler;
    };

    case "frame": {
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
        } forEach (uiNamespace getVariable [QGVAR(skinPairs), []]);

        // The picked rows, wherever the list is scrolled; the newest pick is the item the info card tells of.
        {
            _x params ["_list", "_group", "", "_last"];

            if (isNull _list) then {continue};

            private _row = [_list] call _fnc_pickedRow;

            if (_row isEqualTo []) then {
                _group ctrlShow false;
            } else {
                _group ctrlSetPosition [_row select 0, _row select 1];
                _group ctrlCommit 0;
                _group ctrlShow true;
            };

            private _nbox = ctrlType _list == 102;
            private _picked = [lbCurSel _list, lnbCurSelRow _list] select _nbox;
            private _data = if (_picked < 0) then {""} else {[_list lbData _picked, _list lnbData [_picked, 0]] select _nbox};

            if (_data isNotEqualTo _last) then {
                _x set [3, _data];
                GVAR(skinPicked) = _data;
            };
        } forEach (uiNamespace getVariable [QGVAR(skinPickers), []]);

        private _info = uiNamespace getVariable [QGVAR(skinInfo), []];

        _info params [["_card", []], ["_line", controlNull], ["_shownFor", ""]];

        if (!isNull _line) then {
            private _picked = missionNamespace getVariable [QGVAR(skinPicked), ""];

            if (_picked isNotEqualTo _shownFor) then {
                _info set [2, _picked];

                private _words = [_picked] call FUNC(aceInfo);

                {_x ctrlShow (_words isNotEqualTo "")} forEach _card;
                _line ctrlSetStructuredText parseText _words;
            };
        };
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

        {
            _x params ["", "_group", "_made"];

            {ctrlDelete _x} forEach _made;
            _group ctrlSetPosition [0, 0, 0, 0];
            _group ctrlCommit 0;
        } forEach (uiNamespace getVariable [QGVAR(skinPickers), []]);

        {ctrlDelete _x} forEach ((uiNamespace getVariable [QGVAR(skinInfo), []]) param [0, []]);

        uiNamespace setVariable [QGVAR(skinPairs), []];
        uiNamespace setVariable [QGVAR(skinPickers), []];
        uiNamespace setVariable [QGVAR(skinInfo), []];
        GVAR(skinPicked) = "";
    };
};
