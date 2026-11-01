#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Step 1, General: what holds for everything, top to bottom in one page that scrolls.
 *   - The title, where Save goes (or why it may not, in red), the switch to force it over the mission's own setup
 *     where that is allowed, a line that says these are the very settings of CBA's Addon Options as well, and the
 *     buttons for the setup as a whole: Import, Export (the setup as text, fnc_openExport) and Reset to default.
 *     Under them, only when there are any, what the rules engine left out of the text it read.
 *   - Containers: for each kind - uniforms, vests, backpacks, vehicles, crates - Auto, the size its load gives
 *     (see below), or Fixed, every container of that kind the same size across x down. The rule all kind=uniform >
 *     grid=5x5 of the text (fnc_kindRule, fnc_upsertKinds), which the engine asks after every rule, mod and table
 *     about a class: a class with a rule of its own, or a mod that sets its grid, keeps it.
 *   - How room is worked out: the load per cell (the header's cell=) and, in plain words with the numbers as they
 *     are now, how weight turns into cells for each kind of container, how big an item is and what stacks.
 *   - Categories (fnc_drawCategories): the eight built-in categories - names and pictures can be changed - and the ones the setup
 *     defines itself, which items are put in, compartments accept and the strip at the side of a loot box lists. Add, rename,
 *     pick a picture, delete; the statements category=... of the rules text.
 *   - The server settings, by topic (aio_main_topics): everything of this mod that is the same for everyone, each a
 *     control of its own kind - a switch, a stepper, a drop-down, a text box - with a small reset button while it is
 *     off its default. They are registered by their addons (aio_main_fnc_addSetting), each a CBA setting of its own
 *     as well, and show the values in effect; Save writes each one changed through CBA (fnc_setSetting,
 *     fnc_commitSettings, fnc_save). One the source's cba_settings.sqf sets is greyed, with why in its tooltip.
 *     What a player sets for themselves stays in CBA's menu.
 *   - What you changed: everything above that is off the default, and what the classes change on top of it
 *     (fnc_drawChanges "default") - the cell size, a server setting, the size of a kind of container, a category, a class
 *     that is 5x5 -, each in words, to open at its class or take back.
 * Every change goes into the draft; Save in the footer stores it, and the header's count of changes opens the list
 * of what Save would store.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The step's group <CONTROL>
 * 2: Theme <HASHMAP>
 * 3: Arguments - none <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _group, _theme, []] call aio_setup_fnc_drawGeneral;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_group", "_theme"];

(ctrlPosition _group) params ["", "", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _loss = _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]];

// ----- The page: one column that scrolls, and a throwaway group to measure texts in -----

// Drawn again in the same step (fnc_showStep keeps the content group), the scroll group stays: the controls on it are
// drawn first and the old ones deleted at the end, so the group is never empty and keeps its place (a new one would start at
// the top).
private _page = _group getVariable [QGVAR(page), controlNull];
private _oldControls = [];

if (isNull _page) then {
    _page = [_display, "AIO_ScrollGroup", _group, [0, 0, _width, _height]] call EFUNC(gui,uiCreate);

    _group setVariable [QGVAR(page), _page];
    _page setVariable [QGVAR(scrollId), "general"];
} else {
    _page ctrlSetPosition [0, 0, _width, _height];
    _page ctrlCommit 0;

    _oldControls = (allControls _page) select {ctrlParentControlsGroup _x isEqualTo _page};
};

private _pageW = _width - SCROLL_W - pixelW * 2;
private _probe = [_display, "AIO_Group", _group, [0, 0, _pageW, UNIT * 10]] call EFUNC(gui,uiCreate);

private _padX = WIZ_PAD_X;
private _innerW = _pageW - _padX * 2;
private _cardX = _padX + CARD_PAD_X;
private _cardW = _innerW - CARD_PAD_X * 2;
private _gapY = UNIT * 0.5;
private _rowH = UNIT * 1.2;
private _rowGap = UNIT * 0.35;
private _gap = SQUARE(UNIT * 0.3);
private _cardTop = CARD_PAD_Y + CARD_CAPTION_H + UNIT * 0.15;
private _cursorY = UNIT * 0.4;

// A text as high as it comes out at a width.
private _fnc_height = {
    params ["_text", "_textWidth", ["_size", TEXT_SMALL]];

    [_display, _probe, [0, 0, _textWidth], _text, _size, _colorText2, _font] call FUNC(uiText)
};

// A button whose box opens under it: its code gets the button's rectangle on the screen.
private _fnc_anchored = {
    params ["_rect", "_label", "_icon", "_code", ["_style", ""], ["_tooltip", ""]];

    private _controls = [_display, _page, _rect, _label, _icon, _theme, {}, [], true, _style, _tooltip] call FUNC(uiAction);
    private _hit = _controls select (count _controls - 1);

    _hit setVariable [QGVAR(action), [{
        params ["_hit", "_code"];

        [uiNamespace getVariable [QGVAR(display), displayNull], [_hit] call FUNC(screenRect)] call _code;
    }, [_hit, _code]]];
};

// ----- Title, where Save goes, and the buttons for the setup as a whole -----

private _target = GVAR(target);
private _buttonH = UNIT * 1.15;
private _buttonGap = SQUARE(UNIT * 0.3);
private _minW = SQUARE(UNIT * 3.8);
private _fnc_buttonW = {
    params ["_label", "_hasIcon"];

    ACTION_W(_label,_buttonH,_hasIcon,_font) max _minW
};

private _importW = [LLSTRING(Import), true] call _fnc_buttonW;
private _exportW = [LLSTRING(Export), true] call _fnc_buttonW;
private _resetW = [LLSTRING(Reset), true] call _fnc_buttonW;
private _buttonsW = _importW + _exportW + _resetW + _buttonGap * 2;
private _buttonsX = _padX + _innerW - _buttonsW;
private _titleW = (_buttonsX - _gap) - _padX;

[_display, _page, [_padX, _cursorY, _titleW, UNIT * 1.1], LLSTRING(General_Title), TEXT_HEAD, _colorText, _fontBold, 0] call EFUNC(gui,uiLabel);

private _atDefault = [] call FUNC(atDefault);

[[_buttonsX, _cursorY, _importW, _buttonH], LLSTRING(Import), UI_TEX(icon_import_ca), {
    params ["_display", "_anchor"];

    [_display, _anchor] call FUNC(openImport);
}, "", LLSTRING(Import_Tip)] call _fnc_anchored;

_buttonsX = _buttonsX + _importW + _buttonGap;

[[_buttonsX, _cursorY, _exportW, _buttonH], LLSTRING(Export), UI_TEX(icon_export_ca), {
    params ["_display", "_anchor"];

    [_display, _anchor] call FUNC(openExport);
}, "", LLSTRING(Export_Tip)] call _fnc_anchored;

_buttonsX = _buttonsX + _exportW + _buttonGap;

[_display, _page, [_buttonsX, _cursorY, _resetW, _buttonH], LLSTRING(Reset), ICON(icon_reset_ca,icon_auto_ca), _theme, {
    [uiNamespace getVariable [QGVAR(display), displayNull], LLSTRING(Reset_Confirm), LLSTRING(Reset_Yes), {
        [] call FUNC(resetAll);
        [LLSTRING(Reset_Done), "text2"] call FUNC(setHint);
    }] call FUNC(confirm);
}, [], !_atDefault, "danger", [LLSTRING(Reset_Tip), LLSTRING(Reset_Already)] select _atDefault] call FUNC(uiAction);

_cursorY = _cursorY + UNIT * 1.1;

// Where Save goes - or why it may not: a player who cannot save should know before pressing anything.
private _saveLine = "";
private _saveInk = _colorText2;

if (GVAR(readOnly)) then {
    _saveLine = format [LLSTRING(Save_ReadOnly), _target getOrDefault ["reason", ""]];
    _saveInk = _loss;
} else {
    private _source = _target getOrDefault ["source", ""];

    _saveLine = switch (true) do {
        case (GVAR(mode) isEqualTo "menu"): {format [LLSTRING(Save_ToMenu), localize format ["STR_aio_setup_Source_%1", _source]]};
        case (_source isEqualTo "mission"): {LLSTRING(Save_ToMission)};
        default {LLSTRING(Save_ToServer)};
    };
};

_cursorY = _cursorY + ([_display, _page, [_padX, _cursorY, _innerW], _saveLine, TEXT_SMALL, _saveInk, _font] call FUNC(uiText)) + UNIT * 0.1;

if (GVAR(readOnly)) then {
    _cursorY = _cursorY + ([_display, _page, [_padX, _cursorY, _innerW], LLSTRING(Save_ReadOnlyHelp), TEXT_SMALL, _muted, _font] call FUNC(uiText)) + UNIT * 0.1;
} else {
    if ((_target getOrDefault ["missionWins", false]) && {!GVAR(override)}) then {
        _cursorY = _cursorY + ([_display, _page, [_padX, _cursorY, _innerW], LLSTRING(Save_MissionWins), TEXT_SMALL, _accent, _font] call FUNC(uiText)) + UNIT * 0.1;
    };

    // Forced over the mission's own setup - only where it cannot outlive what it is meant for (fnc_canEdit).
    if (_target getOrDefault ["override", false]) then {
        [_display, _page, [_padX, _cursorY, _innerW, UNIT * 1.05], GVAR(override), _theme, {
            params ["_on"];

            GVAR(override) = _on;

            [GVAR(step)] call FUNC(showStep);
        }, [], true, LLSTRING(Save_Override)] call FUNC(uiToggle);

        _cursorY = _cursorY + UNIT * 1.05 + UNIT * 0.1;
    };
};

// The same settings are rows of CBA's Addon Options: say so, and which place is the better one.
_cursorY = _cursorY + ([
    _display, _page, [_padX, _cursorY, _innerW], format [LLSTRING(General_CbaNote), CBA_SETTINGS_AIO_SERVER], TEXT_SMALL, _muted, _font
] call FUNC(uiText)) + UNIT * 0.1;

_cursorY = _cursorY + _gapY;

// ----- What the engine left out of the text, only when something was -----

private _warnings = (+GVAR(parseWarnings)) + (GVAR(draftRules) getOrDefault ["warnings", []]);
private _length = count GVAR(draftText);

if (_length > TEXT_MAX) then {
    _warnings = [format [LLSTRING(Warning_TooLong), _length]] + _warnings;
};

_warnings = _warnings select {_x isEqualType ""};
_warnings = _warnings arrayIntersect _warnings;

if (_warnings isNotEqualTo []) then {
    private _dotH = UNIT * 0.28;
    private _textX = SQUARE(UNIT * 0.75);
    private _heights = _warnings apply {[_x, _cardW - _textX - SCROLL_W] call _fnc_height};
    private _listH = 0;

    {
        _listH = _listH + _x + UNIT * 0.15;
    } forEach _heights;

    // A few lines; the rest scrolls.
    _listH = _listH min (UNIT * 4.4);

    private _cardH = _cardTop + _listH + CARD_PAD_Y;
    private _contentY = [_display, _page, [_padX, _cursorY, _innerW, _cardH], format [LLSTRING(Review_Warnings), count _warnings], _theme] call FUNC(uiCard);
    private _list = [_display, "AIO_ScrollGroup", _page, [_cardX, _contentY, _cardW + CARD_PAD_X - pixelW * 2, _listH]] call EFUNC(gui,uiCreate);
    private _lineY = 0;

    _list setVariable [QGVAR(scrollId), "generalWarnings"];

    {
        [_display, _list, [SQUARE(UNIT * 0.2), _lineY + UNIT * 0.2, SQUARE(_dotH), _dotH], UI_TEX(circle_ca), _accent] call EFUNC(gui,uiIcon);

        _lineY = _lineY + ([_display, _list, [_textX, _lineY, _cardW - _textX - SCROLL_W], _x, TEXT_SMALL, _colorText2, _font] call FUNC(uiText)) + UNIT * 0.15;
    } forEach _warnings;

    _cursorY = _cursorY + _cardH + _gapY;
};

// ----- Containers: the size of each kind, Auto or fixed -----

private _kindNames = createHashMapFromArray [
    ["uniform", LLSTRING(Kinds_uniform)], ["vest", LLSTRING(Kinds_vest)], ["backpack", LLSTRING(Kinds_backpack)],
    ["vehicle", LLSTRING(Kinds_vehicle)], ["crate", LLSTRING(Kinds_crate)]
];

// What a kind is when switched to Fixed for the first time: something near what Auto gives.
private _kindStart = createHashMapFromArray [
    ["uniform", [UNIFORM_COLS, UNIFORM_ROWS_MIN]], ["vest", [5, 4]], ["backpack", [6, 6]], ["vehicle", [STORAGE_COLS, 10]], ["crate", [STORAGE_COLS, 6]]
];

private _containersHelp = LLSTRING(Containers_Help);
private _containersHelpH = [_containersHelp, _cardW] call _fnc_height;
private _containersH = _cardTop + _containersHelpH + UNIT * 0.3 + (count GENERAL_KINDS) * (_rowH + _rowGap) + CARD_PAD_Y - _rowGap;
private _contentY = [_display, _page, [_padX, _cursorY, _innerW, _containersH], LLSTRING(Containers_Title), _theme] call FUNC(uiCard);

[_display, _page, [_cardX, _contentY, _cardW], _containersHelp, TEXT_SMALL, _colorText2, _font] call FUNC(uiText);

private _rowY = _contentY + _containersHelpH + UNIT * 0.3;
private _labelW = SQUARE(UNIT * 7.5);
private _modeLabels = [LLSTRING(Kinds_Auto), LLSTRING(Kinds_Fixed)];
private _modeW = (selectMax (_modeLabels apply {_x getTextWidth [_fontBold, _rowH * 0.5]})) * TEXT_SLACK / 0.9 * 2 + SQUARE(UNIT * 0.8);
private _numberW = SQUARE(_rowH) * 2 + ("88" getTextWidth [_fontBold, _rowH * 0.52]) * TEXT_SLACK;
private _timesW = SQUARE(UNIT * 0.6);

{
    private _kind = _x;

    ([_kind] call FUNC(kindRule)) params ["_state", "_across", "_down"];

    // The numbers the steppers show: the rule's, else the last ones stepped to, else a start.
    private _numbers = GVAR(kindEdit) getOrDefault [_kind, _kindStart get _kind];

    if (_state isEqualTo "fixed") then {
        _numbers = [_across, _down];
        GVAR(kindEdit) set [_kind, _numbers];
    };

    _numbers params ["_editAcross", "_editDown"];

    private _fixed = _state isEqualTo "fixed";
    private _rowX = _cardX;

    [_display, _page, [_rowX, _rowY, _labelW, _rowH], _kindNames get _kind, TEXT_BODY, _colorText, _fontBold, 0] call EFUNC(gui,uiLabel);
    _rowX = _rowX + _labelW + _gap;

    // Auto or Fixed. A rule that is neither (a pattern typed at the text) leaves both open: either replaces it.
    // Fixed takes the size the steppers show.
    [_display, _page, [_rowX, _rowY, _modeW, _rowH], _modeLabels, ["auto", "fixed"] find _state, _theme, {
        params ["_index", "_arguments"];

        _arguments params ["_kind", "_numbers"];

        if (_index == 0) then {
            [[[_kind, createHashMap, ["grid"]]]] call FUNC(upsertKinds);
        } else {
            [[[_kind, createHashMapFromArray [["grid", format ["%1x%2", _numbers select 0, _numbers select 1]]], []]]] call FUNC(upsertKinds);
        };
    }, [_kind, _numbers]] call FUNC(uiSegmented);
    _rowX = _rowX + _modeW + _gap;

    // The size of a fixed one: greyed while it goes by load.
    private _fnc_step = {
        params ["_value", "_arguments"];

        _arguments params ["_kind", "_slot"];

        private _numbers = +(GVAR(kindEdit) getOrDefault [_kind, [UNIFORM_COLS, UNIFORM_ROWS_MIN]]);

        _numbers set [_slot, _value];
        GVAR(kindEdit) set [_kind, _numbers];

        [[[_kind, createHashMapFromArray [["grid", format ["%1x%2", _numbers select 0, _numbers select 1]]], []]]] call FUNC(upsertKinds);
    };

    [_display, _page, [_rowX, _rowY, _numberW, _rowH], _editAcross, [1, STORAGE_COLS, 1], _theme, _fnc_step, [_kind, 0], "%1", _fixed] call FUNC(uiStepper);
    [_display, _page, [_rowX + _numberW, _rowY, _timesW, _rowH], "×", TEXT_BODY, [DISABLED_INK, _colorText2] select _fixed, _font, 2] call EFUNC(gui,uiLabel);
    [_display, _page, [_rowX + _numberW + _timesW, _rowY, _numberW, _rowH], _editDown, [1, MAX_ROWS, 1], _theme, _fnc_step, [_kind, 1], "%1", _fixed] call FUNC(uiStepper);
    _rowX = _rowX + _numberW * 2 + _timesW + _gap;

    // Back to Auto, only while there is a rule.
    if (_state isNotEqualTo "auto") then {
        [_display, _page, [_rowX, _rowY, _rowH, _rowH], _theme, {
            params ["_kind"];

            [[[_kind, createHashMap, ["grid"]]]] call FUNC(upsertKinds);
        }, [_kind]] call FUNC(uiReset);
    };

    _rowX = _rowX + _rowH + _gap * 2;

    // What the kind gets: by its load, in a few words - or the rule that is there, if it is none of the two.
    private _noteW = _cardX + _cardW - _rowX;
    private _note = switch (_state) do {
        case "other": {
            private _rules = GVAR(draft) getOrDefault ["rules", []];
            private _index = [_rules, [_kind]] call FUNC(allRule);

            format [LLSTRING(Kind_Other), (((_rules select _index) select 1) getOrDefault ["grid", ""])]
        };
        case "fixed": {LLSTRING(Kind_Fixed)};
        default {localize format ["STR_aio_setup_Kind_Auto_%1", _kind]};
    };

    if (_noteW > UNIT * 3) then {
        [
            _display, _page, [_rowX, _rowY, _noteW, _rowH], [_note, _noteW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL,
            [_muted, _accent] select (_state isEqualTo "other"), _font, 0
        ] call EFUNC(gui,uiLabel);
    };

    _rowY = _rowY + _rowH + _rowGap;
} forEach GENERAL_KINDS;

_cursorY = _cursorY + _containersH + _gapY;

// ----- How room is worked out: the load per cell, and what that makes of everything -----

private _cell = GVAR(draftRules) getOrDefault ["cell", 5];
private _cellKg = (_cell * MASS_TO_KG) toFixed 2;
private _ownCell = (GVAR(draft) getOrDefault ["cell", -1]) > 0;

// What the rules make of the examples: a load, divided and rounded up, a fifth more for what is worn.
private _fnc_worn = {
    params ["_load"];

    ceil (_load * 1.2 / _cell)
};

private _packCells = [280] call _fnc_worn;
private _packCols = (ceil sqrt _packCells) min STORAGE_COLS;
private _crateCells = ceil (1000 / _cell);

private _paragraphs = [
    [LLSTRING(Explain_Containers_Label), format [LLSTRING(Explain_Containers), _cell, _cellKg, [120] call _fnc_worn, _packCells]],
    [LLSTRING(Explain_Uniforms_Label), format [LLSTRING(Explain_Uniforms), UNIFORM_COLS, UNIFORM_ROWS_MIN, UNIFORM_ROWS_MAX]],
    [LLSTRING(Explain_Vests_Label), format [LLSTRING(Explain_Vests), VEST_POUCHES_MAX]],
    [LLSTRING(Explain_Backpacks_Label), format [LLSTRING(Explain_Backpacks), STORAGE_COLS, _packCells, _packCols, ceil (_packCells / _packCols)]],
    [LLSTRING(Explain_Cargo_Label), format [LLSTRING(Explain_Cargo), STORAGE_COLS, _crateCells]],
    [LLSTRING(Explain_Items_Label), LLSTRING(Explain_Items)],
    [LLSTRING(Explain_Stacks_Label), LLSTRING(Explain_Stacks)],
    [LLSTRING(Explain_Rules_Label), LLSTRING(Explain_Rules)]
];

private _paragraphLabelW = SQUARE(UNIT * 7.5);
private _paragraphW = _cardW - _paragraphLabelW - _gap;
private _paragraphHeights = _paragraphs apply {[_x select 1, _paragraphW, TEXT_BODY] call _fnc_height};
private _roomH = _cardTop + _rowH + UNIT * 0.35 - UNIT * 0.1 + CARD_PAD_Y;

{
    _roomH = _roomH + _x + UNIT * 0.35;
} forEach _paragraphHeights;

_contentY = [_display, _page, [_padX, _cursorY, _innerW, _roomH], LLSTRING(Room_Title), _theme] call FUNC(uiCard);

// The load per cell, the one number behind the rest.
private _cellLabel = LLSTRING(Room_Cell);

[_display, _page, [_cardX, _contentY, _paragraphLabelW, _rowH], _cellLabel, TEXT_BODY, _colorText, _fontBold, 0] call EFUNC(gui,uiLabel);

private _stepperW = SQUARE(UNIT * 6);
private _cellX = _cardX + _paragraphLabelW + _gap;

[_display, _page, [_cellX, _contentY, _stepperW, _rowH], _cell, [1, 50, 1, 5], _theme, {
    params ["_value"];

    private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);

    _ast set ["cell", _value];

    [_ast] call FUNC(commit);
}, [], "%1"] call FUNC(uiStepper);

private _cellText = format ["%1 · %2", format [LLSTRING(Cell_Value), _cellKg], [LLSTRING(Cell_Default), LLSTRING(Cell_Own)] select _ownCell];

[
    _display, _page, [_cellX + _stepperW + _gap * 2, _contentY, _cardX + _cardW - (_cellX + _stepperW + _gap * 2) - _rowH - _gap, _rowH],
    _cellText, TEXT_BODY, _colorText, _font, 0
] call EFUNC(gui,uiLabel);

if (_ownCell) then {
    [_display, _page, [_cardX + _cardW - _rowH, _contentY, _rowH, _rowH], _theme, {
        private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);

        _ast set ["cell", -1];

        [_ast] call FUNC(commit);
    }, [], LLSTRING(Cell_ResetTip)] call FUNC(uiReset);
};

private _paragraphY = _contentY + _rowH + UNIT * 0.35 - UNIT * 0.1;

{
    _x params ["_label", "_text"];

    [_display, _page, [_cardX, _paragraphY, _paragraphLabelW, UNIT * 0.9], _label, TEXT_BODY, _colorText, _fontBold, 0] call EFUNC(gui,uiLabel);
    [_display, _page, [_cardX + _paragraphLabelW + _gap, _paragraphY, _paragraphW], _text, TEXT_BODY, _colorText2, _font] call FUNC(uiText);

    _paragraphY = _paragraphY + (_paragraphHeights select _forEachIndex) + UNIT * 0.35;
} forEach _paragraphs;

_cursorY = _cursorY + _roomH + _gapY;

// ----- Categories: the names and pictures of the categories, and the setup's own -----

_cursorY = _cursorY + ([_display, _page, [_padX, _cursorY, _innerW], _theme, _probe] call FUNC(drawCategories)) + _gapY;

// ----- The server settings, by topic -----

private _registry = missionNamespace getVariable [QEGVAR(main,serverSettings), createHashMap];

// What is registered and has a control, in the order the addons registered it.
private _shown = (missionNamespace getVariable [QEGVAR(main,serverOrder), []]) select {!((_registry get _x) get "hidden")};

// The topics in their order; what is registered but named in none of them goes under "Other".
private _topics = [];
private _named = [];

{
    _x params ["_id", "", "_names"];

    private _inTopic = _names select {_x in _shown};

    _named append _names;

    if (_inTopic isNotEqualTo []) then {
        _topics pushBack [_id, _inTopic];
    };
} forEach (missionNamespace getVariable [QEGVAR(main,topics), []]);

private _others = _shown select {!(_x in _named)};

if (_others isNotEqualTo []) then {
    _topics pushBack ["other", _others];
};

private _columnGap = SQUARE(UNIT * 1.2);
private _columnW = (_cardW - _columnGap) / 2;

// A setting the source's cba_settings.sqf sets is greyed: a change here would be lost at the next restart, and Save
// leaves it out (fnc_canEdit).
private _lockedSettings = _target getOrDefault ["lockedSettings", []];
private _lockedWhy = [LLSTRING(Setting_LockedServer), LLSTRING(Setting_LockedMission)] select ((_target getOrDefault ["source", ""]) isEqualTo "mission");

// One setting's row: its label (the tooltip is its description), its control by its kind, and its reset button
// while it is off its default - all in the room of _w, a column or a whole line. Its control starts where a
// column's does (_column), so a text box that takes the whole line lines up with the controls above and below it.
private _fnc_setting = {
    params ["_name", "_left", "_y", "_w", ["_column", -1]];

    private _entry = _registry get _name;
    private _type = _entry get "type";
    private _default = _entry get "default";
    private _isOff = _name in GVAR(draftSettings);
    private _locked = _name in _lockedSettings;
    private _value = GVAR(draftSettings) getOrDefault [_name, _default];
    private _tip = _entry get "tip";
    private _labelW = ([_column, _w] select (_column < 0)) * 0.46;
    private _controlX = _left + _labelW + _gap;
    private _controlW = _w - _labelW - _gap - _rowH - _gap;

    if (_locked) then {
        _tip = _lockedWhy + toString [10, 10] + _tip;
    };

    private _label = [
        _display, _page, [_left, _y, _labelW, _rowH], [_entry get "label", _labelW, _font, TEXT_BODY] call EFUNC(gui,fitText), TEXT_BODY,
        [[_colorText2, _accent] select _isOff, _muted] select _locked, _font, 0
    ] call EFUNC(gui,uiLabel);

    _label ctrlSetTooltip ((_entry get "label") + toString [10, 10] + _tip);

    switch (_type) do {
        case "CHECKBOX": {
            private _controls = [_display, _page, [_controlX, _y, _controlW min (UNIT * 5), _rowH], _value, _theme, {
                params ["_on", "_name"];

                [_name, _on] call FUNC(setSetting);
            }, _name, !_locked, ""] call FUNC(uiToggle);

            (_controls select (count _controls - 1)) ctrlSetTooltip _tip;
        };
        case "SLIDER": {
            private _min = _entry get "min";
            private _max = _entry get "max";
            private _decimals = (_entry getOrDefault ["decimals", 0]) max 0;
            private _span = _max - _min;

            // The step a click takes: whole numbers, unless the range is short and the setting has decimals.
            private _step = switch (true) do {
                case (_decimals == 0 || {_span >= 10 && {_decimals < 2}}): {1};
                case (_decimals == 1): {0.5};
                case (_span > 5): {1};
                default {0.05};
            };

            [
                _display, _page, [_controlX, _y, _controlW min SQUARE(UNIT * 8), _rowH], _value, [_min, _max, _step, _step * ([5, 10] select (_span >= 50))], _theme, {
                    params ["_new", "_arguments"];

                    _arguments params ["_name", "_decimals"];

                    private _factor = 10 ^ _decimals;

                    [_name, (round (_new * _factor)) / _factor] call FUNC(setSetting);
                }, [_name, _decimals], "%1", !_locked, _tip
            ] call FUNC(uiStepper);
        };
        case "LIST": {
            private _labels = _entry get "labels";
            private _choices = [];

            {
                _choices pushBack [_labels param [_forEachIndex, str _x], _x];
            } forEach (_entry get "values");

            [_display, _page, [_controlX, _y, _controlW, _rowH], _choices, _value, _theme, {
                params ["_new", "_name"];

                [_name, _new] call FUNC(setSetting);
            }, _name, !_locked] call FUNC(uiDropdown);
        };
        default {
            // A text field has no greyed look: a locked one shows its text instead.
            if (_locked) then {
                private _valueLabel = [_display, _page, [_controlX, _y, _controlW, _rowH], [_value, _controlW, _font, TEXT_BODY] call EFUNC(gui,fitText), TEXT_BODY, _muted, _font, 0] call EFUNC(gui,uiLabel);

                _valueLabel ctrlSetTooltip _tip;
            } else {
                [_display, _page, [_controlX, _y, _controlW, _rowH], _value, "", _theme, {
                    params ["_new", "_name"];

                    [_name, _new] call FUNC(setSetting);
                }, _name, _tip] call FUNC(uiField);
            };
        };
    };

    if (_isOff && {!_locked}) then {
        [_display, _page, [_left + _w - _rowH, _y, _rowH, _rowH], _theme, {
            params ["_name"];

            [_name] call FUNC(setSetting);
        }, [_name]] call FUNC(uiReset);
    };
};

{
    _x params ["_topic", "_names"];

    // Two to a line, a text box a line to itself.
    private _lines = [];
    private _open = [];

    {
        if (((_registry get _x) get "type") isEqualTo "EDITBOX") then {
            if (_open isNotEqualTo []) then {
                _lines pushBack _open;
                _open = [];
            };

            _lines pushBack [_x];
        } else {
            _open pushBack _x;

            if (count _open == 2) then {
                _lines pushBack _open;
                _open = [];
            };
        };
    } forEach _names;

    if (_open isNotEqualTo []) then {
        _lines pushBack _open;
    };

    private _topicH = _cardTop + (count _lines) * (_rowH + _rowGap) + CARD_PAD_Y - _rowGap;

    _contentY = [_display, _page, [_padX, _cursorY, _innerW, _topicH], localize format ["STR_aio_setup_Topic_%1", _topic], _theme] call FUNC(uiCard);

    {
        private _lineY = _contentY + _forEachIndex * (_rowH + _rowGap);

        // A text box takes the whole line, the others a column each.
        if (count _x == 1 && {((_registry get (_x select 0)) get "type") isEqualTo "EDITBOX"}) then {
            [_x select 0, _cardX, _lineY, _cardW, _columnW] call _fnc_setting;
        } else {
            [_x select 0, _cardX, _lineY, _columnW] call _fnc_setting;

            if (count _x > 1) then {
                [_x select 1, _cardX + _columnW + _columnGap, _lineY, _columnW] call _fnc_setting;
            };
        };
    } forEach _lines;

    _cursorY = _cursorY + _topicH + _gapY;
} forEach _topics;

// ----- What you changed: everything off the default, this page's settings and the classes' own rules -----

[_display, _page, [_padX, _cursorY, _innerW, UNIT * 11], _theme, "default"] call FUNC(drawChanges);

_cursorY = _cursorY + UNIT * 11 + UNIT * 0.6;

// The end of the page: the scroll group is as long as its last control. Its length is kept on the group, for where it
// is scrolled to be put back after a redraw (fnc_restoreScroll) and for a box that opens at a control on it
// (fnc_screenRect).
[_display, "AIO_Hitbox", _page, [0, _cursorY, pixelW, pixelH]] call EFUNC(gui,uiCreate);

_page setVariable [QGVAR(contentH), _cursorY + pixelH];

ctrlDelete _probe;

// The page as it was goes now that the new one stands on it: the scroll group never lay empty, so it kept its place
// (fnc_showStep). Text areas that were on it are gone with it.
{ctrlDelete _x} forEach _oldControls;

uiNamespace setVariable [QGVAR(editAreas), (uiNamespace getVariable [QGVAR(editAreas), []]) select {!isNull _x}];
