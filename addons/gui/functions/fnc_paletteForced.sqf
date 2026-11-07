#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a server or a mission forces the colours (the CBA setting aio_gui_paletteText, set with a priority of 1 or more on
 * "server" or "mission", fnc_settingForced): then everyone wears those, and the palette button is not drawn (fnc_paletteAllowed).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Forced <BOOL>
 *
 * Example:
 * call aio_gui_fnc_paletteForced;
 *
 * Public: No
 */

[QGVAR(paletteText)] call FUNC(settingForced)
