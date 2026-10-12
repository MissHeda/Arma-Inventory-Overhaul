#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Everything the open window shows, written out in three parts that fnc_onFrame compares one by one -
 * two signatures differ in a part exactly when something shown there was taken, put in, used up,
 * swapped or laid elsewhere while the window was open, by a script, the Arsenal, ACE or another player:
 *
 *   own  - the unit's loadout, which holds what its uniform, vest and backpack carry, the cargo of what
 *          lies in them, ACE's virtual load on it (which its weight counts), and the revision of the
 *          places of its three containers (einv_storage_fnc_readPlaces), and the key of the weight limits
 *          (einv_weight_fnc_getLimits) - the weight card's marks move with a changed setting, ACE's load
 *          factor or the soldier's performance factor. A change here builds the window anew.
 *   list - which sections the loot column shows and what is not a tile of it: the two containers the
 *          window looks into, what lies around (GVAR(nearby)), what was opened from inside a container
 *          and the bodies' and persons' gear on their dolls, a count of changes to the kits shown
 *          (einv_compat_efak) and the places of the kits' windows. A change here builds the window
 *          anew as well.
 *   loot - per section of the loot column that has a container, [its number in the list of sections,
 *          what it holds and where it lies]: its cargo - and that of every uniform, vest and backpack
 *          lying in it, all the way down - and the revision of its places. Only some of these changed:
 *          only those sections are drawn again (fnc_redrawTiles).
 *
 * A living person's loadout leaves out the rounds in their loaded magazines: one who fires would build
 * the window anew every second, closing the context menu and pulling the hover away. A body's or
 * person's uniform, vest and backpack are sections of their own, read by their cargo.
 *
 * The sections are those of the last build (GVAR(context)), so a signature taken between two builds
 * compares like with like: when the list differs the window is built anew anyway.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [own, list, loot] <ARRAY>
 *   own  <STRING>
 *   list <ARRAY>
 *   loot <ARRAY of [number, STRING]>
 *
 * Example:
 * call einv_gui_fnc_getSignature;
 *
 * Public: No
 */

// An object's cargo, and that of every uniform, vest and backpack lying in it, all the way down.
private _fnc_cargo = {
    params ["_object"];

    [
        weaponsItemsCargo _object, magazinesAmmoCargo _object, getItemCargo _object, getBackpackCargo _object,
        everyContainer _object apply {[_x select 1] call _fnc_cargo}
    ]
};

// What is lying in a unit's own uniform, vest and backpack.
private _fnc_nested = {
    params ["_unit"];

    [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] apply {
        if (isNull _x) then {[]} else {everyContainer _x apply {[_x select 1] call _fnc_cargo}}
    }
};

// The revision of the places of a holder, -1 for none.
private _fnc_revision = {
    params ["_holder"];

    if (_holder isEqualType "" || {!isNull _holder}) then {([_holder] call EFUNC(storage,readPlaces)) select 0} else {-1}
};

// ----- Own -----

private _ownParts = [getUnitLoadout GVAR(unit), [GVAR(unit)] call _fnc_nested];

// ACE's virtual load, which the weight card counts (fnc_drawEquipmentCards). The weight overrides of the
// rules reach it a frame or two after a move - after the window was built for that move - and an Enhanced
// First Aid Kits kit changes it without any cargo changing. Either way the card is drawn again.
_ownParts pushBack ([GVAR(unit), uniformContainer GVAR(unit), vestContainer GVAR(unit), backpackContainer GVAR(unit)] apply {
    _x getVariable [QACEGVAR(movement,vLoad), 0]
});

_ownParts pushBack ([uniformContainer GVAR(unit), vestContainer GVAR(unit), backpackContainer GVAR(unit)] apply {[_x] call _fnc_revision});

// Where the tiers start (the weight card's ticks): a changed threshold redraws the card within a second.
_ownParts pushBack (([GVAR(unit)] call EFUNC(weight,getLimits)) get "key");

private _own = str _ownParts;

// ----- List -----

private _list = [GVAR(container), GVAR(secondary), GVAR(nearby)];

{
    // A body or a person is read by their loadout like the unit - less what their uniform, vest and
    // backpack hold, which their sections show (loot) -, and a living one less the rounds in their loaded
    // magazines.
    if (!isNull _x && {_x isKindOf "CAManBase"}) then {
        private _loadout = getUnitLoadout _x;

        for "_i" from 3 to 5 do {
            private _worn = _loadout param [_i, []];

            if (_worn isNotEqualTo []) then {
                _loadout set [_i, _worn select 0];
            };
        };

        // The doll's counts catch up with the next real change.
        if (alive _x) then {
            for "_i" from 0 to 2 do {
                private _weapon = _loadout select _i;

                if (_weapon isNotEqualTo []) then {
                    _weapon set [4, (_weapon param [4, []]) param [0, ""]];
                    _weapon set [5, (_weapon param [5, []]) param [0, ""]];
                };
            };
        };

        _list pushBack _loadout;
    };
} forEach [GVAR(container), GVAR(secondary)];

// What was opened from inside a container: the very objects - the engine makes a new one whenever a
// sibling of its class is taken out and the others put back (fnc_build finds it again).
_list pushBack (GVAR(opened) select {!isNull (_x select 1)} apply {_x select 1});

// A kit of Enhanced First Aid Kits the window shows changed - its contents, or the name a player gave
// it - without any cargo changing (einv_compat_efak - only when that addon is loaded).
if (!isNil QEFUNC(compat_efak,signature)) then {
    _list pushBack (call EFUNC(compat_efak,signature));
};

// Where things lie in the kits' windows, by the key their places are kept under (GVAR(windowOrder)).
_list pushBack (GVAR(windowOrder) apply {[_x] call _fnc_revision});

// Who may open what changed (einv_locks): a lock set, lifted or passed on to another group, and ACE
// lockpicking or a key changing `locked` while the window is open.
_list pushBack EGVAR(locks,stamp);
_list pushBack ([GVAR(container), GVAR(secondary)] apply {if (isNull _x) then {-1} else {locked _x}});

// What ACE cargo has loaded in everything the window looks into, and what unloads (einv_compat_ace_cargo).
if (!isNil QEFUNC(compat_ace_cargo,signature)) then {
    _list pushBack ([] call EFUNC(compat_ace_cargo,signature));
};

// ----- Loot -----

private _loot = [];

{
    private _container = _x getOrDefault ["container", objNull];

    if (!isNull _container) then {
        _loot pushBack [_forEachIndex, str [[_container] call _fnc_cargo, [_container] call _fnc_revision]];
    };
} forEach (GVAR(context) getOrDefault ["lootSections", []]);

[_own, _list, _loot]
