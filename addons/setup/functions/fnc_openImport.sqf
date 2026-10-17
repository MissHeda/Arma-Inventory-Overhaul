#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the box to import a shared setup: paste a rules text or lines of a cba_settings.sqf into it with
 * Ctrl+V - a paste box, as CBA's own Import is one: it works for every player, where a script reading the
 * clipboard would not -, then take it instead of the own setup, or add its statements to the own ones
 * (fnc_importText). The lines of a cba_settings.sqf or CBA's Export may carry the server settings as well
 * (einv_main_settings, fnc_importSettings): added, the settings the text names are set and the others stay;
 * instead of the own setup, the ones it does not name go back to their defaults. Either way it only changes the
 * draft, rules and settings in one undo step: Save is still to come, and Undo takes it back.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Screen rectangle of what opened it - the box goes below it - or [] for the middle <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, [0.5, 0.5, 0.1, 0.03]] call einv_setup_fnc_openImport;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_anchor", [], [[]]]];

[_display, _anchor, [SQUARE(UNIT * 24), UNIT * 11], LLSTRING(Import_Title), {
    params ["_display", "_inner", "_theme"];

    (ctrlPosition _inner) params ["", "", "_width", "_height"];

    private _helpH = [_display, _inner, [0, 0, _width], LLSTRING(Import_Help), TEXT_BODY, _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]], _theme getOrDefault ["font", "PuristaMedium"]] call FUNC(uiText);
    private _buttonH = UNIT * 1.2;
    private _boxTop = _helpH + UNIT * 0.35;
    private _boxH = _height - _boxTop - _buttonH - UNIT * 0.45;

    private _box = [_display, _inner, [0, _boxTop, _width, _boxH], GVAR(importText), LLSTRING(Import_Placeholder), _theme, {
        params ["_text"];

        GVAR(importText) = _text;
    }, [], true, true] call FUNC(uiEdit);

    ctrlSetFocus (_box select (count _box - 1));

    // Both read the box as it is now, not the last change reported.
    private _fnc_take = {
        params ["_add"];

        private _edit = uiNamespace getVariable [QGVAR(importEdit), controlNull];

        if (!isNull _edit) then {
            GVAR(importText) = ctrlText _edit;
        };

        private _ast = [GVAR(importText)] call FUNC(importText);
        private _settingsText = [GVAR(importText)] call FUNC(importSettings);
        private _hasSettings = _settingsText isNotEqualTo "";

        if (count _ast == 0 && {!_hasSettings}) exitWith {
            [LLSTRING(Import_Nothing), "loss"] call FUNC(setHint);
        };

        // Too long to be a setup: the box stays open with the text in it, to be shortened.
        if ("tooLong" in _ast) exitWith {
            [format [LLSTRING(Warning_TooLong), _ast get "tooLong"], "loss"] call FUNC(setHint);
        };

        private _imported = [[], []];
        private _warnings = [];

        if (count _ast > 0) then {
            _imported = [[_ast] call EFUNC(items,writeRules)] call FUNC(statements);
            _warnings = _ast getOrDefault ["warnings", []];

            if (_add) then {
                // The own header stays; what the import says that the own rules do not, joins them.
                ([GVAR(draftText)] call FUNC(statements)) params ["_head", "_statements"];

                private _text = (([_head] + _statements + ((_imported select 1) - _statements)) select {_x isNotEqualTo ""}) joinString ", ";

                // Together too long: the engine would read it as the bare default.
                if (count _text > TEXT_MAX) exitWith {
                    _ast = createHashMapFromArray [["tooLong", count _text]];
                };

                private _merged = [_text] call EFUNC(items,parseRules);

                _merged set ["warnings", +_warnings];
                _ast = _merged;
            };
        };

        if ("tooLong" in _ast) exitWith {
            [format [LLSTRING(Warning_TooLong), _ast get "tooLong"], "loss"] call FUNC(setHint);
        };

        // The server settings: set on top of the own ones, or instead of them.
        private _values = nil;
        private _count = 0;

        if (_hasSettings) then {
            ([_settingsText] call EFUNC(main,parseSettings)) params ["_named", "_settingWarnings"];

            _warnings = _warnings + _settingWarnings;
            _count = count _named;
            _values = [createHashMap, +GVAR(draftSettings)] select _add;
            _values merge [_named, true];
        };

        call FUNC(closePopover);

        [_ast, _values] call FUNC(commitSetup);

        GVAR(importText) = "";

        [
            format [LLSTRING(Import_Done), count (_imported select 1), _count, count _warnings],
            ["gain", "accent"] select (_warnings isNotEqualTo [])
        ] call FUNC(setHint);
    };

    uiNamespace setVariable [QGVAR(importEdit), _box select (count _box - 1)];

    private _buttonW = (_width - SQUARE(UNIT * 0.3)) / 2;
    private _buttonY = _height - _buttonH;

    [_display, _inner, [0, _buttonY, _buttonW, _buttonH], LLSTRING(Import_Add), "", _theme, _fnc_take, [true]] call FUNC(uiAction);
    [_display, _inner, [_width - _buttonW, _buttonY, _buttonW, _buttonH], LLSTRING(Import_Replace), "", _theme, _fnc_take, [false], true, "accent"] call FUNC(uiAction);
}, [], [], "import"] call FUNC(popover);
