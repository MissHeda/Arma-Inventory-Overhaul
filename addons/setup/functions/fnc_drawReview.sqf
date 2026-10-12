#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Step 5, Review: the draft as a whole, and where it goes.
 *   - Left: the own rules, each as a sentence (fnc_describeRule) with the statement itself under it and a
 *     cross to take it away; then the warnings - what the rules engine left out or could not use, a text
 *     too long to save.
 *   - Right, as text: the own rules - to edit by hand for those who know the rules language, used once
 *     Apply text is pressed -, the full setup with the preset written out, or a line for a
 *     cba_settings.sqf; to select and copy (Ctrl+A, Ctrl+C), with a Copy button where the game lets a
 *     script copy (the server, single player). Import pastes a shared one in.
 *   - Save: where it goes and how firmly, forced over the mission's own setup where that is allowed, Save
 *     - Apply in CBA's menu - and Reset to default.
 *   - The player's own presets: keep the draft under a name, load or delete one - in their profile, for any
 *     mission, also for players who may not save the server's setup.
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
 * [_display, _group, _theme, []] call einv_setup_fnc_drawReview;
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
private _loss = _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]];

private _padX = WIZ_PAD_X;
private _innerW = _width - _padX * 2;
private _gapY = UNIT * 0.5;
private _gapX = SQUARE(_gapY);
private _top = UNIT * 0.4;
private _bottom = _height - UNIT * 0.5;
private _leftW = (_innerW - _gapX) * 0.47;
private _rightX = _padX + _leftW + _gapX;
private _rightW = _innerW - _leftW - _gapX;
private _buttonH = UNIT * 1.15;
private _buttonGap = SQUARE(UNIT * 0.3);

// ----- Left: the own rules and the warnings -----

private _groups = GVAR(draft) getOrDefault ["groups", []];
private _rules = GVAR(draft) getOrDefault ["rules", []];

private _listTop = [_display, _group, [_padX, _top, _leftW, _bottom - _top], format [LLSTRING(Review_Rules), count _groups + count _rules], _theme] call FUNC(uiCard);
private _list = [_display, "EINV_ScrollGroup", _group, [_padX + CARD_PAD_X, _listTop, _leftW - CARD_PAD_X - pixelW * 2, _bottom - CARD_PAD_Y - _listTop]] call EFUNC(gui,uiCreate);

_list setVariable [QGVAR(scrollId), "reviewRules"];

(ctrlPosition _list) params ["", "", "_listW"];

private _rowW = _listW - SCROLL_W - SQUARE(UNIT * 0.35);
private _cell = GVAR(draftRules) getOrDefault ["cell", 5];
private _cursor = 0;

// What it builds on.
_cursor = _cursor + ([
    _display, _list, [0, _cursor, _rowW],
    format [LLSTRING(Review_Header), [GVAR(draft) getOrDefault ["base", "default"]] call FUNC(presetName), (_cell * MASS_TO_KG) toFixed 2],
    TEXT_BODY, _colorText2, _font
] call FUNC(uiText)) + UNIT * 0.35;

// Every own statement in the order the engine writes them, its groups first: the rows match its text.
([GVAR(draftText)] call FUNC(statements)) params ["", "_statements"];

private _entries = [];

{_entries pushBack [true, _x, _forEachIndex]} forEach _groups;
{_entries pushBack [false, _x, _forEachIndex]} forEach _rules;

if (_entries isEqualTo []) then {
    _cursor = _cursor + ([_display, _list, [0, _cursor, _rowW], LLSTRING(Review_NoRules), TEXT_BODY, _muted, _font] call FUNC(uiText)) + UNIT * 0.35;
};

private _rowH = UNIT * 1.85;
private _numberW = SQUARE(UNIT * 1.3);
private _removeH = UNIT * 1.1;
private _removeW = SQUARE(_removeH);
private _textW = _rowW - _numberW - _removeW - SQUARE(UNIT * 0.3);

{
    _x params ["_isGroup", "_statement", "_index"];

    private _sentence = [_statement, GVAR(draft), _isGroup] call FUNC(describeRule);
    private _raw = _statements param [_forEachIndex, ""];

    [_display, _list, [0, _cursor, _rowW, _rowH], [1, 1, 1, 0.035], (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3)] call EFUNC(gui,uiPanel);
    [_display, _list, [0, _cursor, _numberW, UNIT * 1.05], str (_forEachIndex + 1), TEXT_SMALL, _muted, _fontBold, 2] call EFUNC(gui,uiLabel);

    // The sentence, a group's in the accent; the statement as written under it.
    private _sentenceCtrl = [
        _display, _list, [_numberW, _cursor + UNIT * 0.12, _textW, UNIT * 0.9],
        [_sentence, _textW, _font, TEXT_BODY] call EFUNC(gui,fitText), TEXT_BODY, [_colorText, _accent] select _isGroup, _font, 0
    ] call EFUNC(gui,uiLabel);

    _sentenceCtrl ctrlSetTooltip format ["%1 - %2", _sentence, _raw];

    [
        _display, _list, [_numberW, _cursor + UNIT * 0.95, _textW, UNIT * 0.75],
        [_raw, _textW, "EtelkaMonospacePro", TEXT_SMALL * 0.85] call EFUNC(gui,fitText), TEXT_SMALL * 0.85, _muted, "EtelkaMonospacePro", 0
    ] call EFUNC(gui,uiLabel);

    [
        _display, _list, [_rowW - _removeW - SQUARE(UNIT * 0.15), _cursor + (_rowH - _removeH) / 2, _removeW, _removeH], "", UI_TEX(icon_close_ca), _theme, {
            params ["_isGroup", "_index"];

            private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
            (_ast getOrDefault [["rules", "groups"] select _isGroup, []]) deleteAt _index;

            [_ast] call FUNC(commit);
        }, [_isGroup, _index], true, "ghost", LLSTRING(Review_Remove)
    ] call FUNC(uiAction);

    _cursor = _cursor + _rowH + UNIT * 0.2;
} forEach _entries;

// The warnings: what the engine left out of the text the draft came from, and what it could not use when
// it compiled it - a long text among them -, each once. A text too long to save on top.
private _warnings = (+GVAR(parseWarnings)) + (GVAR(draftRules) getOrDefault ["warnings", []]);
private _length = count GVAR(draftText);

if (_length > TEXT_MAX) then {
    _warnings = [format [LLSTRING(Warning_TooLong), _length]] + _warnings;
};

_warnings = _warnings select {_x isEqualType ""};
_warnings = _warnings arrayIntersect _warnings;

_cursor = _cursor + UNIT * 0.3;

[_display, _list, [0, _cursor, _rowW, UNIT * 1], format [LLSTRING(Review_Warnings), count _warnings], TEXT_BODY, _colorText, _fontBold, 0] call EFUNC(gui,uiLabel);

_cursor = _cursor + UNIT * 1.05;

if (_warnings isEqualTo []) then {
    [_display, _list, [0, _cursor, _rowW], LLSTRING(Review_NoWarnings), TEXT_SMALL, _muted, _font] call FUNC(uiText);
};

{
    private _dotH = UNIT * 0.28;

    [_display, _list, [SQUARE(UNIT * 0.2), _cursor + UNIT * 0.22, SQUARE(_dotH), _dotH], UI_TEX(circle_ca), _accent] call EFUNC(gui,uiIcon);

    _cursor = _cursor + ([_display, _list, [SQUARE(UNIT * 0.75), _cursor, _rowW - SQUARE(UNIT * 0.75)], _x, TEXT_SMALL, _colorText2, _font] call FUNC(uiText)) + UNIT * 0.2;
} forEach _warnings;

// ----- Right: as text -----

private _saveH = UNIT * 7.4;
private _presetsH = UNIT * 4.9;
private _textH = (_bottom - _top) - _saveH - _presetsH - _gapY * 2;
private _textTop = [_display, _group, [_rightX, _top, _rightW, _textH], LLSTRING(Text_Title), _theme] call FUNC(uiCard);
private _cardX = _rightX + CARD_PAD_X;
private _cardW = _rightW - CARD_PAD_X * 2;

// Which text: the own rules, the full setup, a line for a cba_settings.sqf.
private _segmentH = UNIT * 0.95;
private _segmentW = (SQUARE(UNIT * 13)) min (_cardW * 0.62);

[
    _display, _group, [_cardX + _cardW - _segmentW, _top + CARD_PAD_Y + (CARD_CAPTION_H - _segmentH) / 2, _segmentW, _segmentH],
    [LLSTRING(Text_Own), LLSTRING(Text_Full), LLSTRING(Text_Cba)], GVAR(exportMode), _theme, {
        params ["_index"];

        GVAR(exportMode) = _index;
        [GVAR(step)] call FUNC(showStep);
    }
] call FUNC(uiSegmented);

private _variant = ["own", "full", "cba"] param [GVAR(exportMode), "own"];
private _own = _variant isEqualTo "own";
private _shown = [_variant] call FUNC(exportText);

// The own rules can be typed into. What is typed is kept through redraws until it is applied, or the
// draft changes some other way.
if (_own) then {
    GVAR(rawShown) = _shown;

    if (GVAR(rawText) isNotEqualTo "") then {
        _shown = GVAR(rawText);
    };
};

private _noteH = UNIT * 0.8;
private _buttonsY = _top + _textH - CARD_PAD_Y - _buttonH;
private _noteY = _buttonsY - UNIT * 0.2 - _noteH;
private _areaH = (_noteY - UNIT * 0.15) - _textTop;

private _area = [_display, _group, [_cardX, _textTop, _cardW, _areaH], _shown, "", _theme, {
    params ["_text"];

    GVAR(rawText) = _text;

    private _state = uiNamespace getVariable [QGVAR(rawState), controlNull];
    private _applied = _text isEqualTo GVAR(rawShown);

    _state ctrlSetText ([LLSTRING(Text_Unapplied), LLSTRING(Text_OwnNote)] select _applied);
    _state ctrlSetTextColor (GVAR(theme) getOrDefault [["accent", "muted"] select _applied, [1, 1, 1, 1]]);

    // How long the typed text is, in red once it is too long to apply.
    private _count = uiNamespace getVariable [QGVAR(rawCount), controlNull];

    _count ctrlSetText format [LLSTRING(Text_Chars), count _text];
    _count ctrlSetTextColor (GVAR(theme) getOrDefault [["muted", "loss"] select (count _text > TEXT_MAX), [1, 1, 1, 1]]);
}, [], true, _own] call FUNC(uiEdit);

uiNamespace setVariable [QGVAR(textArea), _area select (count _area - 1)];

// Under it: what the text is for - or that what was typed is not used yet - and how long it is: the own
// rules as saved, or what was typed into them and not applied yet. As wide as the longest the box takes.
private _chars = count ([_shown, GVAR(draftText)] select (_own && {GVAR(rawText) isEqualTo ""}));
private _countText = format [LLSTRING(Text_Chars), _chars];
private _countW = ((format [LLSTRING(Text_Chars), 88888]) getTextWidth [_font, TEXT_SMALL]) * TEXT_SLACK;

private _countCtrl = [
    _display, _group, [_cardX + _cardW - _countW, _noteY, _countW, _noteH], _countText, TEXT_SMALL,
    [_muted, _loss] select (_own && {_chars > TEXT_MAX}), _font, 1
] call EFUNC(gui,uiLabel);

private _unapplied = _own && {GVAR(rawText) isNotEqualTo ""} && {GVAR(rawText) isNotEqualTo GVAR(rawShown)};
private _noteText = switch (_variant) do {
    case "full": {LLSTRING(Text_FullNote)};
    case "cba": {LLSTRING(Text_CbaNote)};
    default {[LLSTRING(Text_OwnNote), LLSTRING(Text_Unapplied)] select _unapplied};
};
private _noteW = _cardW - _countW - SQUARE(UNIT * 0.3);

private _note = [
    _display, _group, [_cardX, _noteY, _noteW, _noteH], [_noteText, _noteW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL,
    [_muted, _accent] select _unapplied, _font, 0
] call EFUNC(gui,uiLabel);

_note ctrlSetTooltip _noteText;

if (_own) then {
    uiNamespace setVariable [QGVAR(rawState), _note];
    uiNamespace setVariable [QGVAR(rawCount), _countCtrl];
};

// Apply text (own rules only), Copy (where the game lets a script copy), Import.
private _buttons = [];

if (_own) then {
    _buttons pushBack [LLSTRING(Text_Apply), {
        private _edit = uiNamespace getVariable [QGVAR(textArea), controlNull];
        private _text = [ctrlText _edit, GVAR(rawText)] select (isNull _edit);

        if (_text isEqualTo "" || {_text isEqualTo GVAR(rawShown)}) exitWith {
            [LLSTRING(Text_NothingToApply), "text2"] call FUNC(setHint);
        };

        // Cleaned as the setting's own box cleans it. Longer than a setup may be, the engine would read it
        // as the bare default and everything typed would be gone: not applied, and it stays in the box to
        // be shortened.
        private _clean = [_text] call FUNC(sanitize);

        if (count _clean > TEXT_MAX) exitWith {
            GVAR(rawText) = _text;

            [format [LLSTRING(Warning_TooLong), count _clean], "loss"] call FUNC(setHint);
        };

        private _ast = [_clean] call EFUNC(items,parseRules);
        private _count = count (_ast getOrDefault ["warnings", []]);

        [_ast] call FUNC(commit);
        [format [LLSTRING(Text_Applied), _count], ["gain", "accent"] select (_count > 0)] call FUNC(setHint);
    }, "accent"];
};

if (isServer || {!isMultiplayer}) then {
    _buttons pushBack [LLSTRING(Text_Copy), {
        copyToClipboard ctrlText (uiNamespace getVariable [QGVAR(textArea), controlNull]);
        [LLSTRING(Text_Copied), "gain"] call FUNC(setHint);
    }, ""];
};

_buttons pushBack [LLSTRING(Import), {
    [uiNamespace getVariable [QGVAR(display), displayNull]] call FUNC(openImport);
}, ""];

private _textButtonW = (_cardW - _buttonGap * (count _buttons - 1)) / count _buttons;

{
    _x params ["_label", "_code", "_style"];

    [_display, _group, [_cardX + _forEachIndex * (_textButtonW + _buttonGap), _buttonsY, _textButtonW, _buttonH], _label, "", _theme, _code, [], true, _style] call FUNC(uiAction);
} forEach _buttons;

// ----- Right: save -----

private _saveY = _top + _textH + _gapY;
private _lineY = [_display, _group, [_rightX, _saveY, _rightW, _saveH], LLSTRING(Save_Title), _theme] call FUNC(uiCard);
private _target = GVAR(target);

if (GVAR(readOnly)) then {
    _lineY = _lineY + ([_display, _group, [_cardX, _lineY, _cardW], format [LLSTRING(Save_ReadOnly), _target getOrDefault ["reason", ""]], TEXT_BODY, _loss, _font] call FUNC(uiText)) + UNIT * 0.2;

    [_display, _group, [_cardX, _lineY, _cardW], LLSTRING(Save_ReadOnlyHelp), TEXT_SMALL, _muted, _font] call FUNC(uiText);
} else {
    private _source = _target getOrDefault ["source", ""];
    private _where = switch (true) do {
        case (GVAR(mode) isEqualTo "menu"): {format [LLSTRING(Save_ToMenu), localize format ["STR_einv_setup_Source_%1", _source]]};
        case (_source isEqualTo "mission"): {LLSTRING(Save_ToMission)};
        default {LLSTRING(Save_ToServer)};
    };

    _lineY = _lineY + ([_display, _group, [_cardX, _lineY, _cardW], _where, TEXT_SMALL, _colorText2, _font] call FUNC(uiText)) + UNIT * 0.2;

    // Forced over the mission's own setup - only where it cannot outlive what it is meant for (fnc_canEdit).
    if (_target getOrDefault ["override", false]) then {
        [_display, _group, [_cardX, _lineY, _cardW, UNIT * 1.05], GVAR(override), _theme, {
            params ["_on"];

            GVAR(override) = _on;
            [GVAR(step)] call FUNC(showStep);
        }, [], true, LLSTRING(Save_Override)] call FUNC(uiToggle);

        _lineY = _lineY + UNIT * 1.1;
    };

    if ((_target getOrDefault ["missionWins", false]) && {!GVAR(override)}) then {
        [_display, _group, [_cardX, _lineY, _cardW], LLSTRING(Save_MissionWins), TEXT_SMALL, _accent, _font] call FUNC(uiText);
    };
};

private _saveButtonsY = _saveY + _saveH - CARD_PAD_Y - _buttonH;
private _halfW = (_cardW - _buttonGap) / 2;
private _canSave = !GVAR(readOnly) && {(call FUNC(isDirty)) || {GVAR(sourceEmpty)}};

[_display, _group, [_cardX, _saveButtonsY, _halfW, _buttonH], LLSTRING(Reset), ICON(icon_reset_ca,icon_auto_ca), _theme, {
    [uiNamespace getVariable [QGVAR(display), displayNull], LLSTRING(Reset_Confirm), LLSTRING(Reset_Yes), {
        [[RULES_DEFAULT] call EFUNC(items,parseRules)] call FUNC(commit);
        [LLSTRING(Reset_Done), "text2"] call FUNC(setHint);
    }] call FUNC(confirm);
}, [], true, "danger"] call FUNC(uiAction);

[
    _display, _group, [_cardX + _cardW - _halfW, _saveButtonsY, _halfW, _buttonH],
    [LLSTRING(Save), LLSTRING(Apply)] select (GVAR(mode) isEqualTo "menu"), "", _theme, {[] call FUNC(save)}, [], _canSave, "accent",
    [[LLSTRING(Save_NothingYet), LLSTRING(Save_Tooltip)] select _canSave, format [LLSTRING(Save_ReadOnly), _target getOrDefault ["reason", ""]]] select GVAR(readOnly)
] call FUNC(uiAction);

// ----- Right: the player's own presets -----

private _presetsY = _saveY + _saveH + _gapY;
private _presetsTop = [_display, _group, [_rightX, _presetsY, _rightW, _presetsH], LLSTRING(Presets_Title), _theme] call FUNC(uiCard);
private _presets = ["list"] call FUNC(personalPresets);

if ((_presets findIf {(_x select 0) == GVAR(presetPick)}) < 0) then {
    GVAR(presetPick) = "";
};

private _picked = GVAR(presetPick) isNotEqualTo "";
private _smallW = SQUARE(UNIT * 4.2);
private _dropW = _cardW - (_smallW + _buttonGap) * 2;

[
    _display, _group, [_cardX, _presetsTop, _dropW, _buttonH], _presets apply {[format ["%1   %2", _x select 0, _x select 2], _x select 0]},
    GVAR(presetPick), _theme, {
        params ["_name"];

        GVAR(presetPick) = _name;
        [GVAR(step)] call FUNC(showStep);
    }, [], true, [LLSTRING(Presets_Pick), LLSTRING(Presets_None)] select (_presets isEqualTo [])
] call FUNC(uiDropdown);

[_display, _group, [_cardX + _dropW + _buttonGap, _presetsTop, _smallW, _buttonH], LLSTRING(Presets_Load), "", _theme, {
    private _preset = (["list"] call FUNC(personalPresets)) select {(_x select 0) == GVAR(presetPick)};

    if (_preset isEqualTo []) exitWith {};

    (_preset select 0) params ["_name", "_text"];

    [[_text] call EFUNC(items,parseRules)] call FUNC(commit);
    [format [LLSTRING(Presets_Loaded), _name], "gain"] call FUNC(setHint);
}, [], _picked] call FUNC(uiAction);

[_display, _group, [_cardX + _cardW - _smallW, _presetsTop, _smallW, _buttonH], LLSTRING(Presets_Delete), "", _theme, {
    private _name = GVAR(presetPick);

    if (_name isEqualTo "") exitWith {};

    [uiNamespace getVariable [QGVAR(display), displayNull], format [LLSTRING(Presets_DeleteConfirm), _name], LLSTRING(Presets_Delete), {
        params ["_name"];

        ["delete", _name] call FUNC(personalPresets);
        GVAR(presetPick) = "";

        [GVAR(step)] call FUNC(showStep);
        [format [LLSTRING(Presets_Deleted), _name], "text2"] call FUNC(setHint);
    }, [_name]] call FUNC(confirm);
}, [], _picked, "danger"] call FUNC(uiAction);

[_display, _group, [_cardX, _presetsTop + _buttonH + UNIT * 0.3, _cardW, _buttonH], LLSTRING(Presets_SaveAs), "", _theme, {
    [uiNamespace getVariable [QGVAR(display), displayNull], [], [SQUARE(UNIT * 17), UNIT * 4.6], LLSTRING(Presets_SaveAs_Title), {
        params ["_display", "_inner", "_theme"];

        (ctrlPosition _inner) params ["", "", "_width", "_height"];

        // Kept under the name typed - an older preset of that name is replaced.
        private _fnc_keep = {
            private _name = trim ctrlText (uiNamespace getVariable [QGVAR(presetEdit), controlNull]);

            if (_name isEqualTo "") exitWith {
                [LLSTRING(Presets_NeedName), "loss"] call FUNC(setHint);
            };

            ["save", _name, GVAR(draftText)] call FUNC(personalPresets);
            GVAR(presetPick) = _name;

            call FUNC(closePopover);
            [GVAR(step)] call FUNC(showStep);
            [format [LLSTRING(Presets_Saved), _name], "gain"] call FUNC(setHint);
        };

        private _helpH = [_display, _inner, [0, 0, _width], LLSTRING(Presets_Help), TEXT_SMALL, _theme getOrDefault ["muted", [0.52, 0.55, 0.6, 1]], _theme getOrDefault ["font", "PuristaMedium"]] call FUNC(uiText);
        private _field = [_display, _inner, [0, _helpH + UNIT * 0.3, _width, UNIT * 1.15], GVAR(presetPick), LLSTRING(Presets_Name), _theme, {
            params ["", "_submitted", "_arguments"];

            if (_submitted) then {
                call (_arguments select 0);
            };
        }, [_fnc_keep]] call FUNC(uiEdit);
        private _edit = _field select (count _field - 1);

        uiNamespace setVariable [QGVAR(presetEdit), _edit];
        ctrlSetFocus _edit;

        private _keepW = SQUARE(UNIT * 6);

        [_display, _inner, [_width - _keepW, _height - UNIT * 1.15, _keepW, UNIT * 1.15], LLSTRING(Presets_Keep), "", _theme, _fnc_keep, [], true, "accent"] call FUNC(uiAction);
    }] call FUNC(popover);
}] call FUNC(uiAction);
