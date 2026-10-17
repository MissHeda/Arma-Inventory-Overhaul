#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The rows under the tools of the Blocks way (fnc_drawCellBlocks) and of the Paint way (fnc_drawCellEditor): what the picked compartment takes.
 *   - "Accepts": a chip for All and one for each category (weapon, ammo, grenade, gear, medical, food, tool, misc and the ones the draft
 *     defines). With All on, the
 *     compartment takes anything, as every compartment does until it is locked; one or more categories on, only items in one of
 *     them go in - a vest's front pouches for magazines, its back for grenades. A click on All takes the lock away, a click on a
 *     category adds it or takes it out; the last one taken out is All again. An item is in the categories of the Category row of
 *     the Items step (cats=), else its built-in one.
 *   - "One item, any size": a chip for the single slot. The compartment then holds one item of its categories whatever the item's
 *     size, and the item takes the whole compartment - a 1x1 grenade loop takes a 2x2 grenade and draws it scaled into the slot.
 * The changes go into the working copy of the class (GVAR(cellWork)), made on the first one, and the editor is drawn again.
 *
 * On the Paint way (uiNamespace QGVAR(paintCanvas) holds the painted canvas, which the editor sets each time it is drawn; empty on the
 * Blocks way) a row of its own comes first: "Compartment 2 / 5", a stepper through the compartments of the canvas in reading order
 * (GVAR(cellPick) keeps the picked one as its places), and the chip "Select on canvas", which makes a click on the canvas pick the
 * compartment it hits instead of painting (GVAR(cellBrush) -1). The attributes are kept in the canvas (fnc_canvasBlocks, "attrs"),
 * tied to the places of the compartment, so they follow it through repainting.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The editor's group <CONTROL>
 * 2: Position [x, y, w], relative to the group <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: Class <STRING>
 * 5: Compartments shown, as the working copy keeps them (fnc_cellBlock) <ARRAY>
 * 6: Index of the picked one <NUMBER>
 *
 * Return Value:
 * The height the rows took <NUMBER>
 *
 * Example:
 * [_display, _box, [0, 0.2, 0.4], _theme, "V_PlateCarrier1_rgr", _shown, 0] call einv_setup_fnc_drawCellAttrs;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", ["_theme", createHashMap, [createHashMap]], ["_class", "", [""]], ["_shown", [], [[]]], ["_picked", 0, [0]]];
_rect params ["_left", "_top", "_width"];

private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _gap = SQUARE(UNIT * 0.3);
private _rowH = UNIT * 1.1;
private _chipH = UNIT * 0.9;
private _labelW = SQUARE(UNIT * 5.6);
private _block = _shown param [_picked, [1, 1, []]];
private _accepts = _block param [4, []];
private _single = _block param [5, false];

// The working copy of the class, made from what is shown the first time something changes.
private _fnc_change = {
    params ["_class", "_shown", "_picked", "_accepts", "_single"];

    private _lc = toLowerANSI _class;
    private _canvas = uiNamespace getVariable [QGVAR(paintCanvas), createHashMap];

    // The Paint way: the lock belongs to the places of the compartment picked, kept in the canvas.
    if (count _canvas > 0) exitWith {
        private _places = (_canvas getOrDefault ["parts", []]) param [_picked, []];

        if (_places isEqualTo []) exitWith {};

        if !(_lc in GVAR(cellWork)) then {
            GVAR(cellWork) set [_lc, _canvas];
        };

        private _attrs = (_canvas getOrDefault ["attrs", []]) select {(_x select 0) isNotEqualTo _places};

        if (_accepts isNotEqualTo [] || {_single}) then {
            _attrs pushBack [+_places, _accepts, _single];
        };

        _canvas set ["attrs", _attrs];

        [] call FUNC(drawCellEditor);
    };

    private _work = GVAR(cellWork) getOrDefault [_lc, createHashMap];

    if (count _work == 0) then {
        _work = createHashMapFromArray [["blocks", +_shown], ["picked", _picked]];
        GVAR(cellWork) set [_lc, _work];
    };

    private _blocks = _work get "blocks";

    if (_picked < count _blocks) then {
        _blocks set [_picked, [_blocks select _picked, _accepts, _single] call FUNC(cellBlock)];
    };

    _work set ["picked", _picked];

    [] call FUNC(drawCellEditor);
};

// The Paint way: which compartment, by number or by a click on the canvas.
private _rowsTop = _top;
private _paint = count (uiNamespace getVariable [QGVAR(paintCanvas), createHashMap]) > 0;

if (_paint) then {
    private _pickW = SQUARE(UNIT * 9);

    [
        _display, _parent, [_left, _rowsTop + (_rowH - _chipH) / 2, _pickW, _chipH], _picked + 1, [1, count _shown, 1], _theme, {
            params ["_value", "_arguments"];
            _arguments params ["_class"];

            private _canvas = uiNamespace getVariable [QGVAR(paintCanvas), createHashMap];
            private _places = (_canvas getOrDefault ["parts", []]) param [_value - 1, []];

            GVAR(cellPick) set [toLowerANSI _class, +_places];

            [] call FUNC(drawCellEditor);
        }, [_class], format [LLSTRING(Cont_Picked), "%1", count _shown], true, LLSTRING(Cont_PaintStepTip)
    ] call FUNC(uiStepper);

    private _selectText = LLSTRING(Cont_PaintSelect);
    private _selectW = SQUARE(_chipH * 0.9) + (_selectText getTextWidth [_fontBold, _chipH * 0.52]) * TEXT_SLACK;

    [_display, _parent, [_left + _pickW + _gap, _rowsTop + (_rowH - _chipH) / 2, _selectW, _chipH], _selectText, GVAR(cellBrush) < 0, _theme, {
        params ["_state"];

        GVAR(cellBrush) = [1, -1] select _state;

        [] call FUNC(drawCellEditor);
    }] call FUNC(uiChip);

    _rowsTop = _rowsTop + _rowH;
};

[_display, _parent, [_left, _rowsTop, _labelW, _rowH], LLSTRING(Cont_Accepts), TEXT_SMALL, _colorText2, _fontBold, 0] call EFUNC(gui,uiLabel);

private _chipX = _left + _labelW;
private _lineY = _rowsTop;

// All, then the categories.
{
    private _group = _x;
    private _text = [(([_group, GVAR(draftRules)] call EFUNC(items,categoryInfo)) get "name"), LLSTRING(Cont_AcceptsAll)] select (_group isEqualTo "");
    private _chipW = SQUARE(_chipH * 0.9) + (_text getTextWidth [_fontBold, _chipH * 0.52]) * TEXT_SLACK;

    if (_chipX + _chipW > _left + _width && {_chipX > _left + _labelW}) then {
        _chipX = _left + _labelW;
        _lineY = _lineY + _rowH;
    };

    private _on = [_group in _accepts, _accepts isEqualTo []] select (_group isEqualTo "");

    [_display, _parent, [_chipX, _lineY + (_rowH - _chipH) / 2, _chipW, _chipH], _text, _on, _theme, {
        params ["_state", "_arguments"];
        _arguments params ["_group", "_class", "_shown", "_picked", "_accepts", "_single", "_change"];

        private _list = if (_group isEqualTo "") then {
            []
        } else {
            ([_accepts - [_group], _accepts + [_group]] select _state)
        };

        [_class, _shown, _picked, [_list] call EFUNC(items,orderGroups), _single] call _change;
    }, [_group, _class, _shown, _picked, _accepts, _single, _fnc_change]] call FUNC(uiChip);

    _chipX = _chipX + _chipW + _gap;
} forEach ([""] + ([GVAR(draftRules)] call EFUNC(items,categories)));

_lineY = _lineY + _rowH;

// A single slot.
[_display, _parent, [_left, _lineY, _labelW, _rowH], LLSTRING(Cont_Single), TEXT_SMALL, _colorText2, _fontBold, 0] call EFUNC(gui,uiLabel);

private _singleText = LLSTRING(Cont_SingleChip);
private _singleW = SQUARE(_chipH * 0.9) + (_singleText getTextWidth [_fontBold, _chipH * 0.52]) * TEXT_SLACK;

[_display, _parent, [_left + _labelW, _lineY + (_rowH - _chipH) / 2, _singleW, _chipH], _singleText, _single, _theme, {
    params ["_state", "_arguments"];
    _arguments params ["_class", "_shown", "_picked", "_accepts", "_change"];

    [_class, _shown, _picked, _accepts, _state] call _change;
}, [_class, _shown, _picked, _accepts, _fnc_change]] call FUNC(uiChip);

_lineY = _lineY + _rowH;

_lineY - _top
