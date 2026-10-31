#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an option of CBA's item context menu stays out of the window's context menu
 * (aio_gui_fnc_cbaOptions): Enhanced First Aid Kits' "Open" on its kits. It opens that mod's own kit
 * window, guessing where the kit lies; the window offers its own Open instead, which opens the kit in a
 * window of its own inside the inventory, from exactly where it lies (fnc_menuChoices).
 *
 * That mod registers the option under an id of its own making and its name already in words, so it is
 * known by the kit and that name.
 *
 * Arguments:
 * 0: Item class <STRING>
 * 1: The option's name, as the menu shows it <STRING>
 *
 * Return Value:
 * Left out <BOOL>
 *
 * Example:
 * ["efak_IFAK_7", "Open"] call aio_compat_efak_fnc_hideCbaOption;
 *
 * Public: No
 */

params [["_item", "", [""]], ["_displayName", "", [""]]];

[_item] call FUNC(isKit) && {_displayName == localize "STR_efak_core_Action_OpenKit"}
