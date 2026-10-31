#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The width of a button in the wizard's footer (Back, Next, Save): the least of 4.5 units, else the room for its
 * label with the paddings. The Apply button of the Items and Containers editors takes the width of Save, so it
 * lies right above it.
 *
 * Arguments:
 * 0: The label <STRING>
 * 1: The font <STRING>
 *
 * Return Value:
 * The width <NUMBER>
 *
 * Example:
 * [localize "STR_aio_setup_Save", "PuristaMedium"] call aio_setup_fnc_footerButtonW;
 *
 * Public: No
 */

params ["_text", "_font"];

private _rowH = UNIT * 1.25;

(SQUARE(UNIT * 4.5)) max (SQUARE(_rowH * 1.4) + (_text getTextWidth [_font, _rowH * 0.5]) * TEXT_SLACK)
