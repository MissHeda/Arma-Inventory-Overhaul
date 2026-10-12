#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Something was added to a uniform, vest or backpack in ACE Arsenal (its event cargoChanged): what has
 * no room on the container's grid comes straight back out, with the arsenal's own message - so the
 * arsenal never dresses a soldier with more than the inventory window can lay out.
 *
 * ACE asks the engine whether an item fits, and the engine only knows weight; nothing of ACE's can be
 * told otherwise without replacing it. So the item goes in first and the grid is asked afterwards. The
 * event comes after the add and before ACE redraws the list, so what is fixed here shows at once.
 *
 * How many arrived is counted, not assumed: Shift adds five, and the engine leaves out what is too
 * heavy. Of those, only as many come back out as the grid has no room for - with several at once the
 * ones that fit stay - and never anything the container held before, even if that did not fit either.
 *
 * Arguments:
 * 0: Arsenal display <DISPLAY>
 * 1: Item class <STRING>
 * 2: Added (above 0) or removed (-1 for the button, 0 for the arrow key) <NUMBER>
 * 3: Shift held - five at once <BOOL>
 *
 * Return Value:
 * How many came back out <NUMBER>
 *
 * Example:
 * [findDisplay 1127001, "30Rnd_65x39_caseless_mag", 1, false] call einv_arsenal_fnc_onCargoChanged;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_item", "", [""]], ["_addOrRemove", 0, [0]], ["_shift", false, [false]]];

// Taking out never fills a grid. In the editor the arsenal dresses a stand-in of the unit: left alone.
if (_addOrRemove <= 0 || {_item isEqualTo ""} || {is3DEN}) exitWith {0};

private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

([_center] call FUNC(getCargo)) params [["_index", -1], ["_container", objNull], ["_items", []]];

if (_index < 0) exitWith {0};

// How many really arrived: the count now against the last look (fnc_rememberCargo). That look only
// counts if nothing else changed in between and it holds no more of the item than there is now - an
// add takes nothing away. "Remove all" raises no event; XEH_postInit looks again by its button.
// Without that look, as many as ACE tried to add, as far as there are any.
private _tries = [1, 5] select _shift;
private _count = {_item == _x} count _items;

GVAR(snapshot) params ["", ["_before", objNull], ["_itemsBefore", []]];

private _known = false;

if (_before isEqualTo _container) then {
    private _others = _items select {_item != _x};
    private _othersBefore = _itemsBefore select {_item != _x};

    _others sort true;
    _othersBefore sort true;
    _known = _others isEqualTo _othersBefore && {_count >= ({_item == _x} count _itemsBefore)};
};

private _added = if (_known) then {
    _count - ({_item == _x} count _itemsBefore)
} else {
    _tries min _count
};

_added = _added min _tries;

if (_added < 1) exitWith {0};

// Whose container it is decides its compartments (einv_storage_fnc_getBlocks), and the engine does not
// say - fnc_getSections marks the unit's containers. The arsenal makes new ones with every uniform,
// vest or backpack it puts on, unmarked.
[_center] call EFUNC(storage,getSections);

// What lies nowhere on the grid with the newest k of the item taken away again - laid out the way the
// window would, without keeping that layout. Read anew every time: the layout changes the entries.
private _fnc_overflow = {
    params ["_k"];

    private _entries = [_container] call EFUNC(storage,getContents);

    // Only what fnc_removeEntry takes out comes off: full magazines, or anything without rounds to
    // count. A part-full magazine was there before - and stacks pile up by rounds, so it may well be
    // the last tile of its class. Off the last tiles first, so a short stack is emptied before a
    // full one.
    for "_i" from (count _entries - 1) to 0 step -1 do {
        if (_k <= 0) exitWith {};

        private _entry = _entries select _i;

        if ((_entry get "class") == _item && {(_entry get "capacity") <= 0 || {(_entry get "ammo") == (_entry get "capacity")}}) then {
            private _off = _k min (_entry get "count");

            _entry set ["count", (_entry get "count") - _off];
            _k = _k - _off;

            if ((_entry get "count") < 1) then {
                _entries deleteAt _i;
            };
        };
    };

    count (([_container, _entries, false] call EFUNC(storage,getLayout)) get "overflow")
};

private _overflow = [0] call _fnc_overflow;

if (_overflow == 0) exitWith {0};

// What did not fit before the add is not this add's fault: only as many come out as it takes to get
// back to that.
private _baseline = [_added] call _fnc_overflow;

if (_overflow <= _baseline) exitWith {0};

private _drop = _added;

for "_n" from 1 to (_added - 1) do {
    if (([_n] call _fnc_overflow) <= _baseline) exitWith {_drop = _n};
};

// Full magazines are the ones that just came in, so those are the ones that leave.
private _info = [_item] call EFUNC(items,getInfo);
private _entry = createHashMapFromArray [["class", _item], ["count", _drop], ["ammo", _info get "capacity"]];

[_container, _entry, _drop] call EFUNC(storage,removeEntry);

([_center] call FUNC(getCargo)) params ["", "", ["_itemsNow", []]];

private _countNow = {_item == _x} count _itemsNow;
private _removed = _count - _countNow;

// Nothing could be taken back out (einv_storage_fnc_removeEntry says why in the RPT).
if (_removed < 1) exitWith {0};

// ACE wrote its count, its own list of the container and the load bar before raising the event - they
// still show the item that left. The colours, the "+" button and the weight it redraws right after.
private _list = _display displayCtrl ARSENAL_IDC_LIST;
private _row = lnbCurSelRow _list;

if (_row >= 0 && {(_list lnbData [_row, 0]) == _item}) then {
    _list lnbSetText [[_row, 2], str _countNow];
};

private _currentItems = missionNamespace getVariable [QACEGVAR(arsenal,currentItems), []];

if (_currentItems isEqualType [] && {count _currentItems > ARSENAL_ITEMS_BACKPACK}) then {
    private _loadout = (getUnitLoadout _center) select ([LOADOUT_UNIFORM, LOADOUT_VEST, LOADOUT_BACKPACK] select _index);

    _currentItems set [[ARSENAL_ITEMS_UNIFORM, ARSENAL_ITEMS_VEST, ARSENAL_ITEMS_BACKPACK] select _index, _loadout param [1, []]];
};

(_display displayCtrl ARSENAL_IDC_LOAD) progressSetPosition ([loadUniform _center, loadVest _center, loadBackpack _center] select _index);

if (!isNil QACEFUNC(arsenal,message)) then {
    [_display, format [LLSTRING(NoRoom), _info get "name"]] call ACEFUNC(arsenal,message);
};

// ACE decides whether "Remove all" shows from the list it read before the item came back out: asked
// again a frame later, when the container may be empty now.
if (!isNil QACEFUNC(arsenal,updateRightPanel)) then {
    [{
        private _display = findDisplay ARSENAL_IDD;
        private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

        ([_center] call FUNC(getCargo)) params [["_index", -1], ["_container", objNull], ["_items", []]];

        if (isNull _display || {_index < 0}) exitWith {};

        [_display displayCtrl ARSENAL_IDC_LIST, _container, _items isNotEqualTo []] call ACEFUNC(arsenal,updateRightPanel);
    }] call CBA_fnc_execNextFrame;
};

_removed
