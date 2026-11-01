#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A left press on a box of the attachments view (fnc_drawHotspots) while a part is on it: held like a press on the part's own
 * slot (fnc_onMouseButton), so the part is dragged out once the mouse moves (fnc_onFrame, fnc_startDrag) - onto a grid or the
 * ground it comes off there (fnc_endDrag, fnc_doUnequip). Let go without moving, the box's click opens its parts
 * (fnc_hotspotClick). A weapon lying in a container: its part comes off by op "fit" where it is let go (fnc_doUnequip).
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

if (_slot isEqualTo "" || {GVAR(dragging)}) exitWith {};

private _unit = GVAR(unit);

// A weapon lying in a container: the part off its tile as it is now (fnc_weaponTile); dropped, it comes off by op "fit"
// (fnc_doUnequip, fnc_doFit).
if ((_slot select [0, 5]) isEqualTo "tile_") exitWith {
    if (count ([_slot] call FUNC(tilePart)) == 0) exitWith {};

    GVAR(press) = [-1, -1, getMousePosition, [0, 0], false, [_unit, _slot], false];
};

if ((([_unit, _slot] call EFUNC(storage,getSlot)) getOrDefault ["class", ""]) isEqualTo "") exitWith {};
if (([_unit, _slot] call FUNC(queuedSlot)) > 0) exitWith {};

GVAR(press) = [-1, -1, getMousePosition, [0, 0], false, [_unit, _slot], false];
