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

// MAX_ROWS, MAX_BLOCKS and MAX_CELLS live in main's script_macros.hpp: the items addon reads the
// rules that size containers and has to keep to the same limits.
