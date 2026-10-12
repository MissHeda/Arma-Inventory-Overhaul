#define COMPONENT weight
#define COMPONENT_BEAUTIFIED EINV - Weight
#include "\z\einv\addons\main\script_mod.hpp"
#include "\z\einv\addons\main\script_macros.hpp"

// How often, in seconds, the player's load is worked out again while they carry a uniform, vest or
// backpack inside their own storage (XEH_postInit). What lies in those is not part of the loadout, so
// no loadout event tells about it.
#define NESTED_CHECK_INTERVAL 3

// How deep containers lying inside containers are followed (fnc_getExtraLoad). The engine nests them
// one or two deep at most; the limit only keeps a broken object from running on.
#define MAX_DEPTH 4

// Changes smaller than this, in config mass, are not handed to ACE - each one is a broadcast, and
// adding up decimals leaves crumbs behind that nobody could feel.
#define MIN_CHANGE 0.001

// ---------------------------------------------------------------------------
// Tiers (fnc_getLimits, fnc_heavyFromAce, fnc_updateTier)
// ---------------------------------------------------------------------------

// ACE Advanced Fatigue's own jog speed in metres per second: its movement config says "Jog speed
// adjustment: 12 km/h". Heavy is where ACE's cost of jogging at this speed passes what the body keeps up.
#define JOG_SPEED (12 / 3.6)

// How much of the aerobic power counts as kept up. ACE's oxygen runs at 0.87 to 1 while working, so the
// body never quite gets all of its power - without this the yellow mark would sit a little too late.
#define AEROBIC_SHARE 0.95

// Heavy when ACE's fatigue is off and no weight was given: this share of the Overloaded mark. 60 % of 45 kg
// is 27 kg, which is also where ACE's own numbers put it at their defaults.
#define NO_ACE_HEAVY_SHARE 0.6

// Overloaded soldiers tire this many times faster at the Critical mark, and as fast as ever at the Overloaded
// one: ACE's duty factor (fnc_updateTier) climbs between the two.
#define OVERLOAD_DUTY_MAX 1.5

// How often, in seconds, the player's load, the limits and the settings are looked at again
// (XEH_postInit). Catches what no event tells about: Enhanced First Aid Kits' loads, another mod's virtual
// load, a changed setting, ACE's own settings, a looter filling a searched person's backpack.
#define TIER_CHECK_INTERVAL 1

// ACE's constants, copied under names of their own - ACE does not make them public, and the answer has
// to be steady (fnc_heavyFromAce). SIM_BODYMASS: the soldier without gear in kg; BIOMECH_EFFICIENCY: how
// much of the metabolic cost becomes work; the underwear is the weight ACE does not count as gear.
#define ACE_BODY_MASS 70
#define ACE_EFFICIENCY 0.23
#define ACE_UNDERWEAR_KG 3.5

// How the search for Heavy goes: HEAVY_STEPS halvings of the gear mass between 0 and HEAVY_GEAR_MAX kg.
// 400 kg is far more than any soldier carries; 30 halvings are finer than a gram.
#define HEAVY_STEPS 30
#define HEAVY_GEAR_MAX 400
