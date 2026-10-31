#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts an item out of an open kit on the player - dragged onto a slot, Alt+click, Equip / Attach to /
 * Load into in the context menu (aio_gui_fnc_doEquip): a magazine with the rounds the kit kept for it,
 * a CBRN bag's mask on the face. One move of the window's transactions (aio_gui_fnc_sendMoves): out
 * of the kit at its root's authority ("kitTake"), on where the player's unit is local ("putOn").
 *
 * What comes off the slot goes into the kit when the kit takes it - empty, a magazine with rounds left,
 * by that mod's rules and room (fnc_canPack), as in Enhanced First Aid Kits' own wearItem -, else into
 * the player's own gear, the kit's "take into" choice first (fnc_ownTargets), else where the storage
 * settles what has no place: the vehicle or the ground. Never lost; an item that would not go on goes
 * back into the kit the same way.
 *
 * Out of a kit in a living person's gear only as the window's settings for it say
 * (aio_gui_fnc_checkTouch), and never out of another living player's (fnc_mayReach).
 *
 * Arguments:
 * 0: Slot id, see aio_storage_fnc_getSlot <STRING>
 * 1: Kit class <STRING>
 * 2: Entry - a tile of the kit (fnc_getEntries) <HASHMAP>
 *
 * Return Value:
 * Sent <BOOL>
 *
 * Example:
 * ["goggles", "eup_CBRNBag_3", _entry] call aio_compat_efak_fnc_equip;
 *
 * Public: No
 */

params [["_slot", "", [""]], ["_kit", "", [""]], ["_entry", createHashMap, [createHashMap]]];

private _unit = EGVAR(gui,unit);

private _fnc_refuse = {
    params ["_why"];

    [_why] call EFUNC(gui,flashHint);
    false
};

if (_kit isEqualTo "" || {_slot isEqualTo ""} || {isNull _unit}) exitWith {false};

private _wait = call FUNC(notReady);

if (_wait isNotEqualTo "") exitWith {[_wait] call _fnc_refuse};

[_kit] call FUNC(snapshot);

private _key = "kit:" + toLowerANSI _kit;
private _where = ([_kit] call FUNC(locate)) select 1;

if (isNull _where) exitWith {["Failed"] call _fnc_refuse};

// Only while the player may still reach it where it lies now (fnc_mayReach).
if !([_where] call FUNC(mayReach)) exitWith {[LLSTRING(NotYours)] call _fnc_refuse};

// In a living person's gear only as the settings for it say (aio_gui_fnc_checkTouch).
private _touch = [_where, "items"] call EFUNC(gui,checkTouch);

if (_touch isNotEqualTo "") exitWith {[_touch] call _fnc_refuse};

private _root = [_key] call FUNC(holderRoot);

if (isNull _root) exitWith {["Failed"] call _fnc_refuse};

private _move = createHashMapFromArray [
    ["kind", "equip"], ["from", _key], ["fromRoot", _root], ["entry", _entry], ["count", 1],
    ["unit", _unit], ["slot", _slot], ["cell", []]
];

// Where what is in the slot now goes: into the kit when it takes it, else the player's own gear. Read
// here, as it is now - the authority asks the kit again, and what it turns away is settled.
private _old = [_unit, _slot] call EFUNC(storage,getSlot);
private _oldClass = _old getOrDefault ["class", ""];

if (_oldClass isNotEqualTo "") then {
    private _inside = _old getOrDefault ["container", objNull];
    private _empty = isNull _inside || {([_inside] call EFUNC(storage,getContents)) isEqualTo []};
    private _dry = ([_oldClass] call EFAKFUNC(core,getMagazineSize)) > 1 && {(_old getOrDefault ["ammo", 0]) < 1};

    if (_empty && {!_dry} && {([_kit, _oldClass, 1] call FUNC(canPack)) select 0}) then {
        _move set ["to", _key];
        _move set ["toRoot", _root];
    } else {
        // Not into the uniform, vest or backpack that comes off itself.
        private _targets = ([_kit] call FUNC(ownTargets)) select {_x isNotEqualTo _inside};
        private _index = _targets findIf {[_x, _old] call EFUNC(storage,hasRoom)};

        if (_index >= 0) then {
            _move set ["to", _targets select _index];
            _move set ["toRoot", _unit];
        };
    };
};

[[_move], createHashMapFromArray [["flash", true]]] call EFUNC(gui,sendMoves)
