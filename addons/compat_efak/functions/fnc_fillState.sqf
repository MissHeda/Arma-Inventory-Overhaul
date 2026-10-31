#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How full a kit is, in the measure its room is counted in (fnc_roomMode): Enhanced First Aid Kits'
 * mass against its capacity, "12 / 35 mass", while that is its room; the cells its tiles take against
 * the cells of its grid, "8 / 12 cells", once a rule or its config gives it one - whatever that mod's
 * capacity says, it no longer limits anything. Over: fuller than its capacity, or tiles that found no
 * cell (a grid given to a kit that was full already - they show apart and are never lost). For the
 * title of its window (fnc_getSections), the hint (fnc_hintParts) and the inspect card
 * (fnc_inspectRows). The numbers themselves too, for the title of a kit's section in ACE Arsenal's
 * panel, "Kit: IFAK (8/12)" (fnc_arsenalKit): the mass rounded as the text has it.
 *
 * Arguments:
 * 0: Kit class <STRING>
 *
 * Return Value:
 * [text, over, used, room] <ARRAY>
 *
 * Example:
 * (["efak_IFAK_7"] call aio_compat_efak_fnc_fillState) params ["_text", "_over"];
 *
 * Public: No
 */

params [["_kit", "", [""]]];

if (([_kit] call FUNC(roomMode)) isEqualTo "cells") exitWith {
    private _layout = ["kit:" + toLowerANSI _kit, [_kit] call FUNC(getEntries), false] call EFUNC(storage,getLayout);
    private _used = 0;
    private _total = 0;

    {
        if !(_x getOrDefault ["overflow", false]) then {
            _used = _used + (_x getOrDefault ["w", 1]) * (_x getOrDefault ["h", 1]) - count (_x getOrDefault ["holes", []]);
        };
    } forEach (_layout getOrDefault ["entries", []]);

    {
        _total = _total + (_x select 0) * (_x select 1) - count (_x param [2, []]);
    } forEach (_layout getOrDefault ["blocks", []]);

    [format [LLSTRING(FillCells), _used, _total], (_layout getOrDefault ["overflow", []]) isNotEqualTo [], _used, _total]
};

// The kit's class, as fnc_canPack passes it too (that mod reads a class or a contents list alike).
private _used = [_kit] call EFAKFUNC(core,getUsedCapacity);
private _capacity = [_kit] call EFAKFUNC(core,getCapacity);

[
    format ["%1 / %2 %3", round _used, round _capacity, localize "STR_efak_gui_MassUnit"], _used > _capacity + KIT_MASS_EPSILON,
    round _used, round _capacity
]
