#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The panel's hint line (the "footer" hook), in place of the inventory's footer, which would lie over ACE's
 * menu bar: the panel's last band (fnc_layout), on the panel's own glass like the rest of it, under a
 * hairline as the one under the title row, with the engine's hint in it in the footer's text size - what
 * the mouse is on, what a drag would do, why something did not go (einv_gui_fnc_updateHover,
 * einv_gui_fnc_flashHint). The hairline and the text keep the padding of the block's other bands on
 * both sides. With no panel drawn there is no hint either.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _theme] call einv_arsenal_fnc_footer;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_theme", createHashMap, [createHashMap]]];

uiNamespace setVariable [QEGVAR(gui,hint), controlNull];

if (GVAR(hintRect) isEqualTo []) exitWith {};

GVAR(hintRect) params ["_left", "_top", "_width", "_height"];

// Where the column ends: a hairline as thin as the one under the title row, from the block's left padding to
// its right one, so the hint line reads as a band of the block rather than a bar of its own.
private _padX = SQUARE(UNIT * PANEL_PAD);

[_display, controlNull, [_left + _padX, _top, _width - _padX * 2, pixelH], _theme getOrDefault ["line", []]] call EFUNC(gui,uiPanel);

// The text, centred, its lines HINT_LINE_H high (fnc_layout gives the band one or two of them), the band's
// padding above and below.
private _padY = UNIT * HINT_PAD;

uiNamespace setVariable [QEGVAR(gui,hint), [
    _display, "EINV_FooterHint", controlNull,
    [_left + _padX, _top + _padY, _width - _padX * 2, _height - _padY * 2]
] call EFUNC(gui,uiCreate)];
