#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A click on a point of the modding view or a box of its row (fnc_drawHotspots): the left button lists what fits there
 * (fnc_partChoices), the right one takes what is on the part off into the gear (fnc_quickUnequip). A frame later
 * (fnc_later): the card may be drawn anew meanwhile.
 *
 * Asked by the point's own hit box, and by the 3D view's areas that turn the item (fnc_drawInspect): once the item was
 * turned, an area that held the focus could take the point's click - Mia: "as soon as you turn the weapon, the icons
 * can't be clicked anymore". A press on a point there is the point's, not a turn.
 *
 * Arguments:
 * 0: The part's slot, e.g. "primary_optic" <STRING>
 * 1: Mouse button, 0 left, 1 right <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["primary_optic", 0] call aio_gui_fnc_hotspotClick;
 *
 * Public: No
 */

params [["_slot", "", [""]], ["_button", 0, [0]]];

if (_slot isEqualTo "") exitWith {};

if (_button == 0) exitWith {
    [{[_this] call FUNC(partChoices)}, _slot] call FUNC(later);
};

if (_button == 1) then {
    [{
        if ((([GVAR(unit), _this] call EFUNC(storage,getSlot)) getOrDefault ["class", ""]) isNotEqualTo "") then {
            [GVAR(unit), _this] call FUNC(quickUnequip);
        };
    }, _slot] call FUNC(later);
};
