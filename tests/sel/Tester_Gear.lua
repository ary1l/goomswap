-- A made-up Selindrile gear file for tests/run.lua: one of each kind of set path sel2goom has a rule for.
function user_job_setup()
    state.OffenseMode:options('Normal','Acc','FullAcc')
    state.HybridMode:options('Normal','DT')
    state.WeaponskillMode:options('Match','Normal','Acc','Proc')
    state.CastingMode:options('Normal','Resistant','SIRD')
    state.IdleMode:options('Normal','PDT','Refresh')
    state.PhysicalDefenseMode:options('PDT','NukeLock')
    state.Weapons:options('None','Naegling','Maxentius','DualWeapons')
    gear.nuke_jse_back = {name="Sucellos's Cape",augments={'INT+20','Mag. Acc+20 /Mag. Dmg.+20','"Mag.Atk.Bns."+10'}}
    gear.obi_cure_back = "Tempered Cape +1"
    send_command('bind ^` gs c cycle ElementalMode')
    send_command('bind @f10 gs c cycle RecoverMode')
    send_command('bind !f11 gs c cycle MagicBurstMode')
    send_command('bind ^f7 gs c weapons Naegling')
    send_command('bind !q input /ma "Temper II" <me>')
    send_command('bind f9 gs c cycle OffenseMode')
    send_command('bind ~f9 gs c cycle RangedMode;gs c update')
    send_command('bind ^f10 gs c cycle PhysicalDefenseMode')
    send_command('bind ^backspace gs c scholar dark')
    select_default_macro_book()
end

function init_gear_sets()
    sets.precast.JA['Chainspell'] = {body="Viti. Tabard +3"}
    sets.precast.JA['Provoke'] = set_combine(sets.Enmity, {})
    sets.precast.JA['Nightingale'] = {feet="Bihu Slippers +3"}
    sets.precast.Waltz = {legs="Dashing Subligar"}
    sets.precast.Waltz['Healing Waltz'] = {}
    sets.precast.Step = {waist="Chaac Belt"}
    sets.precast.FC = {main="Crocea Mors",head="Atrophy Chapeau +3",body="Viti. Tabard +3",ring1="Kishar Ring",left_ear="Malignance Earring"}
    sets.precast.FC.Impact = set_combine(sets.precast.FC, {head=empty,body="Twilight Cloak"})
    sets.precast.FC.Cure = set_combine(sets.precast.FC, {feet="Vanya Clogs"})
    sets.precast.FC['Enhancing Magic'] = set_combine(sets.precast.FC, {waist="Siegel Sash"})
    sets.precast.FC.Stoneskin = set_combine(sets.precast.FC['Enhancing Magic'], {head="Umuthi Hat"})
    sets.precast.RA = {head="Taeon Chapeau"}
    sets.precast.RA.Flurry = set_combine(sets.precast.RA, {})
    sets.precast.WS = {ammo="Voluspa Tathlum",head="Nyame Helm",back=gear.nuke_jse_back,ring2=undefined_global_thing}
    sets.precast.WS.Acc = set_combine(sets.precast.WS, {neck="Combatant's Torque"})
    sets.precast.WS['Savage Blade'] = set_combine(sets.precast.WS, {neck="Rep. Plat. Medal",waist="Sailfi Belt +1"})
    sets.precast.WS['Savage Blade'].Acc = set_combine(sets.precast.WS['Savage Blade'], {ear1="Telos Earring"})
    sets.precast.WS['Savage Blade'].Proc = {head="Malignance Chapeau"}
    sets.precast.WS.Proc = {head="Malignance Chapeau"}
    sets.precast.WS.Fodder = {neck="Fotia Gorget"}
    sets.precast.WS['Savage Blade'].PDL = {ring1="Sroda Ring"}
    sets.precast.WS.Obi = {waist=gear.ElementalObi,neck="Fotia Gorget"}
    sets.precast.WS['Requiescat'] = set_combine(sets.precast.WS, {neck="Fotia Gorget"})
    sets.precast.WS['Evisceration'] = sets.precast.WS['Requiescat']
    sets.MaxTP = {ear1="Ishvara Earring"}
    sets.midcast.FastRecast = {head="Atrophy Chapeau +3"}
    sets.midcast.Cure = {main="Daybreak",sub="Sors Shield",back=gear.obi_cure_back}
    sets.midcast.Curaga = sets.midcast.Cure
    sets.midcast.Cursna = {neck="Debilis Medallion",ring1="Haoma's Ring",ring2="Menelaus's Ring"}
    sets.midcast.StatusRemoval = set_combine(sets.midcast.FastRecast, {main="Yagrush"})
    sets.midcast['Enhancing Magic'] = {main="Colada",head="Telchine Cap"}
    sets.midcast.Refresh = set_combine(sets.midcast['Enhancing Magic'], {head="Amalric Coif +1"})
    sets.midcast.Stoneskin = set_combine(sets.midcast['Enhancing Magic'], {neck="Nodens Gorget"})
    sets.midcast.Phalanx = set_combine(sets.midcast['Enhancing Magic'], {hands="Taeon Gloves"})
    sets.midcast['Enfeebling Magic'] = {main="Daybreak",range="Ullr",ammo=empty}
    sets.midcast['Enfeebling Magic'].Resistant = set_combine(sets.midcast['Enfeebling Magic'], {ear1="Regal Earring"})
    sets.midcast['Elemental Magic'] = {main="Bunzi's Rod",back=gear.nuke_jse_back}
    sets.midcast['Elemental Magic'].Resistant = set_combine(sets.midcast['Elemental Magic'], {neck="Erra Pendant"})
    sets.midcast['Elemental Magic'].OccultAcumen = {ammo="Seraphic Ampulla"}
    sets.midcast['Dark Magic'] = {neck="Erra Pendant"}
    sets.midcast.Drain = set_combine(sets.midcast['Dark Magic'], {waist="Fucho-no-Obi"})
    sets.midcast.Aspir = sets.midcast.Drain
    sets.midcast.RA = {head="Malignance Chapeau"}
    sets.midcast.RA.Acc = set_combine(sets.midcast.RA, {ring1="Cacoethic Ring +1"})
    sets.MagicBurst = {ring2="Mujin Band"}
    sets.Self_Healing = {waist="Gishdubar Sash"}
    sets.Cure_Received = {waist="Gishdubar Sash"}
    sets.Self_Refresh = {back="Grapevine Cape"}
    sets.idle = {main="Daybreak",head="Viti. Chapeau +3",ring1={name="Stikini Ring +1",bag="wardrobe"},ring2={name="Stikini Ring +1",bag="wardrobe2"}}
    sets.idle.PDT = set_combine(sets.idle, {body="Nyame Mail"})
    sets.idle.Refresh = set_combine(sets.idle, {body="Jhakri Robe +2"})
    sets.idle.Town = sets.idle
    sets.resting = {waist="Shinjutsu-no-Obi +1"}
    sets.defense.PDT = {head="Nyame Helm",body="Nyame Mail"}
    sets.defense.NukeLock = {body="Shamash Robe"}
    sets.defense.MDT = {neck="Warder's Charm +1"}
    sets.defense.MEVA = {neck="Warder's Charm +1",ring1="Purity Ring"}
    sets.Kiting = {legs="Carmine Cuisses +1"}
    sets.TreasureHunter = set_combine(sets.TreasureHunter, {ammo="Per. Lucky Egg",waist="Chaac Belt"})
    sets.weapons.Naegling = {main="Naegling",sub="Thibron"}
    sets.weapons.Maxentius = {main="Maxentius",sub="Thibron"}
    sets.weapons.DualWeapons = {main="Naegling",sub="Tauret"}
    sets.weapons.Unlisted = {main="Tauret"}
    sets.engaged = {ammo="Aurgelmir Orb +1",head="Malignance Chapeau",priority_test={name="x"}}
    sets.engaged.Acc = set_combine(sets.engaged, {neck="Combatant's Torque"})
    sets.engaged.FullAcc = set_combine(sets.engaged.Acc, {ring1="Ramuh Ring +1"})
    sets.engaged.DT = set_combine(sets.engaged, {body="Malignance Tabard"})
    sets.engaged.Acc.DT = set_combine(sets.engaged.Acc, {body="Malignance Tabard"})
    sets.buff.Doom = set_combine(sets.buff.Doom, {waist="Gishdubar Sash"})
    sets.buff.Sleep = {neck="Vim Torque +1"}
    sets.buff['Sneak Attack'] = {hands="Skulk. Armlets +1"}
    sets.HPDown = {head={name="Pixie Hairpin +1",priority=1}}
end

function select_default_macro_book() set_macro_page(1, 4) end
local _init = init_gear_sets
function init_gear_sets()
    _init()
    sets.precast.FC.BardSong = {feet="Bihu Slippers +3"}
    sets.precast.FC.Utsusemi = {neck="Magoraga Beads"}
    sets.precast.FC['Elemental Magic'] = {ear2="Barkaro. Earring"}
    sets.precast.FC.StatusRemoval = {main="Yagrush"}
    sets.precast.FC.Trust = {body="Apururu Unity Shirt"}
    sets.midcast['Blue Magic'] = {ammo="Mavi Tathlum"}
    sets.idle.Pet = {head="Beckoner's Horn +1"}
    sets.Enmity = {neck="Unmoving Collar +1"}
end
function user_setup() state.OffenseMode:options('Normal','GlobalOnly') end
function extra_user_setup() state.Weapons:options('None','Naegling','Maxentius','DualWeapons') end
