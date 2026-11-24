#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Antistasi's SCRT_fnc_paradrop_jump (the HALO jump, scheduled, on the jumper's machine): it hangs the backpack on
 * the jumper's legs, gives them a parachute and, once they land, puts a new backpack of the class on and adds back
 * what backpackItems listed - every magazine full, weapons and their parts lost, nothing on its cell. Here the
 * backpack is noted before the jump as the loadout has it (its contents, rounds and weapons with their parts) with
 * where everything lay (fnc_layoutOf); Antistasi's jump runs as it ships (fnc_patched), and after it the backpack
 * is set back as it was and its places written (fnc_restorePlaces). Strict mode's hidden holder is given back to the
 * containers first, so the backpack holds all of it; it is taken again by the next look (aio_storage_fnc_requestMigrate).
 *
 * Nothing is changed when the jumper has no backpack, died, or wears another backpack after it.
 *
 * Arguments:
 * As SCRT_fnc_paradrop_jump: the jumper <OBJECT>
 *
 * Return Value:
 * As SCRT_fnc_paradrop_jump
 *
 * Public: No
 */

private _jumper = _this;
private _pack = [];
private _layout = [];

if (_jumper isEqualType objNull && {local _jumper} && {backpack _jumper isNotEqualTo ""}) then {
    if (!isNil {_jumper getVariable "aio_storage_hidden"}) then {
        [_jumper] call EFUNC(storage,hiddenReturn);
    };

    _pack = (getUnitLoadout _jumper) param [5, []];
    _layout = [_jumper] call FUNC(layoutOf);
};

private _result = _this call (["paradropJump", A3A_FILE_PARADROP, []] call FUNC(patched));

if (_pack isEqualTo [] || {!alive _jumper} || {backpack _jumper isNotEqualTo (_pack param [0, ""])}) exitWith {
    if (!isNil "_result") then {_result}
};

private _loadout = getUnitLoadout _jumper;

_loadout set [5, _pack];
_jumper setUnitLoadout _loadout;

[_jumper, _layout] call FUNC(restorePlaces);

if (!isNil "_result") then {_result}
