#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the box that shows the setup as text, to copy and share: the own rules (short, and follows the default as the
 * mod improves it), the whole of them written out (so later versions cannot change it), or the lines for a
 * cba_settings.sqf or CBA's Import - the rules and one line for each server setting off its default
 * (fnc_exportText). One of the three is shown at a time, read only; the Copy button puts it on the clipboard where the
 * game lets a script do that (the server, single player, Eden), else the text is there to select (Ctrl+A) and copy
 * (Ctrl+C) by hand. What the box showed last - the line for a cba_settings.sqf the first time - stays picked.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Screen rectangle of what opened it - the box goes below it - or [] for the middle <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, [0.5, 0.5, 0.1, 0.03]] call aio_setup_fnc_openExport;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_anchor", [], [[]]]];

uiNamespace setVariable [QGVAR(exportAnchor), _anchor];

[_display, _anchor, [SQUARE(UNIT * 34), UNIT * 17], LLSTRING(Export_Title), {
    params ["_display", "_inner", "_theme"];

    (ctrlPosition _inner) params ["", "", "_width", "_height"];

    private _font = _theme getOrDefault ["font", "PuristaMedium"];
    private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
    private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
    private _gap = SQUARE(UNIT * 0.3);
    private _buttonH = UNIT * 1.2;
    private _segmentH = UNIT * 1;
    private _segmentW = (SQUARE(UNIT * 17)) min (_width * 0.55);
    private _variant = ["own", "full", "cba"] param [GVAR(exportMode), "cba"];
    private _shown = [_variant] call FUNC(exportText);
    private _canCopy = isServer || {!isMultiplayer};

    // Which text: the own rules, the whole setup written out, the lines for a cba_settings.sqf.
    private _helpH = [_display, _inner, [0, 0, _width - _segmentW - _gap], LLSTRING(Export_Help), TEXT_SMALL, _colorText2, _font] call FUNC(uiText);
    private _topH = _helpH max _segmentH;

    [
        _display, _inner, [_width - _segmentW, 0, _segmentW, _segmentH],
        [LLSTRING(Text_Own), LLSTRING(Text_Full), LLSTRING(Text_Cba)], GVAR(exportMode) min 2, _theme, {
            params ["_index"];

            GVAR(exportMode) = _index;

            [uiNamespace getVariable [QGVAR(display), displayNull], uiNamespace getVariable [QGVAR(exportAnchor), []]] call FUNC(openExport);
        }
    ] call FUNC(uiSegmented);

    private _noteH = UNIT * 0.8;
    private _buttonsY = _height - _buttonH;
    private _noteY = _buttonsY - UNIT * 0.2 - _noteH;
    private _areaY = _topH + UNIT * 0.3;
    private _areaH = (_noteY - UNIT * 0.15) - _areaY;

    private _area = [_display, _inner, [0, _areaY, _width, _areaH], _shown, "", _theme, {}, [], true, false] call FUNC(uiEdit);

    uiNamespace setVariable [QGVAR(textArea), _area select (count _area - 1)];

    // What the shown text is for, and how long it is.
    private _countW = ((format [LLSTRING(Text_Chars), 88888]) getTextWidth [_font, TEXT_SMALL]) * TEXT_SLACK;
    private _tooLong = count GVAR(draftText) > TEXT_MAX;

    [
        _display, _inner, [_width - _countW, _noteY, _countW, _noteH], format [LLSTRING(Text_Chars), count _shown], TEXT_SMALL,
        [_muted, _theme getOrDefault ["loss", _muted]] select _tooLong, _font, 1
    ] call EFUNC(gui,uiLabel);

    private _noteText = switch (_variant) do {
        case "full": {LLSTRING(Text_FullNote)};
        case "cba": {[LLSTRING(Export_ByHandCba), LLSTRING(Text_CbaNote)] select _canCopy};
        default {LLSTRING(Text_OwnRead)};
    };
    private _noteW = _width - _countW - _gap;

    private _note = [
        _display, _inner, [0, _noteY, _noteW, _noteH], [_noteText, _noteW, _font, TEXT_SMALL] call EFUNC(gui,fitText), TEXT_SMALL,
        _muted, _font, 0
    ] call EFUNC(gui,uiLabel);

    _note ctrlSetTooltip _noteText;

    if (_canCopy) then {
        private _copyW = ACTION_W(LLSTRING(Text_Copy),_buttonH,false,_font) max SQUARE(UNIT * 4.5);

        [_display, _inner, [0, _buttonsY, _copyW, _buttonH], LLSTRING(Text_Copy), "", _theme, {
            copyToClipboard ctrlText (uiNamespace getVariable [QGVAR(textArea), controlNull]);

            [LLSTRING(Text_Copied), "gain"] call FUNC(setHint);
        }, [], true, "accent"] call FUNC(uiAction);
    };
}, [], [], "export"] call FUNC(popover);
