#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A left press on a box of the attachments view (fnc_drawHotspots) while a part is on it: held like a press on the part's own
 * slot (fnc_onMouseButton), so the part is dragged out once the mouse moves (fnc_onFrame, fnc_startDrag) - onto a grid or the
 * ground it comes off there (fnc_endDrag, fnc_doUnequip). Let go without moving, the box's click opens its parts
 * (fnc_hotspotClick). Only a worn weapon's parts: a weapon lying in a container changes through op "fit", which takes no drag.
 *
 * Arguments:
 * 0: The part's slot, e.g. "primary_optic" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["primary_optic"] call aio_gui_fnc_hotspotPress;
 *
 * Public: No
 */

params [["_slot", "", [""]]];

if (_slot isEqualTo "" || {(_slot select [0, 5]) isEqualTo "tile_"} || {GVAR(dragging)}) exitWith {};

private _unit = GVAR(unit);

if ((([_unit, _slot] call EFUNC(storage,getSlot)) getOrDefault ["class", ""]) isEqualTo "") exitWith {};
if (([_unit, _slot] call FUNC(queuedSlot)) > 0) exitWith {};

GVAR(press) = [-1, -1, getMousePosition, [0, 0], false, [_unit, _slot], false];
