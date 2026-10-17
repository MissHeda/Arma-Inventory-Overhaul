#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the strip at the side of a loot box lists (fnc_drawGroupStrip): "All" first, then every category there is (the eight
 * built-in ones and the setup's own, einv_items_fnc_categories) with its picture and its name. When they do not fit
 * the STRIP_SLOTS fields, All stays on top, the categories come STRIP_SLOTS - 2 at a time and the last field is "more",
 * which turns to the next group (fnc_stripMore).
 *
 * Arguments:
 * 0: Which group of categories, counted from 0 - held to what there is <NUMBER> (default: 0)
 *
 * Return Value:
 * [entries, pages, page] <ARRAY>
 *   entries - [[id, texture, name], ...], at most STRIP_SLOTS; the id "all" or "more" for those two <ARRAY>
 *   pages   - how many groups there are, 1 when everything fits <NUMBER>
 *   page    - the group these entries are of <NUMBER>
 *
 * Example:
 * [1] call einv_gui_fnc_stripEntries;
 *
 * Public: No
 */

params [["_page", 0, [0]]];

private _all = [["all", UI_TEX(slot_cat_all_ca), LLSTRING(Group_All)]];

{
    _all pushBack [_x, [_x] call FUNC(groupTexture), (([_x] call EFUNC(items,categoryInfo)) get "label")];
} forEach ([] call EFUNC(items,categories));

if (count _all <= STRIP_SLOTS) exitWith {[_all, 1, 0]};

private _perPage = STRIP_SLOTS - 2;
private _rest = _all select [1];
private _pages = ceil (count _rest / _perPage);

_page = (_page max 0) min (_pages - 1);

private _entries = [_all select 0] + (_rest select [_page * _perPage, _perPage]);

_entries pushBack ["more", UI_TEX(icon_chevron_down_ca), format [LLSTRING(Group_More), _page + 1, _pages]];

[_entries, _pages, _page]
