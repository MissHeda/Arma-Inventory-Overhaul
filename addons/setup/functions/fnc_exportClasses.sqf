#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Export at the editors of the Items and Containers steps, in one of two ways (the editor asks which,
 * fnc_openExportChoice):
 *
 * "config" - the config lines that give the class what the draft makes of it, ready to paste into a mod's
 * config (einv_items_fnc_configEntry):
 *
 *   class CfgVehicles { class B_Carryall_blk { einv_grid = "1x3+5x7+1x3"; }; };
 *
 * For an edit of a whole tree, one line per class of the tree that the step lists. They are worked out from
 * the draft, not from what is saved, so a design made here can be exported before Save. A class the draft
 * leaves as the game already has it gets no line.
 *
 * "layout" - the values alone, without the class, as one short line that starts with LAYOUT_MARKER and is
 * meant to be shared: what the draft makes of the class that differs from the game (grid, size, stack,
 * weight, name, icon, picture, use), written as a rule's values (einv_items_fnc_writeRules):
 *
 *   einv-layout: grid=1x3+5x7+1x3 weight=1.2 picture=/a3/ui_f/data/igui/cfg/simpletasks/types/backpack_ca.paa
 *
 * Whoever imports it applies it to the class they have selected (fnc_importClasses), so it works across
 * mods and never names a class the other player may not have. Always the class alone - a layout has no
 * tree.
 *
 * The lines go to the clipboard where the game lets a script write there - on the server and alone, as at the
 * setup's Export -; anyone else gets a box with the text, to select and copy by hand.
 *
 * Arguments:
 * 0: Step: "items" or "containers" <STRING>
 * 1: Class <STRING>
 * 2: The edit is for the class and everything built on it <BOOL> (default: false)
 * 3: "config" or "layout" <STRING> (default: "config")
 *
 * Return Value:
 * The text <STRING>
 *
 * Example:
 * ["containers", "B_Carryall_blk"] call einv_setup_fnc_exportClasses;
 *
 * Public: No
 */

disableSerialization;

params [["_mode", "items", [""]], ["_class", "", [""]], ["_tree", false, [false]], ["_format", "config", [""]]];

private _layout = _format isEqualTo "layout";
private _classes = [_class];

if (_tree && {!_layout}) then {
    _classes = ((([_class, _mode] call FUNC(treeRows)) getOrDefault ["rows", []])) apply {_x select 1};

    if (_classes isEqualTo []) then {
        _classes = [_class];
    };
};

// Without the rules engine's own writer: every key the draft has an answer for, as it writes them.
private _fnc_lines = {
    params ["_class"];

    private _facts = [_class] call EFUNC(items,getFacts);
    private _root = _facts getOrDefault ["root", ""];

    if (_root isEqualTo "") exitWith {""};

    private _info = [_class, GVAR(draftRules)] call EFUNC(items,getInfo);
    private _kind = _info getOrDefault ["kind", ""];
    private _quote = """";
    private _lines = [];

    _lines pushBack format ["einv_size = %1%2%1;", _quote, _info getOrDefault ["shape", "1x1"]];

    if !(_kind in ["rifle", "handgun", "launcher", "binocular", "uniform", "vest", "backpack"]) then {
        _lines pushBack format ["einv_stack = %1;", _info getOrDefault ["stack", 1]];
    };

    if (_kind in CONTAINER_KINDS) then {
        _lines pushBack format ["einv_grid = %1%2%1;", _quote, [_info getOrDefault ["grid", ["auto"]]] call EFUNC(items,formatGrid)];
    };

    if ((_info getOrDefault ["weightOverride", -1]) >= 0) then {
        _lines pushBack format ["einv_weight = %1;", _info get "weightOverride"];
    };

    if ((_info getOrDefault ["nameOverride", ""]) isNotEqualTo "") then {
        _lines pushBack format ["einv_name = %1%2%1;", _quote, (_info get "nameOverride") regexReplace [_quote, _quote + _quote]];
    };

    private _icon = _info getOrDefault ["icon", [1, 0, 0]];

    if (_icon isNotEqualTo [1, 0, 0] && {!isNil QEFUNC(items,formatIcon)}) then {
        _lines pushBack format ["einv_icon = %1%2%1;", _quote, [_icon, ","] call EFUNC(items,formatIcon)];
    };

    private _picture = _info getOrDefault ["pictureOverride", ""];

    if (_picture isNotEqualTo "") then {
        _lines pushBack format ["einv_picture = %1%2%1;", _quote, _picture regexReplace [_quote, _quote + _quote]];
    };

    if ((_info getOrDefault ["use", []]) isNotEqualTo [] && {!isNil QEFUNC(items,formatUse)}) then {
        _lines pushBack format ["einv_use = %1%2%1;", _quote, [_info get "use", ","] call EFUNC(items,formatUse)];
    };

    if ((_info getOrDefault ["cats", []]) isNotEqualTo [] && {!isNil QEFUNC(items,formatGroups)}) then {
        _lines pushBack format ["einv_cat = %1%2%1;", _quote, [_info get "cats", ","] call EFUNC(items,formatGroups)];
    };

    format ["class %1 { class %2 { %3 }; };", _root, _facts getOrDefault ["class", _class], _lines joinString " "]
};

private _lines = [];

{
    private _line = if (isNil QEFUNC(items,configEntry)) then {
        [_x] call _fnc_lines
    } else {
        [_x, false, GVAR(draftRules)] call EFUNC(items,configEntry)
    };

    if (_line isNotEqualTo "") then {
        _lines pushBack _line;
    };
} forEach ([_classes, []] select _layout);

// A layout: the values of the class that differ from the game, without its name.
if (_layout) then {
    private _entry = [_class, false, GVAR(draftRules)] call EFUNC(items,configEntry);
    private _parsed = if (_entry isEqualTo "") then {[]} else {[_entry] call EFUNC(items,parseConfigEntry)};
    private _values = if (_parsed isEqualTo []) then {createHashMap} else {[(_parsed select 0) select 1] call FUNC(configValues)};

    if (count _values > 0) then {
        _lines pushBack (LAYOUT_MARKER + " " + ([createHashMapFromArray [["rules", [[[], _values]]]], false] call EFUNC(items,writeRules)));
    };
};

if (_lines isEqualTo []) exitWith {
    [[LLSTRING(Export_ClassNothing), LLSTRING(Export_LayoutNothing)] select _layout, "text2"] call FUNC(setHint);

    ""
};

private _text = _lines joinString toString [10];

// The game lets a script copy only on the server and alone: anyone else gets the lines to copy by hand.
if (isServer || {!isMultiplayer}) exitWith {
    copyToClipboard _text;

    if (_layout) then {
        [format [LLSTRING(Export_LayoutCopied), _class], "gain"] call FUNC(setHint);
    } else {
        [format [[LLSTRING(Export_ClassCopiedOne), LLSTRING(Export_ClassCopied)] select (count _lines != 1), count _lines], "gain"] call FUNC(setHint);
    };

    _text
};

[
    uiNamespace getVariable [QGVAR(display), displayNull], [], [SQUARE(UNIT * 28), UNIT * 12], [LLSTRING(Export_ClassTitle), LLSTRING(Export_LayoutTitle)] select _layout, {
        params ["_display", "_inner", "_theme", "_arguments"];
        _arguments params ["_text"];

        (ctrlPosition _inner) params ["", "", "_width", "_height"];

        private _helpH = [
            _display, _inner, [0, 0, _width], LLSTRING(Export_ClassByHand), TEXT_BODY,
            _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]], _theme getOrDefault ["font", "PuristaMedium"]
        ] call FUNC(uiText);
        private _buttonH = UNIT * 1.2;
        private _boxTop = _helpH + UNIT * 0.35;

        // Several lines that cannot be typed into but selected and copied (Ctrl+A, Ctrl+C).
        private _box = [
            _display, _inner, [0, _boxTop, _width, _height - _boxTop - _buttonH - UNIT * 0.45], _text, "", _theme, {}, [], true, false
        ] call FUNC(uiEdit);

        ctrlSetFocus (_box select (count _box - 1));

        private _closeW = SQUARE(UNIT * 6);

        [_display, _inner, [_width - _closeW, _height - _buttonH, _closeW, _buttonH], LLSTRING(Close), "", _theme, {
            call FUNC(closePopover);
        }, [], true, "accent"] call FUNC(uiAction);
    }, [_text], [], "exportClasses"
] call FUNC(popover);

_text
