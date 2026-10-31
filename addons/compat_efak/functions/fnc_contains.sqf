#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a kit is - or holds, anywhere down its kits packed in kits - another kit. A kit put into
 * itself, or into a kit packed inside it, would be gone for good; Enhanced First Aid Kits itself only
 * keeps kits out of kits altogether (efak_core_allowNesting), so where a mission lets them in, this
 * keeps a kit out of itself. Followed only so deep: a kit nobody has carried holds nothing.
 *
 * Arguments:
 * 0: The kit - or any item, which holds nothing <STRING>
 * 1: The kit looked for <STRING>
 * 2: How deep it is already, for itself <NUMBER> (default: 0)
 *
 * Return Value:
 * It is or holds it <BOOL>
 *
 * Example:
 * ["efak_IFAK_3", "efak_IFAK_7"] call aio_compat_efak_fnc_contains;
 *
 * Public: No
 */

params [["_outer", "", [""]], ["_inner", "", [""]], ["_depth", 0, [0]]];

if (_outer == _inner) exitWith {true};

if (
    _depth >= KIT_MAX_DEPTH
    || {!([_outer] call FUNC(isKit))}
    || {toLowerANSI _outer in (missionNamespace getVariable [QEFAKGVAR(core,needsConversion), createHashMap])}
) exitWith {false};

(([_outer] call EFAKFUNC(core,getContents)) findIf {[_x select 0, _inner, _depth + 1] call FUNC(contains)}) >= 0
