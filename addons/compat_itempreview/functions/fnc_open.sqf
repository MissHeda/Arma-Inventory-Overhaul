#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Shows an item on the showcase of KPBLM Item Preview: lit, turned with the mouse, zoomed with the wheel. Its
 * window opens as a child of this one (kpblm_pv_fnc_previewItem with the window as its parent), so this one keeps
 * still meanwhile (aio_gui_fnc_isCovered) and is there again as it was once the showcase is closed - Escape or a
 * double click. A weapon the player carries shows with what is on it, any other with what its config fits on it,
 * as that mod reads it.
 *
 * Arguments:
 * 0: Item class <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["arifle_MX_F"] call aio_compat_itempreview_fnc_open;
 *
 * Public: No
 */

params [["_class", "", [""]]];

if (_class isEqualTo "" || {isNil "kpblm_pv_fnc_previewItem"}) exitWith {};

private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

if (isNull _display) exitWith {};

call EFUNC(gui,closeMenu);

[_class, _display] call kpblm_pv_fnc_previewItem;
