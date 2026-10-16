#define COMPONENT storage
#define COMPONENT_BEAUTIFIED EINV - Storage
#include "\z\einv\addons\main\script_mod.hpp"
#include "\z\einv\addons\main\script_macros.hpp"

// How far from a unit a pile on the ground still counts as at its feet (fnc_getGroundHolder).
#define GROUND_RANGE 2

// How long after writing places the authority looks whether an older write overtook its own, in seconds
// (fnc_writePlaces, the heal). Used as an array literal in code only - never handed to a macro, whose
// arguments must not hold commas.
#define HEAL_DELAYS [1.5, 6]

// Extra metres beyond the reach setting a request may come from: positions reach the authority late
// (fnc_inReach).
#define REACH_SLACK 2

// The hub sends an unanswered phase again after this many seconds - the same attempt, answered from the
// journal should it have run already (fnc_hubTick).
#define PHASE_RESEND 10

// After a root changed owner, the new owner gets its first phase this many seconds later: the engine tells
// the old and the new owner separately, so for a moment both can see it local (fnc_hubRoute).
#define LOCALITY_SETTLE 1

// A phase answered "NotLocal" is tried again after attempt x NOTLOCAL_BACKOFF seconds, at most
// NOTLOCAL_TRIES times (fnc_hubPhaseDone).
#define NOTLOCAL_BACKOFF 0.5
#define NOTLOCAL_TRIES 5

// A root whose owner left and that has no new owner after this many seconds: its phases count as
// "Moved" and what they carry is settled (fnc_hubRoute, fnc_hubTick).
#define ROUTE_TIMEOUT 15

// How long a machine remembers the phases it ran, in seconds (GVAR(journal), fnc_tick).
#define JOURNAL_KEEP 300

// Ops one frame runs at most, whole phases only - at least one phase per frame (fnc_tick): many players
// emptying crates at once spread over a few frames instead of stalling one.
#define PHASE_FRAME_OPS 30

// The player's own containers, changed by their own moves, are broadcast at most this often, in seconds
// (fnc_flushPlaces): sixty players sorting their gear must not flood the network.
#define OWN_WRITE_DELAY 2

// An authority re-writes a holder for a viewer's stale copy at most this often, in seconds
// (fnc_opNormalize).
#define FORCE_REPEAT 30

// How often the server looks at held phases and re-sends, in seconds (fnc_tick, fnc_hubTick).
#define HUB_TICK 0.25

// Surplus migration (fnc_queueMigrate, fnc_tickMigrate, fnc_requestMigrate, fnc_opMigrate). A unit whose cargo
// changed is looked at MIGRATE_DELAY seconds later, so a script adding twenty items over a few frames is one
// look; the waiting units are looked at every MIGRATE_TICK seconds, MIGRATE_PER_TICK of them at most. A request
// that was not carried out (the server not ready, the unit changed hands) is asked again after MIGRATE_RETRY
// seconds, at most MIGRATE_TRIES times; under an arsenal the unit waits MIGRATE_WAIT seconds at a time.
#define MIGRATE_DELAY 0.3
#define MIGRATE_TICK 0.25
#define MIGRATE_PER_TICK 3
#define MIGRATE_RETRY 3
#define MIGRATE_TRIES 3
#define MIGRATE_WAIT 1

// ACE Arsenal's display (1127001, ARSENAL_IDD of the arsenal addon) or the vanilla arsenal's is open. Both
// do their own adding and taking back on the unit's cargo and read it as they go, so nothing is moved under
// them (fnc_requestMigrate, fnc_opMigrate); the arsenal addon asks again once they are closed.
#define ARSENAL_OPEN (!isNull (findDisplay 1127001) || {!isNull (uiNamespace getVariable ["RscDisplayArsenal", displayNull])})

// MAX_ROWS, MAX_BLOCKS and MAX_CELLS live in main's script_macros.hpp: the items addon reads the
// rules that size containers and has to keep to the same limits.

// ---------------------------------------------------------------------------
// Use from containers (the settings einv_storage_useUniform, useVest and useBackpack)
// ---------------------------------------------------------------------------

// The kinds of item (einv_items_fnc_getInfo "kind") that are used from where they lie: magazines to reload,
// grenades to throw, medicine, food and tools (item), kits and radios. A rifle, an attachment or a piece of
// clothing is worn or fitted, not used from a container, so the settings never touch them. An array literal -
// used in code only, never inside a macro's arguments.
#define USE_ITEM_KINDS ["magazine", "grenade", "item", "kit", "radio"]

// The reload key is looked at at most this often, in seconds (fnc_reloadGuard): a key held down repeats.
#define RELOAD_GUARD_GAP 0.6

// The magazine a scroll-menu or gamepad reload took from a closed container is taken back a frame after the
// event (fnc_reloadUndo); a magazine that may be used is then loaded this many seconds later, once the
// weapon is back as it was.
#define UNDO_RELOAD_WAIT 0.4

// How often the throwing is looked at (fnc_throwTick), and the notes of where the magazines lie are taken
// again (fnc_useTrack), in seconds.
#define THROW_TICK 0.25
#define TRACK_TICK 1
