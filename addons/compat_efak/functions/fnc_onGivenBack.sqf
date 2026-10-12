#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The Enhanced Arsenal gives back something that lies in a kit: it comes out of the kit (what the kit's
 * window does for a take - the kit's contents written, the tile's record gone, a magazine with the rounds
 * it was kept with) and the arsenal discards it. Only while the kit's arsenal setting lets the arsenal take
 * things out (fnc_arsenalEditing: take out only or everything). A kit that is empty after that and is set
 * to go when empty goes (fnc_removeIfEmpty), as it does in the inventory.
 *
 * Written where it is called: the kit has to lie under the root named, the unit whose gear it is.
 *
 * Arguments:
 * 0: Kit class, an instance <STRING>
 * 1: The tile as the window saw it <HASHMAP>
 * 2: How many, -1 for the whole tile <NUMBER> (default: -1)
 * 3: The unit whose gear the kit lies in, objNull to take it for granted <OBJECT> (default: objNull)
 *
 * Return Value:
 * [status - "" when it came out, "ReadOnly" for a kit the arsenal may not take from, "Gone" when it was
 *  not there, else a word for einv_gui_fnc_flashHint -, the payload that came out as the storage knows
 *  payloads or [], whether the emptied kit went too] <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7", _tile, -1, player] call einv_compat_efak_fnc_onGivenBack;
 *
 * Public: No
 */

params [
    ["_kit", "", [""]], ["_entry", createHashMap, [createHashMap]], ["_count", -1, [0]], ["_root", objNull, [objNull]]
];

if (_kit isEqualTo "" || {count _entry == 0}) exitWith {["Failed", [], false]};

if (([_kit] call FUNC(arsenalEditing)) < 1) exitWith {["ReadOnly", [], false]};

// Written here only for a unit of this machine: its gear's transactions run here too - one writer.
if (!isNull _root && {!local _root}) exitWith {["Failed", [], false]};
if (!isNull _root && {!([("kit:" + toLowerANSI _kit), _root] call FUNC(holderVerify))}) exitWith {["Gone", [], false]};

([_kit, _entry, _count] call FUNC(takeFromKit)) params ["_status", "_payload"];

if (_status isNotEqualTo "") exitWith {[_status, [], false]};

private _removed = !isNull _root && {[_kit, _root] call FUNC(removeIfEmpty)};

[] call FUNC(requestRebuild);

["", _payload, _removed]
