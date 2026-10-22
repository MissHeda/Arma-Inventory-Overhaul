#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The controls of Enhanced First Aid Kits' kits tab in ACE Arsenal that the panel works with: the list of what the
 * picked kit may hold - the tab's right list, at the place of ACE's own and built like it, which items are dragged
 * out of into the kit's grid and greyed by its room (einv_arsenal_fnc_listDrag, einv_arsenal_fnc_ungreyKit) -, the
 * tab's sort bar, where ACE's own is (einv_arsenal_fnc_panelRect), and the "-" and "+" of that list, which lie over
 * the row picked (einv_arsenal_fnc_onListPress). They are part of ACE's display from that mod's config, there from
 * the start and hidden while the tab is closed; null where that mod's arsenal addon is not loaded.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 *
 * Return Value:
 * [list <CONTROL>, sort bar <CONTROL>, [IDC of "-", IDC of "+"] <ARRAY>] <ARRAY>
 *
 * Example:
 * ([findDisplay 1127001] call einv_compat_efak_fnc_arsenalControls) params ["_list", "_sort", "_arrows"];
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

[_display displayCtrl EFAK_IDC_CONTENTS, _display displayCtrl EFAK_IDC_SORT, [EFAK_IDC_ARROW_MINUS, EFAK_IDC_ARROW_PLUS]]
