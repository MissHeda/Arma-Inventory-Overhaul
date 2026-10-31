#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether a container's contents have to be searched before this player sees them: loot only - never
 * the player's own uniform, vest or backpack - and only the kinds the settings name: what a body
 * carries, what a living person carries (aio_gui_fnc_openPerson), crates and vehicles (the cargo of the
 * one the player sits in too), loose items on the ground. A mission leaves out a single object with
 * aio_noSearch on it. A search time of 0 means no searching at all, and so does a factor of 0 for the
 * kind of box (fnc_searchTime: uniforms, vests, backpacks, crates, vehicles, the ground, bodies).
 *
 * A uniform, vest or backpack that came off a body or a living person unsearched carries that with it
 * (aio_storage_searchState, written by aio_storage_fnc_takeOff and carried to every new object the
 * engine makes of it): it is searched as that body or person is, wherever it lies now - on the ground,
 * in a crate, opened from inside either. Whoever searched it before keeps it searched (fnc_searchRecord).
 *
 * An ACE arsenal box never is: it is there to hand things out, not to be looted
 * (aio_arsenal_fnc_isArsenalBox - asked only when that addon is loaded).
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * Has to be searched <BOOL>
 *
 * Example:
 * [cursorObject] call aio_gui_fnc_isSearched;
 *
 * Public: No
 */

params ["_container"];

if (isNull _container || {GVAR(searchTime) <= 0}) exitWith {false};

private _unit = GVAR(unit);

if (_container in [uniformContainer _unit, vestContainer _unit, backpackContainer _unit]) exitWith {false};

// Taken off a body or a person unsearched: searched as they are, while the setting for them is on - not once it lies in
// what the player carries himself (aio_storage_fnc_rootOf), which is his gear, never searched.
private _source = (_container getVariable [QEGVAR(storage,searchState), []]) param [1, "", [""]];
private _carried = ((_source isEqualTo "body" && {GVAR(searchBodies)}) || {_source isEqualTo "person" && {GVAR(searchPersons)}})
    && {!([_container] call FUNC(isOwnStorage))};

// A uniform, vest or backpack opened from inside a container: as that container is - unless it carries its own search.
private _opened = GVAR(opened) findIf {(_x select 1) isEqualTo _container};

private _searched = call {
    if (_opened >= 0 && {!_carried}) exitWith {
        [(GVAR(opened) select _opened) param [2, objNull]] call FUNC(isSearched)
    };

    // An arsenal box. Asked of the container itself, so a body - looked into through its uniform, vest and
    // backpack - never counts as one.
    if (!isNil QEFUNC(arsenal,isArsenalBox) && {[_container] call EFUNC(arsenal,isArsenalBox)}) exitWith {false};

    // A body's or a living person's uniform, vest and backpack belong to them.
    private _owner = ([_container] call EFUNC(storage,getOwner)) select 0;
    private _object = [_container, _owner] select (!isNull _owner);

    if (_object getVariable [QGVARMAIN(noSearch), false] || {_container getVariable [QGVARMAIN(noSearch), false]}) exitWith {false};

    switch (true) do {
        case (_object isKindOf "CAManBase"): {[GVAR(searchBodies), GVAR(searchPersons)] select (alive _object)};
        case (_carried): {true};
        case ([_container] call EFUNC(storage,isGroundHolder)): {GVAR(searchGround)};
        // A backpack lying about as an object of its own - thrown down, set by a mission - is no crate and no pile: it is
        // searched when either is, or it would be a way round the search ("Open" on a bag that was thrown on the ground).
        case (_container isKindOf "Bag_Base"): {GVAR(searchGround) || {GVAR(searchContainers)}};
        default {GVAR(searchContainers)};
    }
};

// A kind of box the server gave no search time is shown at once.
_searched && {([_container] call FUNC(searchTime)) > 0}
