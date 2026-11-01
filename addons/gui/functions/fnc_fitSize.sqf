#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The font size a short text - a magazine's rounds, "0/30" - is drawn in to fit a width whole: the size asked for where it fits,
 * else as much smaller as it has to be, with the TEXT_SLACK room fnc_fitText leaves. For words that must not be cut (fnc_fitText
 * cuts them with "..."): a small box beside a weapon keeps its count readable at every tile and text size (fnc_drawSlot,
 * fnc_drawEquipmentDoll).
 *
 * Arguments:
 * 0: Text <STRING>
 * 1: Width, in screen units <NUMBER>
 * 2: Font <STRING>
 * 3: Font size wanted, as a height <NUMBER>
 *
 * Return Value:
 * The font size, at most the one wanted <NUMBER>
 *
 * Example:
 * ["0/30", 0.03, "PuristaMedium", 0.02] call aio_gui_fnc_fitSize;
 *
 * Public: No
 */

params [["_text", "", [""]], ["_width", 0, [0]], ["_font", "PuristaMedium", [""]], ["_size", 0, [0]]];

private _drawn = (_text getTextWidth [_font, _size]) * TEXT_SLACK;

if (_drawn <= _width || {_drawn <= 0}) exitWith {_size};

// getTextWidth grows with the size: the share the text is too wide by is the share it is set smaller.
_size * ((_width max 0) / _drawn)
