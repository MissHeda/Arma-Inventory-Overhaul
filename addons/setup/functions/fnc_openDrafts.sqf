#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the player's saved drafts (fnc_personalPresets): setups kept under a name in their profile, for any mission
 * and any server - also for players who may not save the server's setup, so they can keep one they like or one they
 * worked out to hand to their admin. A draft keeps the rules and the server settings together. Pick one to load it
 * (an undo step; Save is still to come) or delete it, or keep the setup as it is now under a name - one of the same
 * name is replaced. Shown as drafts, never as presets: there is one preset, the default.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Screen rectangle of what opened it - the box goes below it - or [] for the middle <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, [0.5, 0.5, 0.1, 0.03]] call einv_setup_fnc_openDrafts;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_anchor", [], [[]]]];

uiNamespace setVariable [QGVAR(draftsAnchor), _anchor];

[_display, _anchor, [SQUARE(UNIT * 26), UNIT * 8.6], format ["%1 (%2)", LLSTRING(Drafts_Title), count (["list"] call FUNC(personalPresets))], {
    params ["_display", "_inner", "_theme"];

    (ctrlPosition _inner) params ["", "", "_width", "_height"];

    private _font = _theme getOrDefault ["font", "PuristaMedium"];
    private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
    private _gap = SQUARE(UNIT * 0.3);
    private _buttonH = UNIT * 1.15;
    private _minW = SQUARE(UNIT * 4.5);
    private _drafts = ["list"] call FUNC(personalPresets);

    if ((_drafts findIf {(_x select 0) == GVAR(draftPick)}) < 0) then {
        GVAR(draftPick) = "";
    };

    private _picked = GVAR(draftPick) isNotEqualTo "";
    private _helpH = [_display, _inner, [0, 0, _width], LLSTRING(Drafts_Help), TEXT_SMALL, _muted, _font] call FUNC(uiText);
    private _rowY = _helpH + UNIT * 0.4;

    // Pick one, load it or delete it.
    private _loadW = ACTION_W(LLSTRING(Drafts_Load),_buttonH,false,_font) max _minW;
    private _deleteW = ACTION_W(LLSTRING(Drafts_Delete),_buttonH,false,_font) max _minW;
    private _dropW = _width - _loadW - _deleteW - _gap * 2;

    [
        _display, _inner, [0, _rowY, _dropW, _buttonH], _drafts apply {[format ["%1   %2", _x select 0, _x select 2], _x select 0]},
        GVAR(draftPick), _theme, {
            params ["_name"];

            GVAR(draftPick) = _name;

            [uiNamespace getVariable [QGVAR(display), displayNull], uiNamespace getVariable [QGVAR(draftsAnchor), []]] call FUNC(openDrafts);
        }, [], _drafts isNotEqualTo [], [LLSTRING(Drafts_Pick), LLSTRING(Drafts_None)] select (_drafts isEqualTo [])
    ] call FUNC(uiDropdown);

    [_display, _inner, [_dropW + _gap, _rowY, _loadW, _buttonH], LLSTRING(Drafts_Load), "", _theme, {
        private _draft = (["list"] call FUNC(personalPresets)) select {(_x select 0) == GVAR(draftPick)};

        if (_draft isEqualTo []) exitWith {};

        (_draft select 0) params ["_name", "_text"];

        // The rules, and after the mark the server settings that were kept with them.
        private _at = _text find DRAFT_SETTINGS_MARKER;
        private _rules = [_text, _text select [0, _at]] select (_at >= 0);
        private _settings = [_text select [_at + count DRAFT_SETTINGS_MARKER], ""] select (_at < 0);

        call FUNC(closePopover);

        [[_rules] call EFUNC(items,parseRules), ([_settings] call EFUNC(main,parseSettings)) select 0] call FUNC(commitSetup);
        [format [LLSTRING(Drafts_Loaded), _name], "gain"] call FUNC(setHint);
    }, [], _picked] call FUNC(uiAction);

    [_display, _inner, [_dropW + _gap + _loadW + _gap, _rowY, _deleteW, _buttonH], LLSTRING(Drafts_Delete), "", _theme, {
        private _name = GVAR(draftPick);

        if (_name isEqualTo "") exitWith {};

        [uiNamespace getVariable [QGVAR(display), displayNull], format [LLSTRING(Drafts_DeleteConfirm), _name], LLSTRING(Drafts_Delete), {
            params ["_name"];

            ["delete", _name] call FUNC(personalPresets);
            GVAR(draftPick) = "";

            [format [LLSTRING(Drafts_Deleted), _name], "text2"] call FUNC(setHint);
        }, [_name]] call FUNC(confirm);
    }, [], _picked, "danger"] call FUNC(uiAction);

    // Keep the setup as it is now, under a name.
    private _keepY = _height - _buttonH;
    private _keepW = ACTION_W(LLSTRING(Drafts_Keep),_buttonH,false,_font) max _minW;

    private _fnc_keep = {
        private _name = trim ctrlText (uiNamespace getVariable [QGVAR(draftEdit), controlNull]);

        if (_name isEqualTo "") exitWith {
            [LLSTRING(Drafts_NeedName), "loss"] call FUNC(setHint);
        };

        // Rules, and the server settings behind the mark when there are any.
        private _text = GVAR(draftText);

        if (GVAR(draftSettingsText) isNotEqualTo "") then {
            _text = _text + toString [10] + DRAFT_SETTINGS_MARKER + GVAR(draftSettingsText);
        };

        ["save", _name, _text] call FUNC(personalPresets);
        GVAR(draftPick) = _name;

        [uiNamespace getVariable [QGVAR(display), displayNull], uiNamespace getVariable [QGVAR(draftsAnchor), []]] call FUNC(openDrafts);
        [format [LLSTRING(Drafts_Saved), _name], "gain"] call FUNC(setHint);
    };

    private _field = [_display, _inner, [0, _keepY, _width - _keepW - _gap, _buttonH], GVAR(draftPick), LLSTRING(Drafts_Name), _theme, {
        params ["", "_submitted", "_arguments"];

        if (_submitted) then {
            call (_arguments select 0);
        };
    }, [_fnc_keep]] call FUNC(uiEdit);

    uiNamespace setVariable [QGVAR(draftEdit), _field select (count _field - 1)];

    [_display, _inner, [_width - _keepW, _keepY, _keepW, _buttonH], LLSTRING(Drafts_Keep), "", _theme, _fnc_keep, [], true, "accent"] call FUNC(uiAction);
}] call FUNC(popover);
