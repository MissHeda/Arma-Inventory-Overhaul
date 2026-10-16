#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The row "Use from" of the Items step: which containers the item may be used from even where a setting
 * closes them - a chip each for the uniform, vest and backpack, on for the ones it is whitelisted for
 * (use=, einv_use). Under it one line of what the settings "Use items from ..." (einv_storage_useUniform,
 * einv_storage_useVest, einv_storage_useBackpack) limit right now, so a chip is read in the light of it:
 * with a container on Everything its chip changes nothing in the game, and with one on Nothing even a
 * whitelisted item is not usable there. The chips are always clickable - the rule belongs to the item, not
 * to the settings of this mission - and nothing is written here: the code gets the new list and puts it
 * into the editor's working copy; Apply writes use=.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w], relative to the group <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: Width of the label at the left <NUMBER>
 * 5: The containers the working copy whitelists, any of "uniform", "vest", "backpack" <ARRAY of STRING>
 * 6: Code, called with [new list, arguments] when a chip is clicked <CODE>
 * 7: Arguments <ANY> (default: [])
 *
 * Return Value:
 * The height the row and its line took <NUMBER>
 *
 * Example:
 * [_display, _box, [0, 0, 0.4], _theme, 0.08, ["backpack"], {params ["_list"]}] call einv_setup_fnc_drawUseRow;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_theme", createHashMap, [createHashMap]], ["_labelW", 0, [0]], ["_work", [], [[]]],
    ["_code", {}, [{}]], ["_arguments", []]
];
_rect params ["_left", "_top", "_width"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _gap = SQUARE(UNIT * 0.3);
private _rowH = UNIT * 1.1;
private _chipH = UNIT * 0.9;

[_display, _parent, [_left, _top, _labelW, _rowH], LLSTRING(Items_UseField), TEXT_SMALL, _colorText2, _fontBold, 0] call EFUNC(gui,uiLabel);

private _chipX = _left + _labelW;

{
    private _kind = _x;
    private _text = localize format ["STR_einv_setup_Use_%1", _kind];
    private _chipW = SQUARE(_chipH * 0.9) + (_text getTextWidth [_fontBold, _chipH * 0.52]) * TEXT_SLACK;

    [_display, _parent, [_chipX, _top + (_rowH - _chipH) / 2, _chipW, _chipH], _text, _kind in _work, _theme, {
        params ["_on", "_arguments"];
        _arguments params ["_kind", "_work", "_code", "_codeArguments"];

        // In the order the rules write them, whatever order they were clicked in.
        private _list = ([_work - [_kind], _work + [_kind]] select _on);

        [USE_KINDS select {_x in _list}, _codeArguments] call _code;
    }, [_kind, _work, _code, _arguments]] call FUNC(uiChip);

    _chipX = _chipX + _chipW + _gap;
} forEach USE_KINDS;

// What the settings limit now.
private _limited = [];

{
    private _mode = [_x] call EFUNC(storage,useMode);

    if (_mode isNotEqualTo USE_ALL) then {
        _limited pushBack format [
            [LLSTRING(Use_PartList), LLSTRING(Use_PartNone)] select (_mode isEqualTo USE_NONE), localize format ["STR_einv_setup_Use_%1", _x]
        ];
    };
} forEach USE_KINDS;

private _line = if (_limited isEqualTo []) then {
    LLSTRING(Use_NoneLimited)
} else {
    format [LLSTRING(Use_Limited), _limited joinString ", "]
};

private _lineH = [_display, _parent, [_left + _labelW, _top + _rowH, _width - _labelW], _line, TEXT_SMALL, _muted, _font] call FUNC(uiText);

_rowH + _lineH
