#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * While an item is dragged, every one of the player's slots that takes it lights up, as in Tarkov - a
 * green outline and a faint green fill on its round corners: the helmet's slot for a helmet, the
 * weapons a magazine or attachment fits (on the weapon's card as on the part's own slot).
 *
 * A worn item dragged off a slot lights up the same slot of the other units it may be exchanged with
 * (fnc_canSwap) - a body's for the player's own, the player's for a body's -, in the inventory only.
 *
 * Lighting up makes no controls: each slot's highlight is made once per build (fnc_glowSlot, ahead of
 * time by fnc_warmTargets) and is shown here, hidden again by fnc_endDrag. What the unit wears is read
 * once for all the slots asked about, and only for an item that may go on a weapon's part at all.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The dragged entry <HASHMAP>
 * 2: The slot it comes from, [unit, slot id] - [] for a tile <ARRAY> (default: [])
 *
 * Return Value:
 * None - the controls shown are kept as uiNamespace QGVAR(dragGlow), hidden again with fnc_endDrag
 *
 * Example:
 * [_display, _entry] call aio_gui_fnc_showTargets;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_entry", ["_slotSource", [], [[]]]];

private _class = _entry getOrDefault ["class", ""];
private _unit = GVAR(unit);

// What a drag before this one left lit, should it not have been ended.
{
    if (!isNull _x) then {_x ctrlShow false};
} forEach (uiNamespace getVariable [QGVAR(dragGlow), []]);

// What the unit wears, read once: only an attachment or a magazine is asked about a weapon's parts (fnc_slotAccepts).
private _equipment = createHashMap;

if (
    _slotSource isEqualTo []
    && {(([_class] call EFUNC(items,getInfo)) get "kind") in ["muzzle", "optic", "rail", "bipod", "magazine", "grenade"]}
) then {
    _equipment = [_unit] call EFUNC(storage,getEquipment);
};

private _controls = [];

{
    _x params [["_rect", []], "", "", "", "", ["_slot", ""], ["_owner", objNull]];

    if (_slot isEqualTo "" || {_rect isEqualTo []} || {(_x param [7, -1]) >= 0}) then {continue};

    private _fits = if (_slotSource isEqualTo []) then {
        _owner isEqualTo _unit && {
            [_unit, _slot, _class, _equipment] call EFUNC(storage,slotAccepts) || {
                _slot in ["primary", "handgun", "launcher"] && {([_unit, _slot, _class, _equipment] call EFUNC(storage,partFor)) isNotEqualTo ""}
            }
        }
    } else {
        !isNull _owner && {_owner isNotEqualTo (_slotSource select 0)} && {_slot isEqualTo (_slotSource select 1)}
        && {[] call FUNC(isInventoryMode)} && {([_slotSource, _owner, _slot] call FUNC(canSwap)) isEqualTo ""}
    };

    if (!_fits) then {continue};

    private _glow = [_display, _forEachIndex] call FUNC(glowSlot);

    {_x ctrlShow true} forEach _glow;
    _controls append _glow;
} forEach (uiNamespace getVariable [QGVAR(slots), []]);

uiNamespace setVariable [QGVAR(dragGlow), _controls];
