#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The size popover under its button in the header (fnc_openSizeMenu) closed: a slider still held is let go, what was changed is
 * written to the CBA client settings (fnc_sizeSet "commit") and the button is drawn closed. Asked by fnc_closeMenu whenever the
 * menu it closes was the popover - not where it is only made again over a build (aio_gui_menuRemake) - and when the window closes
 * (fnc_onUnload).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_gui_fnc_sizeSettle;
 *
 * Public: No
 */

["end"] call FUNC(sizeSlide);
["commit"] call FUNC(sizeSet);

uiNamespace setVariable [QGVAR(sizeMenuRows), []];

[] call FUNC(updateSizeButton);
