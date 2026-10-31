#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether another window lies over this one: a dialog an option of another mod's context menu opened
 * (fnc_cbaRun), or Enhanced First Aid Kits' kit window or quick access, which its keybinds can open at
 * any time. A dialog opened while this one is open is its child.
 *
 * Meanwhile this window keeps still (fnc_onFrame): it must not take the focus back every frame, nor
 * follow a mouse that works the other window.
 *
 * Arguments:
 * 0: The inventory window <DISPLAY>
 *
 * Return Value:
 * Covered <BOOL>
 *
 * Example:
 * [_display] call aio_gui_fnc_isCovered;
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {false};

(allDisplays findIf {displayParent _x isEqualTo _display}) >= 0
|| {!isNull (uiNamespace getVariable ["efak_gui_display", displayNull])}
|| {!isNull (uiNamespace getVariable ["efak_gui_contentsDisplay", displayNull])}
