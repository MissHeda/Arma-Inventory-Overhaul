#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * While an item is dragged, every one of the player's slots that takes it lights up, as in Tarkov - a
 * green outline and a faint green fill on its round corners: the helmet's slot for a helmet, the
 * weapons a magazine or attachment fits (on the weapon's card as on the part's own slot).
 *
 * A worn item dragged off a slot lights up the same slot of the other units it may be exchanged with
 * (fnc_canSwap) - a body's for the player's own, the player's for a body's -, in the inventory only; the
 * primary lights up the second primary on the back (a two-primary mod), and that one the primary.
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
private _isPart = (([_class] call EFUNC(items,getInfo)) getOrDefault ["kind", ""]) in ["muzzle", "optic", "rail", "bipod", "magazine", "grenade"];

if (_slotSource isEqualTo [] && {_isPart}) then {
    _equipment = [_unit] call EFUNC(storage,getEquipment);
};

private _controls = [];

{
    _x params [["_rect", []], "", "", "", "", ["_slot", ""], ["_owner", objNull]];

    if (_slot isEqualTo "" || {_rect isEqualTo []} || {(_x param [7, -1]) >= 0}) then {continue};

    private _fits = if (_slotSource isEqualTo []) then {
        _owner isEqualTo _unit && {
            [_unit, _slot, _class, _equipment] call EFUNC(storage,slotAccepts) || {
                _slot in ["primary", "handgun", "launcher", "primary2"] && {([_unit, _slot, _class, _equipment] call EFUNC(storage,partFor)) isNotEqualTo ""}
            }
        }
    } else {
        !isNull _owner
        && {
            (_owner isNotEqualTo (_slotSource select 0) && {_slot isEqualTo (_slotSource select 1)})
            || {_owner isEqualTo (_slotSource select 0) && {[_slotSource select 1, _slot] in [["primary", "primary2"], ["primary2", "primary"]]}}
        }
        && {[] call FUNC(isInventoryMode)} && {([_slotSource, _owner, _slot] call FUNC(canSwap)) isEqualTo ""}
    };

    if (!_fits) then {continue};

    private _glow = [_display, _forEachIndex] call FUNC(glowSlot);

    {_x ctrlShow true} forEach _glow;
    _controls append _glow;
} forEach (uiNamespace getVariable [QGVAR(slots), []]);

// The Attachments card's boxes - over the 3D picture and in the row under it (fnc_drawHotspots) - light up for a part they
// take, as Tarkov and Reforger light the slots a dragged part fits: a worn weapon's by the same check as its slot, one lying in
// a container's by the weapon alone (aio_storage_fnc_partFits), as a drop there asks (fnc_updateDrag).
if (_slotSource isEqualTo [] && {_isPart}) then {
    private _weaponTile = createHashMap;

    {
        private _spotSlot = _x getOrDefault ["slot", ""];
        private _glow = _x getOrDefault ["glow", []];

        if (_glow isEqualTo []) then {continue};

        private _fits = if ((_spotSlot select [0, 5]) isEqualTo "tile_") then {
            private _target = GVAR(inspect) param [5, ""];

            // Only a tile out of a grid that is no kit goes onto a weapon lying in a container, as a drop there asks (fnc_updateDrag).
            private _sourceIndex = GVAR(press) param [0, -1];

            if (
                !(_sourceIndex isEqualType 0) || {_sourceIndex < 0}
                || {(((uiNamespace getVariable [QGVAR(grids), []]) param [_sourceIndex, createHashMap]) getOrDefault ["kit", ""]) isNotEqualTo ""}
            ) exitWith {false};

            if (count _weaponTile == 0 && {_target isEqualType createHashMap}) then {
                _weaponTile = [_target] call FUNC(weaponTile);
            };

            [_weaponTile getOrDefault ["class", ""], _x getOrDefault ["part", ""], _class] call EFUNC(storage,partFits)
        } else {
            [_unit, _spotSlot, _class, _equipment] call EFUNC(storage,slotAccepts)
        };

        if (!_fits) then {continue};

        {_x ctrlShow true} forEach _glow;
        _controls append _glow;
    } forEach (uiNamespace getVariable [QGVAR(hotspots), []]);
};

uiNamespace setVariable [QGVAR(dragGlow), _controls];
