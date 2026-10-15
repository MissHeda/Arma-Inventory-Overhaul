#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Step 1, Start: one plain page of what the setup builds on, top to bottom.
 *   - The title and two sentences: pick a preset; Items and Containers change single classes; Review
 *     saves it.
 *   - The presets as cards - Default, Realism, Weight and any that another mod brings - each with its
 *     description; the one the draft builds on is picked. Picking another keeps the own rules on top of
 *     it, or starts without them, as the switch under the cards says.
 *   - What is in use now, set by whom, and where this wizard may save - or why it may not -, with Import
 *     and the way on to Review; beside it what you changed against the Default preset - the preset, the
 *     cell size, every own rule -, each in words, to open or take back (fnc_drawChanges, the same list
 *     Review shows against what is saved).
 *   - Everything else: the size and stack of items no rule answers, and the grid of uniforms, vests and
 *     backpacks no rule answers - the text's rules with "all", which the engine asks after the preset and
 *     before its built-in answer, so they fill only the gaps (einv_items_fnc_resolve). Stepped here, written
 *     with Apply and taken out with Clear (fnc_upsertAll); what was stepped and not applied yet is kept
 *     while the draft stays the same (GVAR(elseEdit)).
 *   - At the bottom, folded away (GVAR(startAdvanced)): the cell size, how much load one cell stands for.
 *     It sizes every container no rule draws, by its load, and every item the Weight preset sizes by
 *     mass - the one number that changes the most at once, which few need to touch.
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
 * [_display, _group, _theme, []] call einv_setup_fnc_drawStart;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_group", "_theme"];

(ctrlPosition _group) params ["", "", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.698, 0.734, 0.784, 1]];
private _muted = _theme getOrDefault ["muted", [0.522, 0.553, 0.604, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _radius = _theme getOrDefault ["radius", 0];

private _padX = WIZ_PAD_X;
private _innerW = _width - _padX * 2;
private _gapY = UNIT * 0.5;
private _gapX = SQUARE(_gapY);
private _cursorY = UNIT * 0.4;

// ----- Title, and what to do -----

[_display, _group, [_padX, _cursorY, _innerW, UNIT * 1.1], LLSTRING(Start_Title), TEXT_HEAD, _colorText, _fontBold, 0] call EFUNC(gui,uiLabel);

_cursorY = _cursorY + UNIT * 1.1;
_cursorY = _cursorY + ([_display, _group, [_padX, _cursorY, _innerW], LLSTRING(Start_Help), TEXT_BODY, _colorText2, _font] call FUNC(uiText)) + _gapY;

// ----- The presets -----

private _presets = call FUNC(shippedPresets);
private _base = toLower (GVAR(draft) getOrDefault ["base", "default"]);

if (_presets isEqualTo []) then {
    _cursorY = _cursorY + ([_display, _group, [_padX, _cursorY, _innerW], LLSTRING(Start_NoPresets), TEXT_BODY, _theme getOrDefault ["loss", _colorText2], _font] call FUNC(uiText)) + _gapY;
} else {
    private _columns = ((count _presets) min 4) max 1;
    private _cardW = (_innerW - _gapX * (_columns - 1)) / _columns;
    private _cardH = UNIT * 6.8;
    private _cardFill = _theme getOrDefault ["card", [1, 1, 1, 0.055]];

    {
        _x params ["_id", "_name", "_description", "_revision"];

        private _left = _padX + (_forEachIndex mod _columns) * (_cardW + _gapX);
        private _top = _cursorY + floor (_forEachIndex / _columns) * (_cardH + _gapY);
        private _picked = _id isEqualTo _base;
        private _fill = [_cardFill, _theme getOrDefault ["accentSoft", [0.84, 0.54, 0.1, 0.2]]] select _picked;
        private _surface = [_display, _group, [_left, _top, _cardW, _cardH], _fill, _radius] call EFUNC(gui,uiPanel);
        private _textX = _left + CARD_PAD_X;
        private _textW = _cardW - CARD_PAD_X * 2;

        if (_picked) then {
            [_display, _group, [_left, _top, _cardW, _cardH], _accent, _radius] call EFUNC(gui,uiRing);
        };

        // The name, and on the right of it whether the draft builds on it.
        private _tagW = [0, (LLSTRING(Start_Picked) getTextWidth [_fontBold, TEXT_SMALL]) * TEXT_SLACK] select _picked;

        [
            _display, _group, [_textX, _top + CARD_PAD_Y, _textW - _tagW, UNIT * 1.1],
            [_name, _textW - _tagW, _fontBold, TEXT_HEAD] call EFUNC(gui,fitText), TEXT_HEAD, _colorText, _fontBold, 0
        ] call EFUNC(gui,uiLabel);

        if (_picked) then {
            [_display, _group, [_textX, _top + CARD_PAD_Y, _textW, UNIT * 1.1], LLSTRING(Start_Picked), TEXT_SMALL, _accent, _fontBold, 1] call EFUNC(gui,uiLabel);
        };

        private _descriptionY = _top + CARD_PAD_Y + UNIT * 1.25;
        private _descriptionCtrl = [_display, "EINV_StructuredText", _group, [_textX, _descriptionY, _textW, _top + _cardH - UNIT * 1.3 - _descriptionY]] call EFUNC(gui,uiCreate);

        _descriptionCtrl ctrlSetStructuredText parseText format [
            "<t font='%1' color='%2' size='%3'>%4</t>",
            _font, [_colorText2] call FUNC(hex), TEXT_SMALL / STRUCTURED_SIZE, [_description] call FUNC(escape)
        ];

        [
            _display, _group, [_textX, _top + _cardH - UNIT * 1.2, _textW, UNIT * 0.8],
            format [LLSTRING(Start_Revision), _revision], TEXT_SMALL * 0.95, _muted, _font, 0
        ] call EFUNC(gui,uiLabel);

        // The whole card is the button. The one picked does nothing.
        [_display, _group, [_left, _top, _cardW, _cardH], _surface, _fill, [1, 1, 1, 0.085], {
            params ["_id"];

            private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
            _ast set ["base", _id];

            if (!GVAR(keepOwn)) then {
                _ast set ["groups", []];
                _ast set ["rules", []];
                _ast set ["cell", -1];
            };

            [_ast] call FUNC(commit);
            [format [LLSTRING(Hint_PresetPicked), [_id] call FUNC(presetName)], "text2"] call FUNC(setHint);
        }, [_id], !_picked] call FUNC(uiHit);
    } forEach _presets;

    _cursorY = _cursorY + ceil ((count _presets) / _columns) * (_cardH + _gapY);
};

// Keep the own rules when picking another preset.
private _own = count (GVAR(draft) getOrDefault ["groups", []]) + count (GVAR(draft) getOrDefault ["rules", []]);

[
    _display, _group, [_padX, _cursorY, _innerW, UNIT * 1.1], GVAR(keepOwn), _theme, {
        params ["_on"];

        GVAR(keepOwn) = _on;
    }, [], true, format [LLSTRING(Start_KeepOwn), _own]
] call FUNC(uiToggle);

_cursorY = _cursorY + UNIT * 1.1 + _gapY;

// ----- Advanced, folded at the bottom: how big it is decides how tall the cards above it are -----

private _cell = GVAR(draftRules) getOrDefault ["cell", 5];
private _ownCell = (GVAR(draft) getOrDefault ["cell", -1]) > 0;
private _foldH = UNIT * 1.1;
private _cellHelpH = 0;
private _bottom = _height - UNIT * 0.5;

if (GVAR(startAdvanced)) then {
    // Measured first, in a group thrown away again, so the cards above know how much room is left.
    private _probe = [_display, "EINV_Group", _group, [0, 0, _innerW, UNIT * 10]] call EFUNC(gui,uiCreate);

    _cellHelpH = [_display, _probe, [0, 0, _innerW - CARD_PAD_X * 2], LLSTRING(Cell_Help), TEXT_SMALL, _colorText2, _font] call FUNC(uiText);

    ctrlDelete _probe;
};

private _advancedH = [_foldH, _foldH + UNIT * 1.2 + UNIT * 0.3 + _cellHelpH + CARD_PAD_Y] select GVAR(startAdvanced);
private _advancedY = _bottom - _advancedH;

// ----- Everything else, over Advanced: measured first, as Advanced is -----

// What its steppers show: the draft's two rules for everything else (fnc_allRule), read again whenever the
// draft changed - an Apply, an undo, a preset picked -, else what was stepped to and not applied yet,
// [draft text read from, across, down, stack, fixed grid, grid across, grid down]. Without a rule 1x1 and
// 10 per tile, a grid by load. A size or grid the card cannot step - a shape, a pattern typed at Review -
// shows as that default, and only an Apply replaces it.
private _rules = GVAR(draft) getOrDefault ["rules", []];
private _itemIndex = [_rules] call FUNC(allRule);
private _boxIndex = [_rules, ELSE_CONTAINER_KINDS] call FUNC(allRule);

if (GVAR(elseEdit) isEqualTo [] || {(GVAR(elseEdit) select 0) isNotEqualTo GVAR(draftText)}) then {
    private _itemValues = if (_itemIndex < 0) then {createHashMap} else {(_rules select _itemIndex) select 1};
    private _boxValues = if (_boxIndex < 0) then {createHashMap} else {(_rules select _boxIndex) select 1};
    private _size = toLower (_itemValues getOrDefault ["footprint", ""]);
    private _grid = toLower (_boxValues getOrDefault ["grid", ""]);
    private _fixed = _grid regexMatch "^[0-9]+x[0-9]+$";
    private _sizeParts = [[1, 1], (_size splitString "x") apply {parseNumber _x}] select (_size regexMatch "^[0-9]+x[0-9]+$");
    private _gridParts = [[6, 4], (_grid splitString "x") apply {parseNumber _x}] select _fixed;

    GVAR(elseEdit) = [
        GVAR(draftText),
        ((_sizeParts select 0) max 1) min SHAPE_MAX, ((_sizeParts select 1) max 1) min SHAPE_MAX,
        ((_itemValues getOrDefault ["stack", 10]) max 1) min EDIT_STACK_MAX,
        _fixed,
        ((_gridParts select 0) max 1) min STORAGE_COLS, ((_gridParts select 1) max 1) min MAX_ROWS
    ];
};

// One row - the items, then the containers - where the step is wide enough, else one for each. The sizes
// are bare numbers with a × between them; the stack says "per tile" in its stepper.
private _elseX = _padX + CARD_PAD_X;
private _elseW = _innerW - CARD_PAD_X * 2;
private _elseHeadH = UNIT * 1.1;
private _elseRowH = UNIT * 1.2;
private _elseGap = SQUARE(UNIT * 0.3);
private _elseSplit = SQUARE(UNIT * 1);
private _numberW = SQUARE(_elseRowH) * 2 + ("88" getTextWidth [_fontBold, _elseRowH * 0.52]) * TEXT_SLACK;
private _timesW = SQUARE(UNIT * 0.6);
private _stackW = SQUARE(_elseRowH) * 2 + ((format [LLSTRING(Value_Stack), 888]) getTextWidth [_fontBold, _elseRowH * 0.52]) * TEXT_SLACK;
private _modeLabels = [LLSTRING(Else_Auto), LLSTRING(Else_Fixed)];
private _modeW = (selectMax (_modeLabels apply {_x getTextWidth [_fontBold, _elseRowH * 0.5]})) * TEXT_SLACK / 0.9 * 2 + SQUARE(UNIT * 0.8);
private _itemsLabel = LLSTRING(Else_Items);
private _boxesLabel = LLSTRING(Else_Containers);
private _itemsLabelW = (_itemsLabel getTextWidth [_font, TEXT_BODY]) * TEXT_SLACK;
private _boxesLabelW = (_boxesLabel getTextWidth [_font, TEXT_BODY]) * TEXT_SLACK;
private _itemsW = _itemsLabelW + _elseGap + _numberW * 2 + _timesW + _elseGap + _stackW;
private _boxesW = _boxesLabelW + _elseGap + _modeW + _elseGap + _numberW * 2 + _timesW;
private _elseRows = [2, 1] select (_itemsW + _elseSplit + _boxesW <= _elseW);
private _elseH = CARD_PAD_Y + _elseHeadH + UNIT * 0.15 + _elseRowH * _elseRows + UNIT * 0.25 * (_elseRows - 1) + CARD_PAD_Y;
private _elseY = _advancedY - _gapY - _elseH;

// ----- Now in use | What you changed -----

private _cardsH = (_elseY - _gapY) - _cursorY;
private _columnW = (_innerW - _gapX) * 0.4;
private _changesX = _padX + _columnW + _gapX;

private _statusY = [_display, _group, [_padX, _cursorY, _columnW, _cardsH], LLSTRING(Status_Title), _theme] call FUNC(uiCard);
private _statusX = _padX + CARD_PAD_X;
private _statusW = _columnW - CARD_PAD_X * 2;

// What the game uses now - not the draft - and who set it.
private _inUse = missionNamespace getVariable [RULES_SETTING, RULES_DEFAULT];

if !(_inUse isEqualType "") then {
    _inUse = RULES_DEFAULT;
};

private _inUseAst = [_inUse] call EFUNC(items,parseRules);
private _inUseOwn = count (_inUseAst getOrDefault ["groups", []]) + count (_inUseAst getOrDefault ["rules", []]);
private _from = LLSTRING(Status_Default);

if (!isNil "cba_settings_fnc_priority") then {
    private _source = [RULES_SETTING] call cba_settings_fnc_priority;
    private _namespace = missionNamespace getVariable [format ["cba_settings_%1", _source], objNull];

    if (!isNil {_namespace getVariable RULES_SETTING}) then {
        private _priority = [RULES_SETTING, _source] call cba_settings_fnc_priority;

        _from = format [
            "%1, %2", localize format ["STR_einv_setup_Source_%1", _source],
            [LLSTRING(Chip_Forced), LLSTRING(Chip_Override)] select (_priority isEqualTo 2)
        ];
    };
};

private _lines = [
    [format [LLSTRING(Status_Active), [_inUseAst getOrDefault ["base", "default"]] call FUNC(presetName), _inUseOwn], _colorText],
    [format [LLSTRING(Status_From), _from], _colorText2]
];

private _target = GVAR(target);

if (GVAR(readOnly)) then {
    _lines pushBack [format [LLSTRING(Status_ReadOnly), _target getOrDefault ["reason", ""]], _theme getOrDefault ["loss", _colorText2]];
} else {
    private _where = localize format ["STR_einv_setup_Source_%1", _target getOrDefault ["source", ""]];

    if (GVAR(mode) isEqualTo "menu") then {
        _where = format [LLSTRING(Chip_Menu), _where];
    };

    _lines pushBack [format [LLSTRING(Status_SaveTo), _where], _colorText2];

    if ((_target getOrDefault ["source", ""]) isEqualTo "mission" && {GVAR(mode) isEqualTo "direct"}) then {
        _lines pushBack [LLSTRING(Status_Eden), _muted];
    };

    if (_target getOrDefault ["missionWins", false]) then {
        _lines pushBack [LLSTRING(Save_MissionWins), _accent];
    };
};

{
    _x params ["_text", "_color"];

    _statusY = _statusY + ([_display, _group, [_statusX, _statusY, _statusW], _text, TEXT_BODY, _color, _font] call FUNC(uiText)) + UNIT * 0.25;
} forEach _lines;

// Import, and on to Review where it is saved.
private _buttonH = UNIT * 1.2;
private _buttonY = _cursorY + _cardsH - CARD_PAD_Y - _buttonH;
private _buttonW = (_statusW - SQUARE(UNIT * 0.3)) / 2;

private _import = [_display, _group, [_statusX, _buttonY, _buttonW, _buttonH], LLSTRING(Import), "", _theme, {}] call FUNC(uiAction);
private _importHit = _import select (count _import - 1);

_importHit setVariable [QGVAR(action), [{
    params ["_hit"];

    [uiNamespace getVariable [QGVAR(display), displayNull], [_hit] call FUNC(screenRect)] call FUNC(openImport);
}, [_importHit]]];

[_display, _group, [_statusX + _statusW - _buttonW, _buttonY, _buttonW, _buttonH], LLSTRING(Start_ToReview), "", _theme, {
    [GVAR(steps) findIf {(_x select 0) isEqualTo "review"}] call FUNC(showStep);
}, [], true, "accent"] call FUNC(uiAction);

// What you changed, against the Default preset
[_display, _group, [_changesX, _cursorY, _innerW - (_changesX - _padX), _cardsH], _theme, "default"] call FUNC(drawChanges);

// ----- Everything else -----

[_display, _group, [_padX, _elseY, _innerW, _elseH], _theme getOrDefault ["card", [1, 1, 1, 0.055]], _radius] call EFUNC(gui,uiPanel);

// The caption, what it does in one line, Clear and Apply on the right.
private _elseHeadY = _elseY + CARD_PAD_Y;
private _elseTitle = LLSTRING(Else_Title);
private _elseTitleW = (_elseTitle getTextWidth [_fontBold, TEXT_HEAD]) * TEXT_SLACK;
private _applyText = LLSTRING(Else_Apply);
private _clearText = LLSTRING(Else_Clear);
private _applyW = ACTION_W(_applyText,_elseHeadH,false,_font);
private _clearW = ACTION_W(_clearText,_elseHeadH,false,_font);
private _applyX = _elseX + _elseW - _applyW;
private _clearX = _applyX - _elseGap - _clearW;
private _noteX = _elseX + _elseTitleW + _elseGap;
private _noteW = _clearX - _elseGap - _noteX;

[_display, _group, [_elseX, _elseHeadY, _elseTitleW, _elseHeadH], _elseTitle, TEXT_HEAD, _colorText, _fontBold, 0] call EFUNC(gui,uiLabel);

if (_noteW > SQUARE(UNIT * 2)) then {
    [
        _display, _group, [_noteX, _elseHeadY, _noteW, _elseHeadH],
        [LLSTRING(Else_Note), _noteW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL, _muted, _font, 0
    ] call EFUNC(gui,uiLabel);
};

// Clear takes out what Apply wrote; nothing to take out, nothing to click.
[_display, _group, [_clearX, _elseHeadY, _clearW, _elseHeadH], _clearText, "", _theme, {
    [[createHashMap, ["footprint", "stack"]], [createHashMap, ["grid"]]] call FUNC(upsertAll);
    [LLSTRING(Hint_ElseCleared), "text2"] call FUNC(setHint);
}, [], _itemIndex >= 0 || {_boxIndex >= 0}] call FUNC(uiAction);

// Apply writes what the steppers show; a grid by load is no rule at all - the built-in answer is that.
[_display, _group, [_applyX, _elseHeadY, _applyW, _elseHeadH], _applyText, "", _theme, {
    GVAR(elseEdit) params ["", "_across", "_down", "_stack", "_fixed", "_gridAcross", "_gridDown"];

    [
        [createHashMapFromArray [["footprint", format ["%1x%2", _across, _down]], ["stack", _stack]], []],
        [[createHashMap, createHashMapFromArray [["grid", format ["%1x%2", _gridAcross, _gridDown]]]] select _fixed, [["grid"], []] select _fixed]
    ] call FUNC(upsertAll);

    [LLSTRING(Hint_ElseApplied), "text2"] call FUNC(setHint);
}, [], true, "accent"] call FUNC(uiAction);

// The steppers keep what they show in GVAR(elseEdit) - its place given as their argument - until Apply.
private _fnc_keep = {
    params ["_value", "_slot"];

    GVAR(elseEdit) set [_slot, _value];
};

GVAR(elseEdit) params ["", "_editAcross", "_editDown", "_editStack", "_editFixed", "_editGridAcross", "_editGridDown"];

private _rowX = _elseX;
private _rowY = _elseHeadY + _elseHeadH + UNIT * 0.15;

[_display, _group, [_rowX, _rowY, _itemsLabelW, _elseRowH], _itemsLabel, TEXT_BODY, _colorText2, _font, 0] call EFUNC(gui,uiLabel);
_rowX = _rowX + _itemsLabelW + _elseGap;

[_display, _group, [_rowX, _rowY, _numberW, _elseRowH], _editAcross, [1, SHAPE_MAX, 1], _theme, _fnc_keep, 1] call FUNC(uiStepper);
[_display, _group, [_rowX + _numberW, _rowY, _timesW, _elseRowH], "×", TEXT_BODY, _colorText2, _font, 2] call EFUNC(gui,uiLabel);
[_display, _group, [_rowX + _numberW + _timesW, _rowY, _numberW, _elseRowH], _editDown, [1, SHAPE_MAX, 1], _theme, _fnc_keep, 2] call FUNC(uiStepper);
_rowX = _rowX + _numberW * 2 + _timesW + _elseGap;

[_display, _group, [_rowX, _rowY, _stackW, _elseRowH], _editStack, [1, EDIT_STACK_MAX, 1], _theme, _fnc_keep, 3, LLSTRING(Value_Stack)] call FUNC(uiStepper);

if (_elseRows == 1) then {
    _rowX = _rowX + _stackW + _elseSplit;
} else {
    _rowX = _elseX;
    _rowY = _rowY + _elseRowH + UNIT * 0.25;
};

[_display, _group, [_rowX, _rowY, _boxesLabelW, _elseRowH], _boxesLabel, TEXT_BODY, _colorText2, _font, 0] call EFUNC(gui,uiLabel);
_rowX = _rowX + _boxesLabelW + _elseGap;

// By load or fixed: the steppers of a fixed grid are greyed while it goes by load.
[_display, _group, [_rowX, _rowY, _modeW, _elseRowH], _modeLabels, parseNumber _editFixed, _theme, {
    params ["_index"];

    GVAR(elseEdit) set [4, _index == 1];

    [0] call FUNC(showStep);
}] call FUNC(uiSegmented);
_rowX = _rowX + _modeW + _elseGap;

[_display, _group, [_rowX, _rowY, _numberW, _elseRowH], _editGridAcross, [1, STORAGE_COLS, 1], _theme, _fnc_keep, 5, "%1", _editFixed] call FUNC(uiStepper);
[_display, _group, [_rowX + _numberW, _rowY, _timesW, _elseRowH], "×", TEXT_BODY, [DISABLED_INK, _colorText2] select _editFixed, _font, 2] call EFUNC(gui,uiLabel);
[_display, _group, [_rowX + _numberW + _timesW, _rowY, _numberW, _elseRowH], _editGridDown, [1, MAX_ROWS, 1], _theme, _fnc_keep, 6, "%1", _editFixed] call FUNC(uiStepper);

// ----- Advanced: the cell size -----

private _foldText = format ["%1 · %2: %3 · %4", LLSTRING(Start_Advanced), LLSTRING(Cell_Title), _cell, format [LLSTRING(Cell_Value), (_cell * MASS_TO_KG) toFixed 2]];
private _foldW = ACTION_W(_foldText,_foldH,true,_font) min _innerW;

if (GVAR(startAdvanced)) then {
    [_display, _group, [_padX, _advancedY, _innerW, _advancedH], _theme getOrDefault ["card", [1, 1, 1, 0.055]], _radius] call EFUNC(gui,uiPanel);
};

[_display, _group, [_padX, _advancedY, _foldW, _foldH], _foldText, [UI_TEX(icon_chevron_right_ca), UI_TEX(icon_chevron_down_ca)] select GVAR(startAdvanced), _theme, {
    GVAR(startAdvanced) = !GVAR(startAdvanced);

    [0] call FUNC(showStep);
}, [], true, "ghost", [LLSTRING(Start_AdvancedOpen), LLSTRING(Start_AdvancedClose)] select GVAR(startAdvanced)] call FUNC(uiAction);

if (!GVAR(startAdvanced)) exitWith {};

private _cellX = _padX + CARD_PAD_X;
private _cellW = _innerW - CARD_PAD_X * 2;
private _cellY = _advancedY + _foldH + UNIT * 0.1;
private _stepperW = SQUARE(UNIT * 5.4);
private _stepperH = UNIT * 1.2;

[_display, _group, [_cellX, _cellY, _stepperW, _stepperH], _cell, [1, 50, 1], _theme, {
    params ["_cell"];

    private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
    _ast set ["cell", _cell];

    [_ast] call FUNC(commit);
}] call FUNC(uiStepper);

private _valueX = _cellX + _stepperW + SQUARE(UNIT * 0.5);
private _valueText = format ["%1 · %2", format [LLSTRING(Cell_Value), (_cell * MASS_TO_KG) toFixed 2], [LLSTRING(Cell_FromPreset), LLSTRING(Cell_Own)] select _ownCell];

[
    _display, _group, [_valueX, _cellY + (_stepperH - UNIT * 0.75) / 2, _cellW - (_valueX - _cellX), UNIT * 0.75],
    _valueText, TEXT_BODY, _colorText, _font, 0
] call EFUNC(gui,uiLabel);

if (_ownCell) then {
    private _resetW = ACTION_W(LLSTRING(Cell_Reset),_stepperH,true,_font);

    [_display, _group, [_cellX + _cellW - _resetW, _cellY, _resetW, _stepperH], LLSTRING(Cell_Reset), ICON(icon_reset_ca,icon_auto_ca), _theme, {
        private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
        _ast set ["cell", -1];

        [_ast] call FUNC(commit);
    }, [], true, "ghost"] call FUNC(uiAction);
};

[_display, _group, [_cellX, _cellY + _stepperH + UNIT * 0.3, _cellW], LLSTRING(Cell_Help), TEXT_SMALL, _colorText2, _font] call FUNC(uiText);
