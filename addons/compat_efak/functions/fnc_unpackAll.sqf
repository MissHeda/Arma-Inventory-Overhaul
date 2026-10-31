#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Unpack everything (the context menu, fnc_menuChoices): every tile of a kit into the player's own
 * gear, each into the first container with room - the kit's "take into" choice first (fnc_ownTargets).
 * What finds no room stays in the kit, and the hint says so: the window never drops anything by
 * itself, unlike Enhanced First Aid Kits' own kit window.
 *
 * Planned here against the player's gear as it is, each tile counted against the room the ones before
 * it take (a free spot by aio_storage_fnc_getLayout; weight limits nothing) - then sent as
 * moves of the window's transactions (aio_gui_fnc_sendMoves), out of the kit at its root's authority
 * and into the player's gear. Whatever does not fit there by then goes back into the kit
 * (aio_storage_fnc_settle). An emptied kit goes when its type says so (fnc_opKitTake). Out of a kit in
 * a living person's gear only as the window's settings for it say (aio_gui_fnc_checkTouch).
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Where the kit lies, [container, kit] <ARRAY> (default: [objNull, ""])
 *
 * Return Value:
 * Something was sent <BOOL>
 *
 * Example:
 * ["efak_IFAK_7", [backpackContainer player, ""]] call aio_compat_efak_fnc_unpackAll;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_holder", [objNull, ""], [[]]]];

private _fnc_refuse = {
    params ["_why"];

    [_why] call EFUNC(gui,flashHint);
    false
};

if (_kit isEqualTo "") exitWith {false};

private _wait = call FUNC(notReady);

if (_wait isNotEqualTo "") exitWith {[_wait] call _fnc_refuse};

// What it holds before it is emptied, for the packing-off rule (fnc_repackable): a kit unpacked from
// its tile's menu was never opened in this window, and with no note of it nothing could go back.
[_kit] call FUNC(snapshot);

// Where its tile lies, else where the kit windows found it.
private _where = ([_kit, [[], _holder] select (_holder isNotEqualTo [objNull, ""])] call FUNC(locate)) select 1;

if (isNull _where) exitWith {["Failed"] call _fnc_refuse};

// Only while the player may still reach it where it lies now (fnc_mayReach).
if !([_where] call FUNC(mayReach)) exitWith {[LLSTRING(NotYours)] call _fnc_refuse};

// In a living person's gear only as the settings for it say (aio_gui_fnc_checkTouch).
private _touch = [_where, "items"] call EFUNC(gui,checkTouch);

if (_touch isNotEqualTo "") exitWith {[_touch] call _fnc_refuse};

private _key = "kit:" + toLowerANSI _kit;
private _root = [_where] call EFUNC(storage,rootOf);

if (isNull _root) exitWith {["Failed"] call _fnc_refuse};

// Each own container as it is: what it holds, and below what is planned into it.
private _targets = ([_kit] call FUNC(ownTargets)) apply {
    [_x, [_x] call EFUNC(storage,getContents), []]
};

private _unit = EGVAR(gui,unit);
private _moves = [];
private _left = false;

{
    private _entry = _x;
    private _class = _entry get "class";
    private _probe = createHashMapFromArray [["class", _class], ["count", _entry get "count"]];

    private _index = _targets findIf {
        _x params ["_container", "_contents", "_planned"];

        // Never a backpack into a backpack
        !([_container, _entry] call EFUNC(storage,backpackIntoBackpack))
        // A free spot - as aio_storage_fnc_hasSpace asks it, with what goes in before this one.
        && {
            (([_container] call EFUNC(storage,getBlocks)) isEqualTo [])
            || {
                [_container, _contents + _planned + [_probe]] call EFUNC(storage,getLayout);
                !(_probe getOrDefault ["overflow", true])
            }
        }
    };

    if (_index < 0) then {
        _left = true;
        continue;
    };

    private _target = _targets select _index;

    (_target select 2) pushBack _probe;

    _moves pushBack createHashMapFromArray [
        ["kind", "move"], ["from", _key], ["fromRoot", _root], ["entry", _entry], ["count", -1],
        ["to", _target select 0], ["toRoot", _unit], ["cell", []]
    ];
} forEach ([_kit, true] call FUNC(getEntries));

if (_moves isEqualTo []) exitWith {["NowhereToGo"] call _fnc_refuse};

private _sent = [_moves, createHashMapFromArray [["flash", true]]] call EFUNC(gui,sendMoves);

if (_sent && {_left}) then {
    [LLSTRING(RestStays)] call EFUNC(gui,flashHint);
};

_sent
