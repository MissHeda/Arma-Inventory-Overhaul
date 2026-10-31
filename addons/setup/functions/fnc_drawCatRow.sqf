#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The row "Category" of the Items step: which categories the item is in - a chip each for weapon, ammo, grenade, gear,
 * medical, food, tool and misc (ITEM_GROUPS) and the ones the draft defines (General step), more than one on when it is in several
 * (cats=, aio_cat). The strip at the
 * side of a loot box shows an item under each of them, and a compartment that accepts only some categories (the Containers
 * step) takes it when it is in one of them. Like the Use from row, the chips are always clickable and nothing is written
 * here: the code gets the new list and puts it into the editor's working copy; Apply writes cats=. At least one stays on.
 * The row wraps onto a second line where the chips do not fit.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w], relative to the group <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: Width of the label at the left <NUMBER>
 * 5: The categories the working copy has, any category of the draft <ARRAY of STRING>
 * 6: Code, called with [new list, arguments] when a chip is clicked <CODE>
 * 7: Arguments <ANY> (default: [])
 *
 * Return Value:
 * The height the row took <NUMBER>
 *
 * Example:
 * [_display, _box, [0, 0, 0.4], _theme, 0.08, ["medical"], {params ["_list"]}] call aio_setup_fnc_drawCatRow;
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
private _gap = SQUARE(UNIT * 0.3);
private _rowH = UNIT * 1.1;
private _chipH = UNIT * 0.9;

[_display, _parent, [_left, _top, _labelW, _rowH], LLSTRING(Items_CatField), TEXT_SMALL, _colorText2, _fontBold, 0] call EFUNC(gui,uiLabel);

private _chipX = _left + _labelW;
private _lineY = _top;

{
    private _group = _x;
    private _text = ([_group, GVAR(draftRules)] call EFUNC(items,categoryInfo)) get "name";
    private _chipW = SQUARE(_chipH * 0.9) + (_text getTextWidth [_fontBold, _chipH * 0.52]) * TEXT_SLACK;

    // A chip that would reach past the row starts the next line, under the first chip.
    if (_chipX + _chipW > _left + _width && {_chipX > _left + _labelW}) then {
        _chipX = _left + _labelW;
        _lineY = _lineY + _rowH;
    };

    [_display, _parent, [_chipX, _lineY + (_rowH - _chipH) / 2, _chipW, _chipH], _text, _group in _work, _theme, {
        params ["_on", "_arguments"];
        _arguments params ["_group", "_work", "_code", "_codeArguments"];

        // In the order they are stored in, whatever order they were clicked in; the last one on cannot be switched off.
        private _list = ([_work - [_group], _work + [_group]] select _on);

        if (_list isEqualTo []) exitWith {
            [LLSTRING(Hint_CatOne), "text2"] call FUNC(setHint);
            [_work, _codeArguments] call _code;
        };

        [[_list] call EFUNC(items,orderGroups), _codeArguments] call _code;
    }, [_group, _work, _code, _arguments]] call FUNC(uiChip);

    _chipX = _chipX + _chipW + _gap;
} forEach ([GVAR(draftRules)] call EFUNC(items,categories));

_lineY - _top + _rowH
