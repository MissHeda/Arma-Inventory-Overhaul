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
    // is listed by class (the last groups, @stack_*, and the rules after them for the medical items of
    // ACE, ACM, ACME and Enhanced First Aid Kits, with their own sizes). A rifle is a column longer than it was before presets went, a
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
        revision = 5;
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

            // What may share a tile besides the medical list below: consumables used up one at a time (cable
            // ties, ear plugs, rations, a first aid kit), by what they weigh - the small ones twenty or ten to a tile,
            // the heavy ones five or two. Keyed by class, so a class of a mod that is not loaded matches nothing and
            // costs nothing; a name with a plus is that class and every class built on it, where they are all of the
            // same sort. Chalk and what keeps a state of its own (a canteen) never stack. A rule
            // of the text with a class of these wins, as it does over any rule here.
            "@stack_20: class=ACE_CableTie|ACE_EarPlugs",
            "@stack_10: class=ACE_adenosine|ACE_painkillers_Item|ACE_bloodIV_250|ACE_IR_Strobe_Item",
            "@stack_5: class=ACE_splint|ACE_bloodIV_500|ACE_Sunflower_Seeds|ACE_MRE_LambCurry+|ACE_Can_Spirit+|FirstAidKit",
            "@stack_2: class=ACE_bloodIV",
            "@stack_20 > stack=20",
            "@stack_10 > stack=10",
            "@stack_5 > stack=5",
            "@stack_2 > stack=2",

            // The medical items of ACE, ACM, ACME and Enhanced First Aid Kits (issue #9, stacks raised for play in issue #21): the
            // stack and the size of each, last so they win over the groups above, field by field. One rule per size and stack; a
            // name with a plus is the class and every class built on it ("all types"). A stack above 1 on a class the game
            // treats as a magazine (ACM_Paracetamol, ACM_AmmoniaInhalant, ACM_Inhaler_Penthrox, ACM_Syringe_10 and its types,
            // ACM_OxygenTank_425) is all it takes to let it share a tile: only magazines with the same rounds meet. The stacks
            // are for worn containers; a crate, a vehicle or a pile on the ground multiplies them (einv_storage_stackMultiplier).
            // Every vial (ACM_Vial_*, ACME_Vial_*, ACME_MannitolVial) by a part of its class name, so a vial added
            // later is covered too: five to a tile.
            "class~ACM_Vial_|ACME_Vial_|ACME_MannitolVial > size=1x1 stack=5",
            // One to a tile, 1x1: single-use devices, bags and tools. A name with a plus is that class and every class built on
            // it (all types of a blood bag, plasma, saline and PlasmaLyte bag). Bulky things stay at one.
            "class=ACM_AmmoniaInhalant|ACM_BloodBag+|ACM_EMMA|ACME_ETTube|ACM_EsmololBag|ACM_FieldBloodTransfusionKit_250|ACM_FieldBloodTransfusionKit_500|ACME_HTSBag|ACME_Laryngoscope|ACME_BloodWarmer|ACME_MagnesiumBag|ACME_MannitolBag|ACM_HPMK|ACM_NRBMask|ACM_Inhaler_Penthrox|ACE_plasmaIV+|ACME_PlasmaLyteBag+|ACM_PocketBVM|ACM_PressureCuff|ACE_salineIV+|ACM_Stethoscope|ACM_Thermometer|ACE_suture|ACM_ThoracostomyKit|ACME_VentBattery > size=1x1 stack=1",
            // Four to a tile, 1x1: injectors, sprays, splints, tourniquets and kits used up one at a time; body bags, all types.
            "class=ACM_Paracetamol|ACM_Autoinjector_ATNA|ACE_bodyBag+|ACM_ChestTubeKit|ACM_CricKit|ACE_epinephrine|ACME_Spray_Esketamine|ACME_HTSBullet|ACM_Autoinjector_Midazolam|ACE_morphine|ACM_Spray_Naloxone|ACME_NARSPEAR|ACM_NCDKit|ACME_PressureInfuser|ACM_PulseOximeter|ACM_SAMSplint|ACE_tourniquet|ACME_XStat > size=1x1 stack=4",
            // Five to a tile, 1x1: dressings and wraps, IV cannulas and IO devices, seals, airways, flushes and prepared syringes (all types).
            "class=ACE_fieldDressing|ACE_elasticBandage|ACE_packingBandage|ACE_quikclot|ACM_PressureBandage|ACM_ElasticWrap|ACM_CombatGauze|ACM_EmergencyTraumaDressing|ACM_IV_14g+|ACM_IV_16g+|ACM_IV_18g+|ACM_IV_20g+|ACM_IO_EZ|ACM_IO_FAST|ACM_ChestSeal|ACM_SuctionBag|ACM_IGel|ACME_NARBOA|ACM_NPA|ACM_OPA|ACM_SalineFlush_10|ACM_Syringe_10+ > size=1x1 stack=5",
            // Ten to a tile, 1x1: lozenges, IV lines and Y tubing.
            "class=ACM_Lozenge_Fentanyl|ACME_IVLine|ACME_YTubing > size=1x1 stack=10",
            // One to a tile, 2x1; the individual first aid kit (Enhanced First Aid Kits) with every instance class built on it.
            "class=ACM_BVM|ACME_AAJT_S|efak_IFAK+ > size=2x1 stack=1",
            // One to a tile, 1x2: the oxygen tank.
            "class=ACM_OxygenTank_425 > size=1x2 stack=1",
            // One to a tile, 2x2; the kit of Enhanced First Aid Kits with its instances (efak_AFAK_1 and on) via the plus.
            "class=ACM_AED|ACME_BloodCooler_CSWB1U|ACE_surgicalKit|ACME_Ventilator|efak_AFAK+ > size=2x2 stack=1",
            // One to a tile, 3x2; before 3x3, so that a kit built on one of these two takes the larger size.
            "class=ACM_ACCUVAC|ACME_BloodCooler_CSWB2U|efak_MFAK+ > size=3x2 stack=1",
            // One to a tile, 3x3.
            "class=ACME_BloodCooler_CSWB4U|efak_MFAKPlus+ > size=3x3 stack=1"
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
