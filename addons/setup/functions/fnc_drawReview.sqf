#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Step 4, Review: what Save would change, and the buttons to do it - one column, top to bottom, nothing of
 * the rules language unless asked for, so nobody has to learn it to save:
 *   - "What changes" (fnc_drawChanges "saved"): every difference to what is saved, in words, each with a
 *     cross to take it back, and under it how many there are against the Default preset.
 *   - Warnings, only when there are any: what the rules engine left out or could not use, a text too
 *     long to save - each one sentence.
 *   - Where Save goes - or why it may not -, the switch to force it over the mission's own setup where
 *     that is allowed, and one row of buttons: Export, Import..., Reset to default, and Save on the right
 *     (Apply to Addon Options in CBA's menu).
 *   - Folded away, both closed whenever the wizard opens: the saved drafts (fnc_personalPresets) - kept
 *     in the player's profile for any mission, also by players who may not save -, and the setup as text
 *     for mission makers: their own rules, the full setup or a line for a cba_settings.sqf, read only
 *     until Edit text, then typed into and used once Apply text is pressed.
 * Export copies the cba_settings.sqf line where the game lets a script copy (the server, single player,
 * Eden); a player in multiplayer gets the line unfolded to copy by hand.
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
private _colorText = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.698, 0.734, 0.784, 1]];
private _muted = _theme getOrDefault ["muted", [0.522, 0.553, 0.604, 1]];
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _loss = _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]];
private _radius = _theme getOrDefault ["radius", 0];

private _padX = WIZ_PAD_X;
private _innerW = _width - _padX * 2;
private _cardX = _padX + CARD_PAD_X;
private _cardW = _innerW - CARD_PAD_X * 2;
private _gapY = UNIT * 0.4;
private _top = UNIT * 0.4;
private _bottom = _height - UNIT * 0.5;
private _buttonH = UNIT * 1.15;
private _buttonGap = SQUARE(UNIT * 0.3);
private _foldH = UNIT * 1.1;
private _target = GVAR(target);

// A button whose box opens under it: its code gets the button's rectangle on the screen.
private _fnc_anchored = {
    params ["_parent", "_rect", "_label", "_code", ["_enabled", true], ["_style", ""], ["_tooltip", ""]];

    private _controls = [_display, _parent, _rect, _label, "", _theme, {}, [], _enabled, _style, _tooltip] call FUNC(uiAction);
    private _hit = _controls select (count _controls - 1);

    _hit setVariable [QGVAR(action), [{
        params ["_hit", "_code"];

        [[_hit] call FUNC(screenRect)] call _code;
    }, [_hit, _code]]];
};

// ----- Measured first, in a group thrown away again: what is left decides how tall the list is -----

// The warnings: what the engine left out of the text the draft came from, and what it could not use when
// it compiled it - a long text among them -, each once. A text too long to save on top.
private _warnings = (+GVAR(parseWarnings)) + (GVAR(draftRules) getOrDefault ["warnings", []]);
private _length = count GVAR(draftText);

if (_length > TEXT_MAX) then {
    _warnings = [format [LLSTRING(Warning_TooLong), _length]] + _warnings;
};

_warnings = _warnings select {_x isEqualType ""};
_warnings = _warnings arrayIntersect _warnings;

// Where Save goes, or why it may not: a player who cannot save should know before pressing anything.
private _saveLines = [];

if (GVAR(readOnly)) then {
    _saveLines pushBack [format [LLSTRING(Save_ReadOnly), _target getOrDefault ["reason", ""]], TEXT_BODY, _loss];
    _saveLines pushBack [LLSTRING(Save_ReadOnlyHelp), TEXT_SMALL, _muted];
} else {
    private _source = _target getOrDefault ["source", ""];
    private _where = switch (true) do {
        case (GVAR(mode) isEqualTo "menu"): {format [LLSTRING(Save_ToMenu), localize format ["STR_einv_setup_Source_%1", _source]]};
        case (_source isEqualTo "mission"): {LLSTRING(Save_ToMission)};
        default {LLSTRING(Save_ToServer)};
    };

    _saveLines pushBack [_where, TEXT_BODY, _colorText2];

    if ((_target getOrDefault ["missionWins", false]) && {!GVAR(override)}) then {
        _saveLines pushBack [LLSTRING(Save_MissionWins), TEXT_SMALL, _accent];
    };
};

// Forced over the mission's own setup - only where it cannot outlive what it is meant for (fnc_canEdit).
private _hasToggle = !GVAR(readOnly) && {_target getOrDefault ["override", false]};
private _warnTextX = SQUARE(UNIT * 0.75);
private _probe = [_display, "EINV_Group", _group, [0, 0, _innerW, UNIT * 10]] call EFUNC(gui,uiCreate);

{
    _x pushBack ([_display, _probe, [0, 0, _cardW], _x select 0, _x select 1, _colorText, _font] call FUNC(uiText));
} forEach _saveLines;

private _warningHeights = _warnings apply {[_display, _probe, [0, 0, _cardW - _warnTextX], _x, TEXT_SMALL, _colorText, _font] call FUNC(uiText)};

ctrlDelete _probe;

private _saveTextH = 0;

{
    _saveTextH = _saveTextH + (_x select 3) + UNIT * 0.15;
} forEach _saveLines;

private _saveH = CARD_PAD_Y + _saveTextH + ([0, UNIT * 1.1] select _hasToggle) + UNIT * 0.15 + _buttonH + CARD_PAD_Y;

// The warnings scroll past a few lines - more while the text is folded away.
private _warnListH = 0;

{
    _warnListH = _warnListH + _x + UNIT * 0.15;
} forEach _warningHeights;

_warnListH = _warnListH min ([UNIT * 4.4, UNIT * 2.4] select GVAR(reviewText));

private _warnH = [0, CARD_PAD_Y + CARD_CAPTION_H + UNIT * 0.15 + _warnListH + CARD_PAD_Y] select (_warnings isNotEqualTo []);
private _draftsH = [_foldH, _foldH + UNIT * 0.15 + _buttonH + CARD_PAD_Y] select GVAR(reviewDrafts);

// The list and the text share what is left; the list keeps enough for a few lines.
private _free = (_bottom - _top) - ([0, _warnH + _gapY] select (_warnH > 0)) - _gapY - _saveH - _gapY - _draftsH - _gapY;
private _changesH = _free - _foldH;
private _textH = _foldH;

if (GVAR(reviewText)) then {
    private _textMin = UNIT * 7.5;

    _changesH = (_free * 0.4) max (UNIT * 4.5);

    if (_free - _changesH < _textMin) then {
        _changesH = (_free - _textMin) max (UNIT * 4.5);
    };

    _textH = _free - _changesH;
};

// ----- What changes -----

[_display, _group, [_padX, _top, _innerW, _changesH], _theme, "saved"] call FUNC(drawChanges);

private _cursorY = _top + _changesH + _gapY;

// ----- Warnings, only when there are any -----

if (_warnH > 0) then {
    private _listTop = [_display, _group, [_padX, _cursorY, _innerW, _warnH], format [LLSTRING(Review_Warnings), count _warnings], _theme] call FUNC(uiCard);
    private _list = [_display, "EINV_ScrollGroup", _group, [_cardX, _listTop, _cardW + CARD_PAD_X - pixelW * 2, _warnListH]] call EFUNC(gui,uiCreate);
    private _dotH = UNIT * 0.28;
    private _lineY = 0;

    _list setVariable [QGVAR(scrollId), "reviewWarnings"];

    {
        [_display, _list, [SQUARE(UNIT * 0.2), _lineY + UNIT * 0.2, SQUARE(_dotH), _dotH], UI_TEX(circle_ca), _accent] call EFUNC(gui,uiIcon);

        _lineY = _lineY + ([_display, _list, [_warnTextX, _lineY, _cardW - _warnTextX], _x, TEXT_SMALL, _colorText2, _font] call FUNC(uiText)) + UNIT * 0.15;
    } forEach _warnings;

    _cursorY = _cursorY + _warnH + _gapY;
};

// ----- Where Save goes, and the buttons -----

private _lineY = [_display, _group, [_padX, _cursorY, _innerW, _saveH], "", _theme] call FUNC(uiCard);

{
    _x params ["_text", "_size", "_color"];

    _lineY = _lineY + ([_display, _group, [_cardX, _lineY, _cardW], _text, _size, _color, _font] call FUNC(uiText)) + UNIT * 0.15;
} forEach _saveLines;

if (_hasToggle) then {
    [_display, _group, [_cardX, _lineY, _cardW, UNIT * 1.05], GVAR(override), _theme, {
        params ["_on"];

        GVAR(override) = _on;
        [GVAR(step)] call FUNC(showStep);
    }, [], true, LLSTRING(Save_Override)] call FUNC(uiToggle);
};

private _buttonsY = _cursorY + _saveH - CARD_PAD_Y - _buttonH;
private _canSave = !GVAR(readOnly) && {(call FUNC(isDirty)) || {GVAR(sourceEmpty)}};
private _atDefault = (["default", false] call FUNC(changeRows)) isEqualTo [];
private _minW = SQUARE(UNIT * 4.5);
private _resetIcon = ICON(icon_reset_ca,icon_auto_ca);
private _exportW = ACTION_W(LLSTRING(Export),_buttonH,false,_font) max _minW;
private _importW = ACTION_W(LLSTRING(Import),_buttonH,false,_font) max _minW;
private _resetW = ACTION_W(LLSTRING(Reset),_buttonH,true,_font) max _minW;
private _saveLabel = [LLSTRING(Save), LLSTRING(Apply)] select (GVAR(mode) isEqualTo "menu");
private _saveW = ACTION_W(_saveLabel,_buttonH,false,_font) max SQUARE(UNIT * 6);
private _buttonX = _cardX;

[_display, _group, [_buttonX, _buttonsY, _exportW, _buttonH], LLSTRING(Export), "", _theme, {
    private _line = ["cba"] call FUNC(exportText);

    // The game lets a script copy only on the server and alone: anyone else gets the line to copy by hand.
    if (isServer || {!isMultiplayer}) exitWith {
        copyToClipboard _line;

        [LLSTRING(Export_Copied), "gain"] call FUNC(setHint);
    };

    GVAR(reviewText) = true;
    GVAR(exportMode) = 2;

    [GVAR(step)] call FUNC(showStep);
    [LLSTRING(Export_ByHand), "accent"] call FUNC(setHint);
}, [], true, "", LLSTRING(Export_Tip)] call FUNC(uiAction);

_buttonX = _buttonX + _exportW + _buttonGap;

[_group, [_buttonX, _buttonsY, _importW, _buttonH], LLSTRING(Import), {
    params ["_anchor"];

    [uiNamespace getVariable [QGVAR(display), displayNull], _anchor] call FUNC(openImport);
}, true, "", LLSTRING(Import_Tip)] call _fnc_anchored;

_buttonX = _buttonX + _importW + _buttonGap;

[_display, _group, [_buttonX, _buttonsY, _resetW, _buttonH], LLSTRING(Reset), _resetIcon, _theme, {
    [uiNamespace getVariable [QGVAR(display), displayNull], LLSTRING(Reset_Confirm), LLSTRING(Reset_Yes), {
        [[RULES_DEFAULT] call EFUNC(items,parseRules)] call FUNC(commit);
        [LLSTRING(Reset_Done), "text2"] call FUNC(setHint);
    }] call FUNC(confirm);
}, [], !_atDefault, "danger", [LLSTRING(Reset_Tip), LLSTRING(Reset_Already)] select _atDefault] call FUNC(uiAction);

[
    _display, _group, [_cardX + _cardW - _saveW, _buttonsY, _saveW, _buttonH], _saveLabel, "", _theme, {[] call FUNC(save)}, [], _canSave, "accent",
    [[LLSTRING(Save_NothingYet), LLSTRING(Save_Tooltip)] select _canSave, format [LLSTRING(Save_ReadOnly), _target getOrDefault ["reason", ""]]] select GVAR(readOnly)
] call FUNC(uiAction);

_cursorY = _cursorY + _saveH + _gapY;

// ----- Folded: the saved drafts -----

private _drafts = ["list"] call FUNC(personalPresets);

if ((_drafts findIf {(_x select 0) == GVAR(draftPick)}) < 0) then {
    GVAR(draftPick) = "";
};

private _fnc_fold = {
    params ["_y", "_h", "_open", "_label", "_code", "_tooltips"];

    if (_open) then {
        [_display, _group, [_padX, _y, _innerW, _h], _theme getOrDefault ["card", [1, 1, 1, 0.055]], _radius] call EFUNC(gui,uiPanel);
    };

    [
        _display, _group, [_padX, _y, ACTION_W(_label,_foldH,true,_font) min _innerW, _foldH], _label,
        [UI_TEX(icon_chevron_right_ca), UI_TEX(icon_chevron_down_ca)] select _open, _theme, _code, [], true, "ghost", _tooltips select _open
    ] call FUNC(uiAction);
};

[
    _cursorY, _draftsH, GVAR(reviewDrafts), format ["%1 (%2)", LLSTRING(Drafts_Title), count _drafts], {
        GVAR(reviewDrafts) = !GVAR(reviewDrafts);

        [GVAR(step)] call FUNC(showStep);
    }, [LLSTRING(Drafts_Help), LLSTRING(Drafts_Help)]
] call _fnc_fold;

if (GVAR(reviewDrafts)) then {
    private _rowY = _cursorY + _foldH + UNIT * 0.15;
    private _picked = GVAR(draftPick) isNotEqualTo "";
    private _loadW = ACTION_W(LLSTRING(Drafts_Load),_buttonH,false,_font) max _minW;
    private _deleteW = ACTION_W(LLSTRING(Drafts_Delete),_buttonH,false,_font) max _minW;
    private _keepW = ACTION_W(LLSTRING(Drafts_SaveAs),_buttonH,false,_font) max _minW;
    private _dropW = (_cardW - _loadW - _deleteW - _keepW - _buttonGap * 3) min SQUARE(UNIT * 22);
    private _rowX = _cardX + _dropW + _buttonGap;

    [
        _display, _group, [_cardX, _rowY, _dropW, _buttonH], _drafts apply {[format ["%1   %2", _x select 0, _x select 2], _x select 0]},
        GVAR(draftPick), _theme, {
            params ["_name"];

            GVAR(draftPick) = _name;
            [GVAR(step)] call FUNC(showStep);
        }, [], _drafts isNotEqualTo [], [LLSTRING(Drafts_Pick), LLSTRING(Drafts_None)] select (_drafts isEqualTo [])
    ] call FUNC(uiDropdown);

    [_display, _group, [_rowX, _rowY, _loadW, _buttonH], LLSTRING(Drafts_Load), "", _theme, {
        private _draft = (["list"] call FUNC(personalPresets)) select {(_x select 0) == GVAR(draftPick)};

        if (_draft isEqualTo []) exitWith {};

        (_draft select 0) params ["_name", "_text"];

        [[_text] call EFUNC(items,parseRules)] call FUNC(commit);
        [format [LLSTRING(Drafts_Loaded), _name], "gain"] call FUNC(setHint);
    }, [], _picked] call FUNC(uiAction);

    _rowX = _rowX + _loadW + _buttonGap;

    [_display, _group, [_rowX, _rowY, _deleteW, _buttonH], LLSTRING(Drafts_Delete), "", _theme, {
        private _name = GVAR(draftPick);

        if (_name isEqualTo "") exitWith {};

        [uiNamespace getVariable [QGVAR(display), displayNull], format [LLSTRING(Drafts_DeleteConfirm), _name], LLSTRING(Drafts_Delete), {
            params ["_name"];

            ["delete", _name] call FUNC(personalPresets);
            GVAR(draftPick) = "";

            [GVAR(step)] call FUNC(showStep);
            [format [LLSTRING(Drafts_Deleted), _name], "text2"] call FUNC(setHint);
        }, [_name]] call FUNC(confirm);
    }, [], _picked, "danger"] call FUNC(uiAction);

    _rowX = _rowX + _deleteW + _buttonGap;

    [_group, [_rowX, _rowY, _keepW, _buttonH], LLSTRING(Drafts_SaveAs), {
        params ["_anchor"];

        [uiNamespace getVariable [QGVAR(display), displayNull], _anchor, [SQUARE(UNIT * 17), UNIT * 4.6], LLSTRING(Drafts_SaveAs_Title), {
            params ["_display", "_inner", "_theme"];

            (ctrlPosition _inner) params ["", "", "_width", "_height"];

            // Kept under the name typed - an older draft of that name is replaced.
            private _fnc_keep = {
                private _name = trim ctrlText (uiNamespace getVariable [QGVAR(draftEdit), controlNull]);

                if (_name isEqualTo "") exitWith {
                    [LLSTRING(Drafts_NeedName), "loss"] call FUNC(setHint);
                };

                ["save", _name, GVAR(draftText)] call FUNC(personalPresets);
                GVAR(draftPick) = _name;

                call FUNC(closePopover);
                [GVAR(step)] call FUNC(showStep);
                [format [LLSTRING(Drafts_Saved), _name], "gain"] call FUNC(setHint);
            };

            private _helpH = [_display, _inner, [0, 0, _width], LLSTRING(Drafts_Help), TEXT_SMALL, _theme getOrDefault ["muted", [0.52, 0.55, 0.6, 1]], _theme getOrDefault ["font", "PuristaMedium"]] call FUNC(uiText);
            private _field = [_display, _inner, [0, _helpH + UNIT * 0.3, _width, UNIT * 1.15], GVAR(draftPick), LLSTRING(Drafts_Name), _theme, {
                params ["", "_submitted", "_arguments"];

                if (_submitted) then {
                    call (_arguments select 0);
                };
            }, [_fnc_keep]] call FUNC(uiEdit);
            private _edit = _field select (count _field - 1);

            uiNamespace setVariable [QGVAR(draftEdit), _edit];
            ctrlSetFocus _edit;

            private _keepW = SQUARE(UNIT * 6);

            [_display, _inner, [_width - _keepW, _height - UNIT * 1.15, _keepW, UNIT * 1.15], LLSTRING(Drafts_Keep), "", _theme, _fnc_keep, [], true, "accent"] call FUNC(uiAction);
        }] call FUNC(popover);
    }] call _fnc_anchored;
};

_cursorY = _cursorY + _draftsH + _gapY;

// ----- Folded: the setup as text, for mission makers -----

[
    _cursorY, _textH, GVAR(reviewText), LLSTRING(Text_Title), {
        GVAR(reviewText) = !GVAR(reviewText);

        [GVAR(step)] call FUNC(showStep);
    }, [LLSTRING(Text_Intro), LLSTRING(Text_Intro)]
] call _fnc_fold;

if (!GVAR(reviewText)) exitWith {};

private _textTop = _cursorY + _foldH + UNIT * 0.1;
private _textBottom = _cursorY + _textH - CARD_PAD_Y;

// One sentence of what it is, and which text: the own rules, the full setup, a line for a cba_settings.sqf.
private _segmentH = UNIT * 0.95;
private _segmentW = (SQUARE(UNIT * 13)) min (_cardW * 0.5);

[
    _display, _group, [_cardX, _textTop, _cardW - _segmentW - _buttonGap, _segmentH],
    [LLSTRING(Text_Intro), _cardW - _segmentW - _buttonGap, _font, TEXT_BODY] call EFUNC(gui,fitText), TEXT_BODY, _colorText2, _font, 0
] call EFUNC(gui,uiLabel);

[
    _display, _group, [_cardX + _cardW - _segmentW, _textTop, _segmentW, _segmentH],
    [LLSTRING(Text_Own), LLSTRING(Text_Full), LLSTRING(Text_Cba)], GVAR(exportMode), _theme, {
        params ["_index"];

        GVAR(exportMode) = _index;
        [GVAR(step)] call FUNC(showStep);
    }
] call FUNC(uiSegmented);

private _variant = ["own", "full", "cba"] param [GVAR(exportMode), "own"];
private _own = _variant isEqualTo "own";
private _editing = _own && {GVAR(textEdit)};
private _shown = [_variant] call FUNC(exportText);

// The own rules can be typed into once Edit text is pressed. What is typed is kept through redraws until
// it is applied, or the draft changes some other way.
if (_own) then {
    GVAR(rawShown) = _shown;

    if (GVAR(rawText) isNotEqualTo "") then {
        _shown = GVAR(rawText);
    };
};

private _noteH = UNIT * 0.8;
private _textButtonsY = _textBottom - _buttonH;
private _noteY = _textButtonsY - UNIT * 0.2 - _noteH;
private _areaTop = _textTop + _segmentH + UNIT * 0.2;
private _areaH = (_noteY - UNIT * 0.15) - _areaTop;

private _area = [_display, _group, [_cardX, _areaTop, _cardW, _areaH], _shown, "", _theme, {
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
}, [], true, _editing] call FUNC(uiEdit);

uiNamespace setVariable [QGVAR(textArea), _area select (count _area - 1)];

// Under it: what the text is for - or that what was typed is not used yet - and how long it is: the own
// rules as saved, or what was typed into them and not applied yet. As wide as the longest the box takes.
private _chars = count ([_shown, GVAR(draftText)] select (_own && {GVAR(rawText) isEqualTo ""}));
private _countW = ((format [LLSTRING(Text_Chars), 88888]) getTextWidth [_font, TEXT_SMALL]) * TEXT_SLACK;

private _countCtrl = [
    _display, _group, [_cardX + _cardW - _countW, _noteY, _countW, _noteH], format [LLSTRING(Text_Chars), _chars], TEXT_SMALL,
    [_muted, _loss] select (_own && {_chars > TEXT_MAX}), _font, 1
] call EFUNC(gui,uiLabel);

private _unapplied = _own && {GVAR(rawText) isNotEqualTo ""} && {GVAR(rawText) isNotEqualTo GVAR(rawShown)};
private _noteText = switch (true) do {
    case (_variant isEqualTo "full"): {LLSTRING(Text_FullNote)};
    case (_variant isEqualTo "cba"): {LLSTRING(Text_CbaNote)};
    case (_unapplied): {LLSTRING(Text_Unapplied)};
    case (_editing): {LLSTRING(Text_OwnNote)};
    default {LLSTRING(Text_OwnRead)};
};
private _noteW = _cardW - _countW - _buttonGap;

private _note = [
    _display, _group, [_cardX, _noteY, _noteW, _noteH], [_noteText, _noteW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL,
    [_muted, _accent] select _unapplied, _font, 0
] call EFUNC(gui,uiLabel);

_note ctrlSetTooltip _noteText;

if (_editing) then {
    uiNamespace setVariable [QGVAR(rawState), _note];
    uiNamespace setVariable [QGVAR(rawCount), _countCtrl];
};

// Edit text, or - typing - Apply text and Cancel; Copy where the game lets a script copy.
private _buttons = [];

if (_own && {!_editing}) then {
    _buttons pushBack [LLSTRING(Text_Edit), {
        GVAR(textEdit) = true;

        [GVAR(step)] call FUNC(showStep);
        ctrlSetFocus (uiNamespace getVariable [QGVAR(textArea), controlNull]);
    }, ""];
};

if (_editing) then {
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

        GVAR(textEdit) = false;

        [_ast] call FUNC(commit);
        [format [LLSTRING(Text_Applied), _count], ["gain", "accent"] select (_count > 0)] call FUNC(setHint);
    }, "accent"];

    _buttons pushBack [LLSTRING(Cancel), {
        GVAR(rawText) = "";
        GVAR(textEdit) = false;

        [GVAR(step)] call FUNC(showStep);
    }, "ghost"];
};

if (isServer || {!isMultiplayer}) then {
    _buttons pushBack [LLSTRING(Text_Copy), {
        copyToClipboard ctrlText (uiNamespace getVariable [QGVAR(textArea), controlNull]);
        [LLSTRING(Text_Copied), "gain"] call FUNC(setHint);
    }, ""];
};

private _textButtonX = _cardX;

{
    _x params ["_label", "_code", "_style"];

    private _buttonW = ACTION_W(_label,_buttonH,false,_font) max _minW;

    [_display, _group, [_textButtonX, _textButtonsY, _buttonW, _buttonH], _label, "", _theme, _code, [], true, _style] call FUNC(uiAction);

    _textButtonX = _textButtonX + _buttonW + _buttonGap;
} forEach _buttons;
