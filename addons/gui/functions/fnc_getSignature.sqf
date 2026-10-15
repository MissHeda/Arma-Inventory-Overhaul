#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Everything the open window shows, written out in five parts that fnc_refresh compares one by one -
 * two signatures differ in a part exactly when something shown there was taken, put in, used up,
 * swapped or laid elsewhere while the window was open, by a script, the Arsenal, ACE, another player or
 * the window's own moves:
 *
 *   own     - the unit's loadout as the equipment column shows it: what it wears and holds, less what its
 *             uniform, vest and backpack carry (storage, below). A change here builds the window anew.
 *   list    - which sections the columns show and what is not a tile of them: the two containers the
 *             window looks into, the uniform, vest and backpack the unit wears (the very objects), what
 *             lies around (GVAR(nearby)), what was opened from inside a container - and whether it still
 *             lies there - and the bodies' and persons' gear on their dolls, a count of changes to the kits
 *             shown (einv_compat_efak) and the places of the kits' windows. A change here builds the window
 *             anew as well.
 *   loot    - per section of the loot column that has a container, [its number in the list of sections,
 *             what it holds and where it lies]: its cargo - and that of every uniform, vest and backpack
 *             lying in it, all the way down - and the revision of its places. Only some of these changed:
 *             only those sections are drawn again (fnc_redrawTiles).
 *   storage - the same per section of the unit's own storage column (GVAR(context) "ownSections"). Only
 *             some changed: those sections are drawn again, and with them the weight card and the hotbar,
 *             which count what the unit carries (fnc_redrawPart).
 *   card    - what else the weight card shows: ACE's virtual load on the unit and its uniform, vest and
 *             backpack (which its weight counts), and the key of the weight limits
 *             (einv_weight_fnc_getLimits) - the card's marks move with a changed setting, ACE's load factor
 *             or the soldier's performance factor. A change here draws only the card again.
 *
 * A living person's loadout leaves out the rounds in their loaded magazines: one who fires would build
 * the window anew every second, closing the context menu and pulling the hover away. A body's or
 * person's uniform, vest and backpack are sections of their own, read by their cargo.
 *
 * The sections are those of the last build (GVAR(context)), so a signature taken between two builds
 * compares like with like: when the list differs the window is built anew anyway. A move between the
 * unit's backpack and a crate changes only storage and loot: two sections and the card are drawn again
 * instead of the whole window (a tester, 0.4.7: a small stutter on every move).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [own, list, loot, storage, card] <ARRAY>
 *   own     <STRING>
 *   list    <ARRAY>
 *   loot    <ARRAY of [number, STRING]>
 *   storage <ARRAY of [number, STRING]>
 *   card    <ARRAY>
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

// The revision of the places of a holder, -1 for none.
private _fnc_revision = {
    params ["_holder"];

    if (_holder isEqualType "" || {!isNull _holder}) then {([_holder] call EFUNC(storage,readPlaces)) select 0} else {-1}
};

// ----- Own -----

// What its uniform, vest and backpack carry is theirs (storage): only their classes stay here.
private _loadout = getUnitLoadout GVAR(unit);

for "_i" from 3 to 5 do {
    private _wornEntry = _loadout param [_i, []];

    if (_wornEntry isNotEqualTo []) then {
        _loadout set [_i, _wornEntry select 0];
    };
};

private _own = str _loadout;

// ----- List -----

private _wornContainers = [uniformContainer GVAR(unit), vestContainer GVAR(unit), backpackContainer GVAR(unit)];
private _list = [GVAR(container), GVAR(secondary), GVAR(nearby), _wornContainers];

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
// sibling of its class is taken out and the others put back (fnc_build finds it again) - and whether each
// still lies where it was opened: one moved away - put on, into the backpack - goes from the column, which
// a build does.
_list pushBack (GVAR(opened) select {!isNull (_x select 1)} apply {
    _x params ["", "_object", ["_parent", objNull]];

    [_object, isNull _parent || {(everyContainer _parent) findIf {(_x select 1) isEqualTo _object} >= 0}]
});

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

// ----- Storage -----

private _storage = [];

{
    private _container = _x getOrDefault ["container", objNull];

    if (!isNull _container) then {
        _storage pushBack [_forEachIndex, str [[_container] call _fnc_cargo, [_container] call _fnc_revision]];
    };
} forEach (GVAR(context) getOrDefault ["ownSections", []]);

// ----- Card -----

// ACE's virtual load, which the weight card counts (fnc_drawWeightCard). The weight overrides of the rules
// reach it a frame or two after a move - after the window was drawn for that move - and an Enhanced First
// Aid Kits kit changes it without any cargo changing. Where the tiers start: a changed threshold redraws the
// card within a second.
private _card = [
    ([GVAR(unit)] + _wornContainers) apply {_x getVariable [QACEGVAR(movement,vLoad), 0]},
    ([GVAR(unit)] call EFUNC(weight,getLimits)) get "key"
];

[_own, _list, _loot, _storage, _card]
