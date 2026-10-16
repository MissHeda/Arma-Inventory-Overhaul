#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether this player may see the setup wizard at all - the one gate every way into it passes: the
 * keybind and the inventory's cog (fnc_openFromGame, before the inventory closes for it), a mission's own
 * call (fnc_open), CBA's Addon Options button (fnc_initCbaMenu) and ESC > Options, where the engine makes
 * the display itself and only its onLoad can still say no (fnc_onLoad). Saving is a question of its own
 * (fnc_canEdit); this one is whether the wizard exists for the player.
 *
 * Only who runs the server: single player, a hosted game's host and the dedicated server itself, or a
 * logged-in admin (#kick is there for a logged-in admin and a voted one alike - both run the server for the
 * session). Everyone else never sees it, nor is told it exists: no button, a key that does nothing, and a
 * window the pause menu's entry closes again without a word. The editor always may - it is the mission
 * maker's. There is no setting for it. Asked whenever a way in is drawn or taken, so an admin who logs
 * in or out is noticed at the next draw (the game has no event for it).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * May see the wizard <BOOL>
 *
 * Example:
 * call einv_setup_fnc_canOpen;
 *
 * Public: Yes
 */

is3DEN || {isServer} || {!isMultiplayer} || {serverCommandAvailable "#kick"}
