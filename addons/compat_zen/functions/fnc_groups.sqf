#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The groups a lock can be given to: every group of the four sides with someone alive in it, sorted by
 * side and then by callsign. The label tells them apart: "BLUFOR - Alpha 1-1".
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[group, label], ...] <ARRAY>
 *
 * Example:
 * call einv_compat_zen_fnc_groups;
 *
 * Public: No
 */

private _sides = [west, east, independent, civilian];
private _names = [LELSTRING(locks,Side_West), LELSTRING(locks,Side_East), LELSTRING(locks,Side_Independent), LELSTRING(locks,Side_Civilian)];
private _entries = [];

{
    private _group = _x;
    private _sideIndex = _sides find (side _group);

    if (_sideIndex >= 0 && {(units _group) findIf {alive _x} >= 0}) then {
        private _callsign = groupId _group;

        // The running number settles two groups with one callsign before the sort could compare groups.
        _entries pushBack [_sideIndex, toLowerANSI _callsign, _forEachIndex, _group, format ["%1 - %2", _names select _sideIndex, _callsign]];
    };
} forEach allGroups;

_entries sort true;

_entries apply {[_x select 3, _x select 4]}
