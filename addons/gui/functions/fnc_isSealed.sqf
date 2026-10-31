#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether a container is drawn sealed (as Tarkov does it): a box this player has to search (fnc_isSearched) and has not
 * opened yet - a body's or a living person's uniform, vest or backpack, a crate, a vehicle's cargo, a pile on the ground,
 * a bag lying about, a uniform, vest or backpack opened from inside a container, and one that came off a body unsearched
 * wherever it lies now. Sealed, its section is one fixed block marked "Unsearched" (fnc_drawSection): neither how big it is
 * nor what it holds shows, not in the grid, the caption's weight, the hint or the search's time.
 *
 * Its search starts with the seal (fnc_markHidden queues it alone, first); when that is done fnc_animateSearch opens it -
 * the window is built with the real grid, every item a hatched footprint, and the items are found one by one.
 *
 * Opened is this player's own knowledge (fnc_searchRecord "unsealed"), never broadcast; it goes with a uniform, vest or
 * backpack wherever it is moved. A box whose every entry this player knows already - he put all of it there himself, a pile
 * he dropped onto - is open to him at once, and stays so.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * Sealed <BOOL>
 *
 * Example:
 * [uniformContainer cursorObject] call aio_gui_fnc_isSealed;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container || {!([_container] call FUNC(isSearched))}) exitWith {false};

private _record = [_container] call FUNC(searchRecord);

if (_record getOrDefault ["unsealed", false]) exitWith {false};

// Nothing known of it: sealed - also an empty one, which takes a search to know it is empty.
private _known = _record getOrDefault ["known", createHashMap];

if (count _known == 0) exitWith {true};

// Everything in it known already: open, from now on.
private _entries = [_container] call EFUNC(storage,getContents);

if (_entries isEqualTo []) exitWith {true};

private _counts = createHashMap;

{
    private _key = toLowerANSI (_x getOrDefault ["class", ""]);

    _counts set [_key, (_counts getOrDefault [_key, 0]) + 1];
} forEach _entries;

private _all = true;

{
    if (_y > (_known getOrDefault [_x, 0])) exitWith {
        _all = false;
    };
} forEach _counts;

if (_all) then {
    ([_container, true] call FUNC(searchRecord)) set ["unsealed", true];
};

!_all
