#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Money the player carries is money: Antistasi (HALs money, hals\Addons\money) turns the four money items into funds
 * on the engine's Take - removes the item and adds HALs_money_oldManItemsPrice of it to the player's funds. The
 * window's moves raise no Take, so here the same is done for what lies in the player's uniform, vest and backpack,
 * whenever the gear changed (CBA's loadout event, XEH_postInit) and once an arsenal closed. Not while an arsenal is
 * open (its loadouts may hold money as an item) nor with HALs' money missing. Items and magazines alike: Antistasi
 * calls them money magazines, and removeItem takes either.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The funds added <NUMBER>
 *
 * Example:
 * call aio_compat_antistasi_fnc_convertMoney;
 *
 * Public: No
 */

private _unit = player;

if (
    isNull _unit || {!alive _unit} || {ARSENAL_OPEN}
    || {isNil "HALs_money_fnc_addFunds"} || {isNil "HALs_money_oldManItemsPrice"}
    || {!(HALs_money_oldManItemsPrice isEqualType [])}
) exitWith {0};

// Antistasi's order: Money_bunch, Money_roll, Money_stack, Money.
private _index = createHashMapFromArray [["money_bunch", 0], ["money_roll", 1], ["money_stack", 2], ["money", 3]];
private _total = 0;

{
    private _at = _index getOrDefault [toLowerANSI _x, -1];

    if (_at >= 0) then {
        private _value = HALs_money_oldManItemsPrice param [_at, 0];

        if (_value isEqualType 0 && {_value > 0}) then {
            _unit removeItem _x;
            _total = _total + _value;
        };
    };
} forEach (itemsWithMagazines _unit);

// The window shows the new funds on its footer (fnc_moneyText) - it is built anew, the money item being gone.
if (_total > 0) then {
    [_unit, _total] call HALs_money_fnc_addFunds;
    call EFUNC(gui,requestRebuild);
};

_total
