#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The kits that lie in the given containers, each as a section with its grid (fnc_kitSection), for the ACE
 * Arsenal's panel: a kit is filled there as a container is - things dragged out of ACE's list onto its grid,
 * out of it to take them away, to and from the soldier's containers. One section per kit class, in the order
 * of the containers and of their cargo; the kit is looked for in the cargo of each container, and in what
 * Strict mode's hidden holder keeps for it (einv_storage_fnc_hiddenClasses). A kit that lies in another kit
 * is not unfolded. Nothing without Enhanced First Aid Kits' registry knowing the class (fnc_isKit).
 *
 * Where each kit lies is kept in GVAR(arsenalHolders), anew at every call (an empty list empties it): no kit
 * window is open in ACE's window, so GVAR(holders) knows none of them, and a move between a kit's grid and the
 * staging space or a container (fnc_drop) found the kit nowhere and was refused - in either measure of its room.
 *
 * Arguments:
 * 0: The containers to look in - uniform, vest, backpack, the staging space <ARRAY of OBJECTs>
 *
 * Return Value:
 * Sections, see fnc_getSections; "container" is objNull and "parent" the container the kit lies in <ARRAY of HASHMAPs>
 *
 * Example:
 * [[uniformContainer player, vestContainer player]] call einv_compat_efak_fnc_arsenalSections;
 *
 * Public: No
 */

params [["_holders", [], [[]]]];

private _seen = createHashMap;
private _sections = [];

{
    private _container = _x;

    if (isNull _container) then {continue};

    private _classes = ((getItemCargo _container) param [0, []]) + ([_container] call EFUNC(storage,hiddenClasses));

    {
        private _lower = toLowerANSI _x;

        if (_lower in _seen || {!([_x] call FUNC(isKit))}) then {continue};

        // Where it lies, as GVAR(holders) notes it for a kit window: [container, kit it is packed in].
        _seen set [_lower, [_container, ""]];
        _sections pushBack ([_x, _container, "", _container] call FUNC(kitSection));
    } forEach _classes;
} forEach _holders;

GVAR(arsenalHolders) = _seen;

_sections
