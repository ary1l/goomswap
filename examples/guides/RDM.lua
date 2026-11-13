-- Guide lists for /gcbuild RDM guide. Per set of examples/RDM.lua, per slot: items best first, written down from a
-- gear guide (the source is named on each set). /gcbuild puts the first one the character owns in that slot, also
-- where the example's set has no line for the slot. It ranks nothing itself, so the order here is the whole answer:
-- add an item where it belongs in a list, and only what a guide actually says.
-- A set or slot without a list is left to the example.
return {
    -- BG-Wiki Community Red Mage Guide, "EnSpell: Crocea" set. The guide gives this one set, no alternatives, so each
    -- list has one item; the weapon (Crocea Mors) is the /wm enspell mode's, not part of this set.
    Tp_Enspell = {
        Ammo = { 'Sroda Tathlum' },
        Head = { 'Sworn Crown' },
        Body = { 'Sworn Platemail' },
        Hands = { 'Aya. Manopolas +2' },
        Waist = { 'Orpheus\'s Sash' },
        Legs = { 'Sworn Brais' },
        Feet = { 'Sworn Sabatons' },
    },
};
