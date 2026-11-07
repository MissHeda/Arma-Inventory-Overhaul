#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A setting of what the window shows or where it stands changed (the settings' scripts, fnc_settingsRow): an open window is built
 * again on the next frame (fnc_later, fnc_buildSoon: a press on the settings card must not delete what it was pressed on), with the
 * settings card open over it (fnc_build). Nothing at all while no window is open: the next one starts from the settings as they are.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call aio_gui_fnc_elementsChanged;
 *
 * Public: No
 */

if (isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {};

[{[] call FUNC(buildSoon)}] call FUNC(later);
