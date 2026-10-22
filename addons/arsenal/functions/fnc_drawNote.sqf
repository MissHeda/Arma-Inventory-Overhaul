#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A section of the panel that shows a note in place of a grid (its "drawer", einv_gui_fnc_drawSection): the kit's
 * section while Enhanced First Aid Kits' kits tab is open and the kit picked there has no grid to show - it lies in
 * none of the soldier's containers nor the staging space ("Take the kit first"), it is still being made ready, or its
 * contents have not reached this machine yet (einv_compat_efak_fnc_arsenalKit). The caption as a section draws it - a
 * pill in the caption line's size and colours, a hairline under the line, at the left edge as the panel's sections
 * have no box - and the note under it in one muted line, cut to the width. Nothing to fold, nothing to drop on.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to draw in - the column's <CONTROL>
 * 2: Top of the section in the group <NUMBER>
 * 3: Width the section may take <NUMBER>
 * 4: Section - "title" and "note" <HASHMAP>
 * 5: Theme <HASHMAP>
 *
 * Return Value:
 * Height used <NUMBER>
 *
 * Example:
 * [_display, _group, 0, 0.3, _section, _theme] call einv_arsenal_fnc_drawNote;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_top", "_width", "_section", "_theme"];

// The measures of a section's caption line (einv_gui_fnc_drawSection), which grow with the tile scale (TEXT_UNIT).
private _textUnit = TEXT_UNIT;
private _lineH = _textUnit * CAPTION_LINE;
private _lineSize = _textUnit * 0.46;
private _buttonH = _textUnit * 0.6;
private _buttonTop = _top + (_lineH - _buttonH) / 2;
private _buttonSize = _textUnit * TEXT_REF;
private _tabPad = SQUARE(_buttonH * 0.9);
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];

// As wide as a grid of the panel, a pixel in from the left as a section without a box is.
([] call EFUNC(gui,getCell)) params ["_cellW"];

private _blockX = pixelW;
private _blockW = (STORAGE_COLS * _cellW) min (_width - pixelW * 2);

private _caption = [_section getOrDefault ["title", ""], _theme] call EFUNC(gui,caption);
private _shown = [_caption, _blockW - _tabPad, _fontBold, _buttonSize] call EFUNC(gui,fitText);
private _tabW = (((_shown getTextWidth [_fontBold, _buttonSize]) * TEXT_SLACK) + _tabPad) min _blockW;

[
    _display, _parent, [_blockX, _buttonTop, _tabW, _buttonH], _theme getOrDefault ["slotCaptionBg", [0, 0, 0, 0.5]],
    (_theme getOrDefault ["radius", 0]) min (_buttonH / 2)
] call EFUNC(gui,uiPanel);

[
    _display, _parent, [_blockX, _buttonTop + _buttonH / 2 - TEXT_MID * _buttonSize, _tabW, TEXT_MID * _buttonSize * 2],
    _shown, _buttonSize, _colorText2, _fontBold, 2
] call EFUNC(gui,uiLabel);

// The hairline under the caption line.
[_display, _parent, [_blockX, _top + _lineH, _blockW, pixelH], _theme getOrDefault ["line", [1, 1, 1, 0.07]]] call EFUNC(gui,uiPanel);

// The note, where the grid would be.
private _note = _section getOrDefault ["note", ""];

[
    _display, _parent, [_blockX, _top + _lineH + UNIT * 0.25, _blockW, _textUnit * 0.62],
    [_note, _blockW, _font, _lineSize] call EFUNC(gui,fitText), _lineSize, _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]], _font, 0
] call EFUNC(gui,uiLabel);

_lineH + UNIT * 0.25 + _textUnit * 0.7
