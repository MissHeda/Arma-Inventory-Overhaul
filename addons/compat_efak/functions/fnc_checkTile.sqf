#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the player may move a kit's tile away from where it lies, and if not, why - for the window's
 * moves out of a living person's gear (einv_gui_fnc_startDrag, einv_gui_fnc_contextMenu,
 * einv_gui_fnc_doEquip). A kit in the uniform, vest or backpack another living player wears
 * (fnc_isPlayerGear) is shown, but neither opened (fnc_canOpen) nor moved, by Mia's rule: the kits of
 * others are off limits here. Any other tile, and a kit anywhere else, is never refused here - the
 * window's own rules for a person's gear still apply (einv_gui_fnc_checkTouch).
 *
 * A kit in a container lying in his gear - a vest in his backpack - moves like his other items.
 *
 * Arguments:
 * 0: Class of the tile <STRING>
 * 1: Container it lies in <OBJECT>
 *
 * Return Value:
 * "" when it may move, else the reason the hint shows <STRING>
 *
 * Example:
 * ["efak_IFAK_7", backpackContainer cursorObject] call einv_compat_efak_fnc_checkTile;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_container", objNull, [objNull]]];

if (isNull _container || {!([_class] call FUNC(isKit))}) exitWith {""};

private _unit = EGVAR(gui,unit);

if (_container in [uniformContainer _unit, vestContainer _unit, backpackContainer _unit]) exitWith {""};

["", LLSTRING(NotYours)] select ([_container] call FUNC(isPlayerGear))
