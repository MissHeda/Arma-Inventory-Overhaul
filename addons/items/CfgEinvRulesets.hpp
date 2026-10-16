// The preset a rules text builds on: "base=default" in its first statement (einv_items_rules,
// einv_items_fnc_compileRules). A preset is a list of statements in the same language as the text,
// one statement per element and no commas in it. Its own base is read first and the preset's rules
// come after it, so they win - up to MAX_CHAIN presets deep.
//
//   name, description - for whoever lists the presets
//   revision          - shown only; base= always means the preset as installed
//   base              - the preset it builds on, "" for none
//   cell              - config mass per grid cell, -1 to leave it to its base or to the slider
//                       einv_items_massPerCell. cell= in a text's own header beats it.
//   rules[]           - its statements
//   class Groups      - a label, a family (its filter chip), an example class for the row's picture
//                       and overlay = 1 for a group that overlaps the others on purpose (its rules
//                       go after theirs)
//
// The group ids are what own rules refer to (@rifle_light > size=3x2): never rename one. Nor a
// preset's id: a text names it in base=. The setup wizard offers no choice of presets any more - there
// is this one - and the ids that were once shipped (realism, weight, and tarkov before them) are read
// as this one (PRESET_ALIASES, fnc_parseRules), so a saved setup that names one still loads. Other mods may
// add presets of their own as classes here, for a text that names them in base=. Only the case of a class
// name is free: the config finds a class whatever its case, and the ids are read lowercased.
class CfgEinvRulesets {
    // The default, the one preset: the sizes a rig and a rifle really take, and nothing stacks but what
    // the owner picked by hand (the last groups, @stack_*). A rifle is a column longer than it was before presets went, a
    // backpack's tile as large as its room. No rule here sets a container's grid: a uniform, vest or
    // backpack with no rule, mod or setting of its own gets what the built-in answer makes of its load
    // (einv_storage_fnc_blocksFor), so the kind settings of the setup wizard's General page - the text's
    // rules with "all" - decide for every container no class rule or mod answers. The groups are a
    // partition: an item is in at most one of them (but medical and the stack groups, which are only
    // handles), so that a rule for one of them never reaches into another. The magazine groups leave
    // each other out for that reason. Kits of Enhanced First Aid Kits are items to kind= as well, so the
    // item groups size them; none of these gives a kit a grid: without a rule or a config key of
    // theirs, that mod's capacity is their room.
    class Default {
        name = CSTRING(Ruleset_Default);
        description = CSTRING(Ruleset_Default_Desc);
        revision = 3;
        base = "";
        cell = -1;
        rules[] = {
            "size=1x1 stack=1",

            "@rifle_light: kind=rifle mass<=55",
            "@rifle_medium: kind=rifle mass>55 mass<=90",
            "@rifle_heavy: kind=rifle mass>90 mass<=150",
            "@rifle_xheavy: kind=rifle mass>150",
            "@handgun: kind=handgun",
            "@launcher: kind=launcher",
            "@rifle_light > size=4x2",
            "@rifle_medium > size=5x2",
            "@rifle_heavy > size=6x2",
            "@rifle_xheavy > size=7x2",
            "@handgun > size=2x1",
            "@launcher > size=6x2",

            "@belt: kind=magazine rounds>=50 mass>15",
            "@rocket: kind=magazine rounds=1 mass>15 mass<=60",
            "@rocket_heavy: kind=magazine rounds=1 mass>60",
            "@mag_small: kind=magazine mass<=5",
            "@mag_rifle: kind=magazine mass>5 mass<=20 !@belt !@rocket",
            "@mag_large: kind=magazine mass>20 !@belt !@rocket !@rocket_heavy",
            "@grenade: kind=grenade",
            "@belt > size=2x2",
            "@rocket > size=1x3",
            "@rocket_heavy > size=2x3",
            "@mag_small > size=1x1",
            "@mag_rifle > size=1x2",
            "@mag_large > size=2x2",
            "@grenade > size=1x1",

            "@optic_small: kind=optic mass<=8",
            "@optic_large: kind=optic mass>8",
            "@muzzle: kind=muzzle",
            "@rail_bipod: kind=rail|bipod",
            "@optic_small > size=1x1",
            "@optic_large > size=2x1",
            "@muzzle > size=2x1",
            "@rail_bipod > size=1x1",

            "@item_small: kind=item mass<=10",
            "@item_medium: kind=item mass>10 mass<=30",
            "@item_large: kind=item mass>30 mass<=60",
            "@item_xlarge: kind=item mass>60",
            "@item_small > size=1x1",
            "@item_medium > size=2x1",
            "@item_large > size=2x2",
            "@item_xlarge > size=3x2",
            "@medical: cat=medical",

            "@assigned: kind=map|gps|radio|compass|watch",
            "@goggles: kind=goggles",
            "@nvg_binocular: kind=nvg|binocular",
            "@headgear: kind=headgear",
            "@assigned > size=1x1",
            "@goggles > size=1x1",
            "@nvg_binocular > size=2x1",
            "@headgear > size=2x2",

            "@uniform: kind=uniform",
            "@vest: kind=vest",
            "@backpack_small: kind=backpack load<=160",
            "@backpack_medium: kind=backpack load>160 load<=280",
            "@backpack_large: kind=backpack load>280",
            "@crate: kind=crate|vehicle",
            "@uniform > size=2x2",
            "@vest > size=3x3",
            "@backpack_small > size=4x4",
            "@backpack_medium > size=5x5",
            "@backpack_large > size=5x6",

            // What may share a tile: consumables that are used up one at a time (bandages, injectors,
            // infusions, rations, a first aid kit), by what they weigh - the small ones twenty or ten
            // to a tile, the heavy ones five or two. Keyed by class, so a class of a mod that is not
            // loaded matches nothing and costs nothing; a name with a plus is that class and every
            // class built on it, where they are all of the same sort. Chalk, anything that is a magazine
            // to the game, and what keeps a state of its own (a canteen, a fresh blood bag) never stack.
            // A rule of the text with a class of these wins, as it does over any rule here.
            "@stack_20: class=ACE_suture|ACE_CableTie|ACE_EarPlugs",
            "@stack_10: class=ACE_fieldDressing|ACE_packingBandage|ACE_elasticBandage|ACE_quikclot|ACE_tourniquet|ACE_morphine|ACE_epinephrine|ACE_adenosine|ACE_painkillers_Item|ACE_plasmaIV_250|ACE_salineIV_250|ACE_bloodIV_250|ACE_IR_Strobe_Item|ACM_PressureBandage|ACM_ElasticWrap|ACM_SAMSplint|ACM_IV_16g+|ACM_Syringe_10+|ACM_Vial_Epinephrine+|ACM_BloodBag_O_250+",
            "@stack_5: class=ACE_splint|ACE_plasmaIV_500|ACE_salineIV_500|ACE_bloodIV_500|ACE_Sunflower_Seeds|ACE_MRE_LambCurry+|ACE_Can_Spirit+|ACM_EmergencyTraumaDressing|ACM_ChestSeal|ACM_BloodBag_O_500+|FirstAidKit",
            "@stack_2: class=ACE_plasmaIV|ACE_salineIV|ACE_bloodIV|ACM_BloodBag_O_1000+",
            "@stack_20 > stack=20",
            "@stack_10 > stack=10",
            "@stack_5 > stack=5",
            "@stack_2 > stack=2"
        };

        // Examples only where the class surely lands in that group; the others stay "" until they
        // have been checked in the game.
        class Groups {
            class rifle_light { name = CSTRING(Group_rifle_light); family = "weapons"; example = ""; };
            class rifle_medium { name = CSTRING(Group_rifle_medium); family = "weapons"; example = ""; };
            class rifle_heavy { name = CSTRING(Group_rifle_heavy); family = "weapons"; example = ""; };
            class rifle_xheavy { name = CSTRING(Group_rifle_xheavy); family = "weapons"; example = ""; };
            class handgun { name = CSTRING(Group_handgun); family = "weapons"; example = "hgun_P07_F"; };
            class launcher { name = CSTRING(Group_launcher); family = "weapons"; example = "launch_NLAW_F"; };
            class belt { name = CSTRING(Group_belt); family = "ammo"; example = "100Rnd_65x39_caseless_mag"; };
            class rocket { name = CSTRING(Group_rocket); family = "ammo"; example = ""; };
            class rocket_heavy { name = CSTRING(Group_rocket_heavy); family = "ammo"; example = ""; };
            class mag_small { name = CSTRING(Group_mag_small); family = "ammo"; example = ""; };
            class mag_rifle { name = CSTRING(Group_mag_rifle); family = "ammo"; example = "30Rnd_65x39_caseless_mag"; };
            class mag_large { name = CSTRING(Group_mag_large); family = "ammo"; example = ""; };
            class grenade { name = CSTRING(Group_grenade); family = "ammo"; example = "HandGrenade"; };
            class optic_small { name = CSTRING(Group_optic_small); family = "attachments"; example = ""; };
            class optic_large { name = CSTRING(Group_optic_large); family = "attachments"; example = ""; };
            class muzzle { name = CSTRING(Group_muzzle); family = "attachments"; example = "muzzle_snds_H"; };
            class rail_bipod { name = CSTRING(Group_rail_bipod); family = "attachments"; example = "acc_flashlight"; };
            class item_small { name = CSTRING(Group_item_small); family = "items"; example = ""; };
            class item_medium { name = CSTRING(Group_item_medium); family = "items"; example = ""; };
            class item_large { name = CSTRING(Group_item_large); family = "items"; example = ""; };
            class item_xlarge { name = CSTRING(Group_item_xlarge); family = "items"; example = ""; };
            class medical { name = CSTRING(Group_medical); family = "items"; example = "FirstAidKit"; overlay = 1; };
            class assigned { name = CSTRING(Group_assigned); family = "worn"; example = "ItemMap"; };
            class goggles { name = CSTRING(Group_goggles); family = "worn"; example = "G_Shades_Black"; };
            class nvg_binocular { name = CSTRING(Group_nvg_binocular); family = "worn"; example = "NVGoggles"; };
            class headgear { name = CSTRING(Group_headgear); family = "worn"; example = "H_HelmetB"; };
            class uniform { name = CSTRING(Group_uniform); family = "containers"; example = "U_B_CombatUniform_mcam"; };
            class vest { name = CSTRING(Group_vest); family = "containers"; example = "V_PlateCarrier1_rgr"; };
            class backpack_small { name = CSTRING(Group_backpack_small); family = "containers"; example = "B_AssaultPack_rgr"; };
            class backpack_medium { name = CSTRING(Group_backpack_medium); family = "containers"; example = "B_Kitbag_rgr"; };
            class backpack_large { name = CSTRING(Group_backpack_large); family = "containers"; example = "B_Carryall_cbr"; };
            class crate { name = CSTRING(Group_crate); family = "containers"; example = "Box_NATO_Ammo_F"; };
            class stack_20 { name = CSTRING(Group_stack_20); family = "items"; example = "ACE_CableTie"; overlay = 1; };
            class stack_10 { name = CSTRING(Group_stack_10); family = "items"; example = "ACE_fieldDressing"; overlay = 1; };
            class stack_5 { name = CSTRING(Group_stack_5); family = "items"; example = "FirstAidKit"; overlay = 1; };
            class stack_2 { name = CSTRING(Group_stack_2); family = "items"; example = "ACE_plasmaIV"; overlay = 1; };
        };
    };
};
