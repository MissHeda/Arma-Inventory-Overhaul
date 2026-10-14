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

// ----- Now in use | What you changed -----

private _cardsH = (_advancedY - _gapY) - _cursorY;
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
