#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The root of a kit holder, for the storage's transactions (einv_storage_holderTypes "kit" "root",
 * einv_storage_fnc_rootOf): the root of the container the kit lies in, or of the container the
 * outermost kit it is packed in lies in. Each answer only once the kit really lies under it
 * (fnc_holderVerify), tried in this order:
 *   the hint einv_storage_fnc_rootOf passes on - a container it lies in or a root it lay under, e.g.
 *   the root of the phase it was taken out in, which settlement puts it back by - and that one's root
 *   where the kit windows were last drawn found it (fnc_locate)
 *   the gear of the unit this machine controls
 * A kit's tile in a container the window shows has its root from that container instead (fnc_drop): a
 * kit no window opened is known here only through its tile. A machine without a window - the server,
 * a headless client - knows a kit's root only from the hint.
 *
 * Any machine may ask; the machine that runs the op checks again (fnc_holderVerify).
 *
 * Arguments:
 * 0: Holder, "kit:" + the lowercase class <STRING>
 * 1: Hint - a container the kit lies in, or a root it lay under <OBJECT> (default: objNull)
 *
 * Return Value:
 * Root, objNull when the kit is found nowhere <OBJECT>
 *
 * Example:
 * ["kit:efak_ifak_7"] call einv_compat_efak_fnc_holderRoot;
 * ["kit:efak_ifak_7", _crate] call einv_compat_efak_fnc_holderRoot;
 *
 * Public: No
 */

params [["_holder", "", [""]], ["_hint", objNull, [objNull]]];

if ((_holder select [0, 4]) isNotEqualTo "kit:") exitWith {objNull};

private _candidates = [];

// A container's root - the hint itself only when it has none, being a root already: a uniform, vest or
// backpack is never the root of what lies in it.
if (!isNull _hint) then {
    private _base = [_hint] call EFUNC(storage,rootOf);

    _candidates pushBack ([_base, _hint] select (isNull _base));
};

private _where = ([_holder select [4]] call FUNC(locate)) select 1;

if (!isNull _where) then {
    _candidates pushBack ([_where] call EFUNC(storage,rootOf));
};

// The player's own gear - or that of the unit a Zeus controls.
_candidates pushBack (call CBA_fnc_currentUnit);

private _index = _candidates findIf {!isNull _x && {[_holder, _x] call FUNC(holderVerify)}};

if (_index < 0) exitWith {objNull};

_candidates select _index
