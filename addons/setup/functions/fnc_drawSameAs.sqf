#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The popover of "Same as another class..." in the Containers step (fnc_drawCellEditor opens it with
 * fnc_popover): which class the one in the editor takes its cells from, in two steps.
 *   - Pick: a search field over the class index (fnc_buildIndex), by class and by name, wildcards too
 *     (fnc_searchFilter), every container but the one being edited, eight to a page with the page turned
 *     by the arrows; a click on one picks it. Cancel closes it.
 *   - Then two ways, each said in a line: "Follow X" writes like=X (and takes the class's own grid away,
 *     which would win over it) - the class keeps X's cells, also when X changes, and the editor shows
 *     them without letting them be drawn on. "Copy cells of X" lays X's compartments into the editor as
 *     the class's own working copy, to change and Apply - which then takes a like= away too, so the
 *     cells are its own. Back goes to the list again.
 * What it shows is kept in GVAR(sameAs): "target" (the class edited), "text", "page", "picked" ("" while
 * picking). Typing redraws only the list, so the field keeps the cursor; everything else draws all of it
 * again. Its place comes from uiNamespace QGVAR(sameAsArgs), which the popover sets; nothing is drawn
 * once the popover is closed. While the index is still being read it says how far, and looks again a
 * moment later.
 *
 * Arguments:
 * 0: What to draw: "all", or "list" for the found classes alone <STRING> (default: "all")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["all"] call aio_setup_fnc_drawSameAs;
 *
 * Public: No
 */

disableSerialization;

params [["_part", "all", [""]]];

(uiNamespace getVariable [QGVAR(sameAsArgs), []]) params [["_display", displayNull], ["_inner", controlNull], ["_theme", createHashMap]];

if (isNull _display || {isNull _inner}) exitWith {};

(ctrlPosition _inner) params ["", "", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _radius = (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3);
private _target = GVAR(sameAs) getOrDefault ["target", ""];
private _picked = GVAR(sameAs) getOrDefault ["picked", ""];
private _buttonH = UNIT * 1.15;
private _searchH = UNIT * 1.15;
private _listY = _searchH + UNIT * 0.3;
private _listH = _height - _listY - _buttonH - UNIT * 0.3;

if (_part isEqualTo "all") then {
    ctrlDelete (uiNamespace getVariable [QGVAR(sameAsBox), controlNull]);

    private _box = [_display, "AIO_Group", _inner, [0, 0, _width, _height]] call EFUNC(gui,uiCreate);

    uiNamespace setVariable [QGVAR(sameAsBox), _box];
    uiNamespace setVariable [QGVAR(sameAsList), controlNull];

    // ----- Picked: follow it, or copy its cells -----

    if (_picked isNotEqualTo "") exitWith {
        private _row = ((uiNamespace getVariable [QGVAR(index), createHashMap]) getOrDefault ["byClass", createHashMap]) getOrDefault [toLowerANSI _picked, []];
        private _name = _row param [ROW_NAME, _picked];
        private _cursorY = 0;

        [_display, _box, [0, _cursorY, _width, UNIT * 0.85], [_name, _width, _fontBold, TEXT_HEAD] call EFUNC(gui,fitText), TEXT_HEAD, _colorText, _fontBold, 0] call EFUNC(gui,uiLabel);

        _cursorY = _cursorY + UNIT * 0.85;

        [
            _display, _box, [0, _cursorY, _width, UNIT * 0.65],
            [format ["%1 · %2", _picked, localize format ["STR_aio_setup_Kind_%1", _row param [ROW_KIND, "backpack"]]], _width, _font, TEXT_SMALL] call EFUNC(gui,fitText),
            TEXT_SMALL, _muted, _font, 0
        ] call EFUNC(gui,uiLabel);

        _cursorY = _cursorY + UNIT * 1;

        {
            _x params ["_label", "_help", "_style", "_code"];

            [_display, _box, [0, _cursorY, _width, _buttonH], format [_label, _name], "", _theme, _code, [_target, _picked], true, _style] call FUNC(uiAction);

            _cursorY = _cursorY + _buttonH + UNIT * 0.15;
            _cursorY = _cursorY + ([_display, _box, [0, _cursorY, _width], format [_help, _name], TEXT_SMALL, _colorText2, _font] call FUNC(uiText)) + UNIT * 0.35;
        } forEach [
            [LLSTRING(Same_Follow), LLSTRING(Same_FollowHelp), "accent", {
                params ["_target", "_source"];

                GVAR(cellWork) deleteAt (toLowerANSI _target);

                call FUNC(closePopover);

                // Its own cells would win over the other class's: they go, the rest of its rule stays.
                [format [LLSTRING(Hint_Linked), _target, _source], "text2"] call FUNC(setHint);
                [_target, createHashMapFromArray [["like", _source]], ["grid"]] call FUNC(upsertRule);
            }],
            [LLSTRING(Same_Copy), LLSTRING(Same_CopyHelp), "", {
                params ["_target", "_source"];

                ([_source] call FUNC(classBlocks)) params ["", "_blocks"];

                if (_blocks isEqualTo []) exitWith {
                    [format [LLSTRING(Hint_NothingToCopy), _source], "loss"] call FUNC(setHint);
                };

                private _lc = toLowerANSI _target;
                private _own = ((call FUNC(ownClassRules)) select 0) getOrDefault [_lc, createHashMap];
                private _work = if (GVAR(cellMode) == 1) then {
                    createHashMapFromArray [
                        ["blocks", _blocks apply {[[_x select 0, _x select 1, _x select 2], _x param [4, []], _x param [5, false], _x param [6, false]] call FUNC(cellBlock)}], ["picked", 0]
                    ]
                } else {
                    [_blocks, 1, CANVAS_ROWS_LOADED, STORAGE_COLS, true] call FUNC(canvasFromBlocks)
                };

                // Copied cells are the class's own: Apply takes a like= away with them.
                _work set ["unlink", "like" in _own];
                GVAR(cellWork) set [_lc, _work];
                GVAR(cellPick) deleteAt _lc;

                call FUNC(closePopover);

                [format [LLSTRING(Hint_Copied), _source, _target], "text2"] call FUNC(setHint);
                [] call FUNC(drawCellEditor);
            }]
        ];

        private _halfW = (_width - SQUARE(UNIT * 0.3)) / 2;

        [_display, _box, [0, _height - _buttonH, _halfW, _buttonH], LLSTRING(Back), UI_TEX(icon_chevron_left_ca), _theme, {
            GVAR(sameAs) set ["picked", ""];

            ["all"] call FUNC(drawSameAs);
        }, [], true, "ghost"] call FUNC(uiAction);

        [_display, _box, [_width - _halfW, _height - _buttonH, _halfW, _buttonH], LLSTRING(Cancel), "", _theme, {
            call FUNC(closePopover);
        }, [], true, "ghost"] call FUNC(uiAction);
    };

    // ----- Pick: the search, and Cancel -----

    private _search = [
        _display, _box, [0, 0, _width, _searchH], GVAR(sameAs) getOrDefault ["text", ""], LLSTRING(Items_Search), _theme, {
            params ["_text"];

            if (_text isEqualTo (GVAR(sameAs) getOrDefault ["text", ""])) exitWith {};

            GVAR(sameAs) set ["text", _text];
            GVAR(sameAs) set ["page", 0];

            ["list"] call FUNC(drawSameAs);
        }
    ] call FUNC(uiEdit);

    ctrlSetFocus (_search select (count _search - 1));
};

if (_picked isNotEqualTo "") exitWith {};

private _box = uiNamespace getVariable [QGVAR(sameAsBox), controlNull];

if (isNull _box) exitWith {};

ctrlDelete (uiNamespace getVariable [QGVAR(sameAsList), controlNull]);

private _list = [_display, "AIO_Group", _box, [0, _listY, _width, _listH + _buttonH + UNIT * 0.3]] call EFUNC(gui,uiCreate);

uiNamespace setVariable [QGVAR(sameAsList), _list];

// Cancel lies in the list's group, which takes the footer's whole width: drawn with it, it stays on top.
private _footY = _listH + UNIT * 0.3;
private _cancelW = SQUARE(UNIT * 5);

[_display, _list, [_width - _cancelW, _footY, _cancelW, _buttonH], LLSTRING(Cancel), "", _theme, {
    call FUNC(closePopover);
}, [], true, "ghost"] call FUNC(uiAction);

// ----- Still reading: say how far, and look again a moment later -----

if !(call FUNC(buildIndex)) exitWith {
    private _index = uiNamespace getVariable [QGVAR(index), createHashMap];

    [
        _display, _list, [0, 0, _width, UNIT * 0.8],
        format [LLSTRING(Index_Reading), floor (100 * (_index getOrDefault ["read", 0]) / (_index getOrDefault ["total", 1])) min 99],
        TEXT_SMALL, _colorText2, _font, 0
    ] call EFUNC(gui,uiLabel);

    [{
        params ["_list"];

        if (!isNull _list) then {
            ["list"] call FUNC(drawSameAs);
        };
    }, [_list], 0.5] call FUNC(defer);
};

// ----- What is found, a page of eight -----

private _filter = [GVAR(sameAs) getOrDefault ["text", ""]] call FUNC(searchFilter);
private _self = toLowerANSI _target;
private _matches = ((uiNamespace getVariable QGVAR(index)) get "rows") select {
    (_x select ROW_KIND) in CONTAINER_KINDS
    && {(_x select ROW_LC) isNotEqualTo _self}
    && {[_filter, _x select ROW_SEARCH, _x select ROW_LC, _x select ROW_NAME] call FUNC(searchHit)}
};

private _perPage = 8;
private _total = count _matches;
private _pages = (ceil (_total / _perPage)) max 1;
private _page = ((GVAR(sameAs) getOrDefault ["page", 0]) min (_pages - 1)) max 0;
private _shown = _matches select [_page * _perPage, _perPage];
private _rowH = (_listH - UNIT * 0.2) / _perPage;

GVAR(sameAs) set ["page", _page];

{
    _x params ["", "_class", "", "_name", "_kind"];

    private _rowY = _forEachIndex * _rowH;
    private _surface = [_display, _list, [0, _rowY, _width, _rowH - pixelH * 2], [0, 0, 0, 0], _radius] call EFUNC(gui,uiPanel);
    private _nameW = _width * 0.55;
    private _aboutX = _nameW + SQUARE(UNIT * 0.3);
    private _aboutW = _width - _aboutX - SQUARE(UNIT * 0.2);

    [
        _display, _list, [SQUARE(UNIT * 0.2), _rowY, _nameW - SQUARE(UNIT * 0.2), _rowH],
        [_name, _nameW - SQUARE(UNIT * 0.2), _fontBold, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, _colorText, _fontBold, 0
    ] call EFUNC(gui,uiLabel);

    [
        _display, _list, [_aboutX, _rowY, _aboutW, _rowH],
        [format ["%1 · %2", _class, localize format ["STR_aio_setup_Kind_%1", _kind]], _aboutW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, _muted, _font, 0
    ] call EFUNC(gui,uiLabel);

    [_display, _list, [0, _rowY, _width, _rowH - pixelH * 2], _surface, [0, 0, 0, 0], [1, 1, 1, 0.085], {
        params ["_class"];

        GVAR(sameAs) set ["picked", _class];

        ["all"] call FUNC(drawSameAs);
    }, [_class], true, _class] call FUNC(uiHit);
} forEach _shown;

if (_shown isEqualTo []) then {
    [_display, _list, [SQUARE(UNIT * 0.2), 0, _width, UNIT * 0.8], LLSTRING(List_None), TEXT_SMALL, _muted, _font, 0] call EFUNC(gui,uiLabel);
};

// ----- The page, beside Cancel -----

private _turnW = SQUARE(_buttonH);

[
    _display, _list, [0, _footY, _width - _cancelW - _turnW * 2 - SQUARE(UNIT * 0.6), _buttonH],
    [LLSTRING(List_None), format [LLSTRING(List_Range), _page * _perPage + 1, _page * _perPage + count _shown, _total]] select (_total > 0),
    TEXT_SMALL, _muted, _font, 0
] call EFUNC(gui,uiLabel);

{
    _x params ["_icon", "_step", "_enabled", "_buttonX"];

    [_display, _list, [_buttonX, _footY, _turnW, _buttonH], "", _icon, _theme, {
        params ["_step"];

        GVAR(sameAs) set ["page", ((GVAR(sameAs) getOrDefault ["page", 0]) + _step) max 0];

        ["list"] call FUNC(drawSameAs);
    }, [_step], _enabled, "ghost"] call FUNC(uiAction);
} forEach [
    [UI_TEX(icon_chevron_left_ca), -1, _page > 0, _width - _cancelW - _turnW * 2 - SQUARE(UNIT * 0.4)],
    [UI_TEX(icon_chevron_right_ca), 1, _page < _pages - 1, _width - _cancelW - _turnW - SQUARE(UNIT * 0.3)]
];
