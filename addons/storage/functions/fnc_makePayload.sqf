#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A payload for something that is made rather than taken from somewhere - what fnc_addNew puts in - in
 * the shape fnc_addPayload and fnc_putOn expect (the shapes fnc_removeEntry makes).
 *
 *   magazine, grenade - ["magazine", class, [rounds, ...]], one entry of rounds for each, full unless said
 *   backpack          - ["backpack", class, empty], a snapshot of nothing, so a backpack that comes with
 *                       things in its config comes empty
 *   weapon, binocular - ["weapon", [class, "", "", "", [], [], ""]]: bare, without the attachments and
 *                       the magazine its class might bring - an attachment is put on as an item of its own
 *   anything else     - ["item", class, count, []]; a uniform or vest has nothing in it to start with
 *
 * What an item is comes from the rules in force (einv_items_fnc_getInfo). A weapon or a backpack is one
 * thing: for several, make several payloads.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: How many <NUMBER> (default: 1)
 * 2: Rounds in each magazine, -1 for full ones <NUMBER> (default: -1)
 *
 * Return Value:
 * Payload, [] for no class <ARRAY>
 *
 * Example:
 * ["30Rnd_65x39_caseless_mag", 3] call einv_storage_fnc_makePayload;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_count", 1, [0]], ["_rounds", -1, [0]]];

if (_class isEqualTo "") exitWith {[]};

_count = _count max 1;

private _magazine = configFile >> "CfgMagazines" >> _class;

if (isClass _magazine) exitWith {
    private _capacity = getNumber (_magazine >> "count");
    private _full = [_capacity, (_rounds min _capacity) max 0] select (_rounds >= 0);
    private _list = [];

    for "_i" from 1 to _count do {
        _list pushBack _full;
    };

    ["magazine", _class, _list]
};

switch (([_class] call EFUNC(items,getInfo)) getOrDefault ["kind", ""]) do {
    case "backpack": {["backpack", _class, [[[], []], [], [], [[], []], []]]};
    case "rifle";
    case "handgun";
    case "launcher";
    case "binocular": {["weapon", [_class, "", "", "", [], [], ""]]};
    default {["item", _class, _count, []]};
}
