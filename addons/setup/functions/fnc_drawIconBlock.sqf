#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The block that sets how large an item's picture is drawn and where (icon=, einv_items_fnc_parseIcon), for the
 * Items step (beside the tile it moves) and the Containers step (beside the box): a caption with Reset at its
 * end (back to the plain picture, enabled while it is not), the zoom (25 to 400 %) with a few common ones at
 * one click (50, 100, 150, 200 %), and two shift steppers, across and down (-100 to 100 % of the tile). Each
 * stepper steps 1 % (Shift and click 10 %) and has a small text box beside it (fnc_uiNumber) where an exact
 * number is typed, read on Return or when the cursor leaves it. ICON_BLOCK_H high.
 *
 * Nothing is kept here: every change calls the code with the new [zoom, across, down] in whole per cent, which puts
 * it into the editor's working copy and draws the editor again.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Top left corner and width [x, y, w], relative to the group <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: The picture now, [zoom, across, down] in per cent <ARRAY>
 * 5: Code, called with [[zoom, across, down], arguments] <CODE>
 * 6: Arguments <ANY> (default: [])
 *
 * Return Value:
 * Height taken <NUMBER>
 *
 * Example:
 * [_display, _box, [0, 0, 0.3], _theme, [100, 0, 0], {params ["_icon"]}] call einv_setup_fnc_drawIconBlock;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_where", ["_theme", createHashMap, [createHashMap]], ["_work", [100, 0, 0], [[]]], ["_code", {}, [{}]], ["_arguments", []]
];
_where params ["_pictureX", "_pictureY", "_pictureW"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _gap = SQUARE(UNIT * 0.3);
private _stepH = UNIT * 1.0;
private _stepGap = UNIT * 0.28;
private _captionH = UNIT * 0.9;
private _top = _pictureY;

// A stepper or a text box sets one of the three numbers.
private _setIcon = {
    params ["_value", "_pack"];
    _pack params ["_work", "_which", "_code", "_arguments"];

    private _new = +_work;

    _new set [_which, _value];

    [_new, _arguments] call _code;
};

// A chip sets all three at once: a common zoom, or back to the plain picture.
private _putIcon = {
    params ["", "_pack"];
    _pack params ["_new", "_code", "_arguments"];

    [_new, _arguments] call _code;
};

// What a chip of this text needs: its padding (0.45 of its height each side) and the label with fitText's slack.
private _fnc_chipWidth = {
    params ["_text", "_chipH"];

    SQUARE(_chipH * 0.9) + (_text getTextWidth [_fontBold, _chipH * 0.52]) * TEXT_SLACK
};

// What a stepper needs to show its widest value: its two buttons and the label with the slack.
private _fnc_stepperWidth = {
    params ["_format", "_widest"];

    SQUARE(_stepH) * 2 + ((format [_format, _widest, "%"]) getTextWidth [_fontBold, _stepH * 0.52]) * TEXT_SLACK + SQUARE(_stepH * 0.3)
};

// One number of the three: a stepper (1 per click, 10 with Shift) with its text box after it, the stepper
// _stepperW wide and the box _numberW.
private _numberW = SQUARE(UNIT * 2.3);
private _fnc_number = {
    params ["_atX", "_atY", "_stepperW", "_which", "_range", "_format"];

    [
        _display, _parent, [_atX, _atY, _stepperW, _stepH], _work select _which, _range + [1, 10], _theme,
        _setIcon, [_work, _which, _code, _arguments], _format, true, LLSTRING(Items_PictureStepTip)
    ] call FUNC(uiStepper);

    [
        _display, _parent, [_atX + _stepperW + _gap, _atY, _numberW, _stepH], _work select _which, _range, _theme,
        _setIcon, [_work, _which, _code, _arguments], LLSTRING(Items_PictureTypeTip)
    ] call FUNC(uiNumber);
};

// The caption, and Reset at its end.
private _resetText = LLSTRING(Items_PictureReset);
private _resetH = _captionH * 0.9;
private _resetW = [_resetText, _resetH] call _fnc_chipWidth;

[_display, _parent, [_pictureX, _pictureY, _pictureW - _resetW - _gap, _captionH], LLSTRING(Items_PictureLook), TEXT_SMALL, _colorText2, _fontBold, 0] call EFUNC(gui,uiLabel);

[
    _display, _parent, [_pictureX + _pictureW - _resetW, _pictureY + (_captionH - _resetH) / 2, _resetW, _resetH], _resetText, false, _theme, _putIcon,
    [+ICON_PERCENT_PLAIN, _code, _arguments], _work isNotEqualTo ICON_PERCENT_PLAIN
] call FUNC(uiChip);

_pictureY = _pictureY + _captionH + _stepGap;

// The zoom with its text box, and a few common ones at one click - the stepper alone would take long from 100
// to 400. The stepper takes what the chips leave, at least what its label needs and at most 0.4 of the block.
private _zoomChipH = _stepH * 0.9;
private _zoomChipGap = SQUARE(UNIT * 0.2);
private _zoomChips = [50, 100, 150, 200];
private _chipsW = _gap * 2 - _zoomChipGap;

{
    _chipsW = _chipsW + ([str _x, _zoomChipH] call _fnc_chipWidth) + _zoomChipGap;
} forEach _zoomChips;

private _zoomW = (([LLSTRING(Items_PictureZoom), 400] call _fnc_stepperWidth) max (_pictureW - _numberW - _chipsW)) min (_pictureW * 0.4);

[_pictureX, _pictureY, _zoomW, 0, [round (ICON_SCALE_MIN * 100), round (ICON_SCALE_MAX * 100)], LLSTRING(Items_PictureZoom)] call _fnc_number;

private _zoomChipX = _pictureX + _zoomW + _gap + _numberW + _gap;

{
    private _chipW = [str _x, _zoomChipH] call _fnc_chipWidth;

    if (_zoomChipX + _chipW > _pictureX + _pictureW + pixelW) exitWith {};

    [_display, _parent, [_zoomChipX, _pictureY + (_stepH - _zoomChipH) / 2, _chipW, _zoomChipH], str _x, (_work select 0) == _x, _theme, _putIcon, [
        [_x, _work select 1, _work select 2], _code, _arguments
    ]] call FUNC(uiChip);

    _zoomChipX = _zoomChipX + _chipW + _zoomChipGap;
} forEach _zoomChips;

_pictureY = _pictureY + _stepH + _stepGap;

// The shift: across, then down, each with its text box.
private _shiftW = (_pictureW - _gap) / 2;

{
    _x params ["_which", "_format"];

    [
        _pictureX + (_shiftW + _gap) * _forEachIndex, _pictureY, (_shiftW - _numberW - _gap) max ([_format, -100] call _fnc_stepperWidth), _which,
        [round (-ICON_OFFSET_MAX * 100), round (ICON_OFFSET_MAX * 100)], _format
    ] call _fnc_number;
} forEach [[1, LLSTRING(Items_PictureAcross)], [2, LLSTRING(Items_PictureDown)]];

_pictureY + _stepH - _top
