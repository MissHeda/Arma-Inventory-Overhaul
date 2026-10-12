#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the window leaves out an option of CBA's item context menu because it offers its own instead:
 * ACRE2's "Open" on one of its radios (the window's "Open radio" steps aside first, which ACRE's own call
 * from inside the window could not). Asked for every option of the menu (einv_gui_fnc_cbaOptions), with
 * the option's name already localized.
 *
 * Arguments:
 * 0: Item class <STRING>
 * 1: The option's display name <STRING>
 *
 * Return Value:
 * Leave it out <BOOL>
 *
 * Example:
 * ["ACRE_PRC152_ID_1", "Open"] call einv_compat_acre_fnc_hideCbaOption;
 *
 * Public: No
 */

params [["_item", "", [""]], ["_displayName", "", [""]]];

_displayName == localize "STR_ACRE_sys_gui_Open" && {[_item] call acre_api_fnc_isRadio}
