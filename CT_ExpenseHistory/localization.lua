------------------------------------------------
--              CT_ExpenseHistory             --
--                                            --
-- Keeps a detailed log of expenses for each  --
-- of your characters.                        --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--					      --
-- Original credits to Cide and TS            --
-- Maintained by Resike from 2014 to 2017     --
-- Maintained by Dahk Celes (ddc) since 2019  --
------------------------------------------------

-- Please contribute new translations at <https://wow.curseforge.com/projects/ctmod/localization>

local MODULE_NAME, module = ...;
module.text = module.text or { };
local L = module.text

-- enUS (other languages follow underneath)

L["CT_ExpenseHistory/Ammo"] = "Ammo"
L["CT_ExpenseHistory/Flight"] = "Flight"
L["CT_ExpenseHistory/Log/Char"] = "Character"
L["CT_ExpenseHistory/Log/Cost"] = "Cost"
L["CT_ExpenseHistory/Log/Date"] = "Date"
L["CT_ExpenseHistory/Log/Heading"] = "Log"
L["CT_ExpenseHistory/Log/RecordingSince"] = "Recorded data from |c00FFFFFF%s|r."
L["CT_ExpenseHistory/Log/Type"] = "Type"
L["CT_ExpenseHistory/Log/Viewing"] = "Viewing |c00FFFFFF%s|r"
L["CT_ExpenseHistory/Mail"] = "Mail"
L["CT_ExpenseHistory/Reagent"] = "Reagent"
L["CT_ExpenseHistory/Repair"] = "Repair"
L["CT_ExpenseHistory/Summary/AmmoCost"] = "Ammo:"
L["CT_ExpenseHistory/Summary/AverageExpenses"] = "Average Expenses/Day:"
L["CT_ExpenseHistory/Summary/AverageRepair"] = "Average Repair:"
L["CT_ExpenseHistory/Summary/FlightCost"] = "Flights:"
L["CT_ExpenseHistory/Summary/Heading"] = "Summary"
L["CT_ExpenseHistory/Summary/MailCost"] = "Mail Postage:"
L["CT_ExpenseHistory/Summary/PlayerDistribution"] = "Player Distribution:"
L["CT_ExpenseHistory/Summary/PlayerDistribution/AllCharacters"] = "All Characters"
L["CT_ExpenseHistory/Summary/PlayerDistribution/AllServers"] = "All Servers"
L["CT_ExpenseHistory/Summary/ReagentCost"] = "Reagents:"
L["CT_ExpenseHistory/Summary/RepairCost"] = "Repairs:"
L["CT_ExpenseHistory/Summary/TotalCost"] = "Total Amount Spent:"
L["CT_ExpenseHistory/Ammo/Accurate Slugs"] = "Accurate Slugs"
L["CT_ExpenseHistory/Ammo/Balanced Throwing Dagger"] = "Balanced Throwing Dagger"
L["CT_ExpenseHistory/Ammo/Blackflight Arrow"] = "Blackflight Arrow"
L["CT_ExpenseHistory/Ammo/Blacksteel Throwing Dagger"] = "Blacksteel Throwing Dagger"
L["CT_ExpenseHistory/Ammo/Crude Throwing Axe"] = "Crude Throwing Axe"
L["CT_ExpenseHistory/Ammo/Deadly Throwing Axe"] = "Deadly Throwing Axe"
L["CT_ExpenseHistory/Ammo/Felbane Slugs"] = "Felbane Slugs"
L["CT_ExpenseHistory/Ammo/Frostbite Bullets"] = "Frostbite Bullets"
L["CT_ExpenseHistory/Ammo/Gleaming Throwing Axe"] = "Gleaming Throwing Axe"
L["CT_ExpenseHistory/Ammo/Halaani Grimshot"] = "Halaani Grimshot"
L["CT_ExpenseHistory/Ammo/Halaani Razorshaft"] = "Halaani Razorshaft"
L["CT_ExpenseHistory/Ammo/Heavy Shot"] = "Heavy Shot"
L["CT_ExpenseHistory/Ammo/Heavy Throwing Dagger"] = "Heavy Throwing Dagger"
L["CT_ExpenseHistory/Ammo/Hellfire Shot"] = "Hellfire Shot"
L["CT_ExpenseHistory/Ammo/Ice Threaded Arrow"] = "Ice threaded Arrow"
L["CT_ExpenseHistory/Ammo/Ice Threaded Bullet"] = "Ice threaded Bullet"
L["CT_ExpenseHistory/Ammo/Impact Shot"] = "Impact Shot"
L["CT_ExpenseHistory/Ammo/Ironbite Shell"] = "Ironbite Shell"
L["CT_ExpenseHistory/Ammo/Jagged Arrow"] = "Jagged Arrow"
L["CT_ExpenseHistory/Ammo/Jagged Throwing Axe"] = "Jagged throwing Axe"
L["CT_ExpenseHistory/Ammo/Keen Throwing Knife"] = "Keen throwing Knife"
L["CT_ExpenseHistory/Ammo/Light Shot"] = "Light Shot"
L["CT_ExpenseHistory/Ammo/Mysterious Arrow"] = "Mysterious Arrow"
L["CT_ExpenseHistory/Ammo/Mysterious Shell"] = "Mysterious Shell"
L["CT_ExpenseHistory/Ammo/Razor Arrow"] = "Razor Arrow"
L["CT_ExpenseHistory/Ammo/Rough Arrow"] = "Rough Arrow"
L["CT_ExpenseHistory/Ammo/Scout's Arrow"] = "Scout's Arrow"
L["CT_ExpenseHistory/Ammo/Sharp Arrow"] = "Sharp Arrow"
L["CT_ExpenseHistory/Ammo/Sharp Throwing Axe"] = "Sharp Throwing Axe"
L["CT_ExpenseHistory/Ammo/Small Throwing Knife"] = "Small Throwing Knife"
L["CT_ExpenseHistory/Ammo/Smooth Pebble"] = "Smooth Pebble"
L["CT_ExpenseHistory/Ammo/Solid Shot"] = "Solid Shot"
L["CT_ExpenseHistory/Ammo/Terrorshaft Arrow"] = "Terrorshaft Arrow"
L["CT_ExpenseHistory/Ammo/Timeless Arrow"] = "Timeless Arrow"
L["CT_ExpenseHistory/Ammo/Timeless Shell"] = "Timeless Shell"
L["CT_ExpenseHistory/Ammo/Warden's Arrow"] = "Warden's Arrow"
L["CT_ExpenseHistory/Ammo/Weighted Throwing Axe"] = "Weighted Throwing Axe"
L["CT_ExpenseHistory/Ammo/Wicked Arrow"] = "Wicked Arrow"
L["CT_ExpenseHistory/Ammo/Wicked Throwing Dagger"] = "Wicked Throwing Dagger"
L["CT_ExpenseHistory/Reagent/Ankh"] = "Ankh"
L["CT_ExpenseHistory/Reagent/Arcane Powder"] = "Arcane Powder"
L["CT_ExpenseHistory/Reagent/Ashwood Seed"] = "Ashwood Seed"
L["CT_ExpenseHistory/Reagent/Corpse Dust"] = "Corpse Dust"
L["CT_ExpenseHistory/Reagent/Demonic Figurine"] = "Demonic Figurine"
L["CT_ExpenseHistory/Reagent/Devout Candle"] = "Devout Candle"
L["CT_ExpenseHistory/Reagent/Flash Powder"] = "Flash Powder"
L["CT_ExpenseHistory/Reagent/Flintweed Seed"] = "Flintweed Seed"
L["CT_ExpenseHistory/Reagent/Holy Candle"] = "Holy Candle"
L["CT_ExpenseHistory/Reagent/Hornbeam Seed"] = "Hornbeam Seed"
L["CT_ExpenseHistory/Reagent/Infernal Stone"] = "Infernal Stone"
L["CT_ExpenseHistory/Reagent/Ironwood Seed"] = "Ironwood Seed"
L["CT_ExpenseHistory/Reagent/Maple Seed"] = "Maple Seed"
L["CT_ExpenseHistory/Reagent/Rune of Portals"] = "Rune of Portals"
L["CT_ExpenseHistory/Reagent/Rune of Teleportation"] = "Rune of Teleportation"
L["CT_ExpenseHistory/Reagent/Sacred Candle"] = "Sacred Candle"
L["CT_ExpenseHistory/Reagent/Starleaf Seed"] = "Starleaf Seed"
L["CT_ExpenseHistory/Reagent/Stranglethorn Seed"] = "Stranglethorn Seed"
L["CT_ExpenseHistory/Reagent/Symbol of Divinity"] = "Symbol of Divinity"
L["CT_ExpenseHistory/Reagent/Symbol of Kings"] = "Symbol of Kings"
L["CT_ExpenseHistory/Reagent/Wild Berries"] = "Wild Berries"
L["CT_ExpenseHistory/Reagent/Wild Quillvine"] = "Wild Quillvine"
L["CT_ExpenseHistory/Reagent/Wild Spineleaf"] = "Wild Spineleaf"
L["CT_ExpenseHistory/Reagent/Wild Thornroot"] = "Wild Thornroot"

-- Classes
CT_EH_WARRIOR = "Warrior";
CT_EH_MAGE = "Mage";
CT_EH_DRUID = "Druid";
CT_EH_ROGUE = "Rogue";
CT_EH_PRIEST = "Priest";
CT_EH_WARLOCK = "Warlock";
CT_EH_HUNTER = "Hunter";
CT_EH_SHAMAN = "Shaman";
CT_EH_PALADIN = "Paladin";
CT_EH_DEATHKNIGHT = "Death Knight";
CT_EH_MONK = "Monk";

CT_EH_MODINFO = {
	"Expense History",
	"Show Dialog",
	"Displays the Expense History dialog, where you can view a listing and summary of your expenses."
};


-- frFR (Credits: anon)

if ( GetLocale() == "frFR" ) then

L["CT_ExpenseHistory/Ammo"] = "Munitions"
L["CT_ExpenseHistory/Flight"] = "Vol"
L["CT_ExpenseHistory/Log/Char"] = "Personnage"
L["CT_ExpenseHistory/Log/Cost"] = "Cost"
L["CT_ExpenseHistory/Log/Date"] = "Date"
L["CT_ExpenseHistory/Log/Heading"] = "Journal"
L["CT_ExpenseHistory/Log/RecordingSince"] = "Données Enregistrées Depuis |c00FFFFFF%s|r."
L["CT_ExpenseHistory/Log/Type"] = "Type"
L["CT_ExpenseHistory/Log/Viewing"] = "Regarder |c00FFFFFF%s|r"
L["CT_ExpenseHistory/Mail"] = "Courrier"
L["CT_ExpenseHistory/Reagent"] = "Composant"
L["CT_ExpenseHistory/Repair"] = "Répare"
L["CT_ExpenseHistory/Summary/AmmoCost"] = "Munitions:"
L["CT_ExpenseHistory/Summary/AverageExpenses"] = "Dépense Moyenne/Jour:"
L["CT_ExpenseHistory/Summary/AverageRepair"] = "Réparation Moyenne:"
L["CT_ExpenseHistory/Summary/FlightCost"] = "Vols:"
L["CT_ExpenseHistory/Summary/Heading"] = "Sommaire"
L["CT_ExpenseHistory/Summary/MailCost"] = "Envoie de Courrier:"
L["CT_ExpenseHistory/Summary/PlayerDistribution"] = "Distribution par Joueur:"
L["CT_ExpenseHistory/Summary/PlayerDistribution/AllCharacters"] = "Tous les Personnages:"
L["CT_ExpenseHistory/Summary/PlayerDistribution/AllServers"] = "All Servers"
L["CT_ExpenseHistory/Summary/ReagentCost"] = "Composants:"
L["CT_ExpenseHistory/Summary/RepairCost"] = "Réparations:"
L["CT_ExpenseHistory/Summary/TotalCost"] = "Montant Dépensé Total:"
L["CT_ExpenseHistory/Ammo/Accurate Slugs"] = "Balles de précision"
L["CT_ExpenseHistory/Ammo/Balanced Throwing Dagger"] = "Dague de lancer équilibrée"
L["CT_ExpenseHistory/Ammo/Blackflight Arrow"] = "Flèche de vol noir"
L["CT_ExpenseHistory/Ammo/Blacksteel Throwing Dagger"] = "Dague de lancer en noiracier"
L["CT_ExpenseHistory/Ammo/Crude Throwing Axe"] = "Hache de lncer grossière"
L["CT_ExpenseHistory/Ammo/Deadly Throwing Axe"] = "Hache de lancer mortelle"
L["CT_ExpenseHistory/Ammo/Frostbite Bullets"] = "Balles morsure-de-givre"
L["CT_ExpenseHistory/Ammo/Heavy Shot"] = "Balle lourde"
L["CT_ExpenseHistory/Ammo/Heavy Throwing Dagger"] = "Couteau de lancer lourd"
L["CT_ExpenseHistory/Ammo/Ice Threaded Arrow"] = "Flèche de glace"
L["CT_ExpenseHistory/Ammo/Ice Threaded Bullet"] = "Balle de glace"
L["CT_ExpenseHistory/Ammo/Jagged Arrow"] = "Flèche barbelée"
L["CT_ExpenseHistory/Ammo/Keen Throwing Knife"] = "Couteau de lancer perçant"
L["CT_ExpenseHistory/Ammo/Light Shot"] = "Balle légère"
L["CT_ExpenseHistory/Ammo/Mysterious Arrow"] = "Flèche mystérieuse"
L["CT_ExpenseHistory/Ammo/Razor Arrow"] = "Flèche rasoir"
L["CT_ExpenseHistory/Ammo/Rough Arrow"] = "Flèche grossière"
L["CT_ExpenseHistory/Ammo/Scout's Arrow"] = "Flèche d'éclaireur"
L["CT_ExpenseHistory/Ammo/Sharp Arrow"] = "Flèche pointue"
L["CT_ExpenseHistory/Ammo/Sharp Throwing Axe"] = "Hache de lancer aiguisée"
L["CT_ExpenseHistory/Ammo/Terrorshaft Arrow"] = "Flèche trait de terreur"
L["CT_ExpenseHistory/Ammo/Timeless Arrow"] = "Flèche intemporelle"
L["CT_ExpenseHistory/Ammo/Warden's Arrow"] = "Flèche de sylvegarde"
L["CT_ExpenseHistory/Ammo/Wicked Arrow"] = "Flèche cruelle"
L["CT_ExpenseHistory/Reagent/Ankh"] = "Ankh"
L["CT_ExpenseHistory/Reagent/Arcane Powder"] = "Poudre des arcane"
L["CT_ExpenseHistory/Reagent/Ashwood Seed"] = "Graine de frêne"
L["CT_ExpenseHistory/Reagent/Corpse Dust"] = "Poussière de cadavre"
L["CT_ExpenseHistory/Reagent/Flash Powder"] = "Poudre éclipsante"
L["CT_ExpenseHistory/Reagent/Holy Candle"] = "Bougie sanctifiée"
L["CT_ExpenseHistory/Reagent/Hornbeam Seed"] = "Graine de charme"
L["CT_ExpenseHistory/Reagent/Infernal Stone"] = "Pierre infernale"
L["CT_ExpenseHistory/Reagent/Ironwood Seed"] = "Graine de bois de fer"
L["CT_ExpenseHistory/Reagent/Maple Seed"] = "Graine d'erable"
L["CT_ExpenseHistory/Reagent/Rune of Portals"] = "Rune de téléportation"
L["CT_ExpenseHistory/Reagent/Rune of Teleportation"] = "Rune de portails"
L["CT_ExpenseHistory/Reagent/Sacred Candle"] = "Bougie sacrée"
L["CT_ExpenseHistory/Reagent/Stranglethorn Seed"] = "Graine de stranglethorn"
L["CT_ExpenseHistory/Reagent/Symbol of Divinity"] = "Symbole de divinité"
L["CT_ExpenseHistory/Reagent/Wild Berries"] = "Baies sauvages"

	-- Classes
	CT_EH_WARRIOR = "Guerrier";
	CT_EH_MAGE = "Mage";
	CT_EH_DRUID = "Druide";
	CT_EH_ROGUE = "Voleur";
	CT_EH_PRIEST = "Pr\195\170tre";
	CT_EH_WARLOCK = "D\195\169moniste";
	CT_EH_HUNTER = "Chasseur";
	CT_EH_SHAMAN = "Chaman";
	CT_EH_PALADIN = "Paladin";
	CT_EH_DEATHKNIGHT = "Death Knight";
	CT_EH_MONK = "Monk";	

	CT_EH_MODINFO = {
		"Expense History",
		"Afficher Fen\195\170tre",
		"Affiche la fen\195\170tre \195\160 partir de laquelle vous pouvez voir une liste et un r\195\169sum\195\169 de vos d\195\169penses."
	};


-- deDE (Credits: anon)

elseif ( GetLocale() == "deDE" ) then

L["CT_ExpenseHistory/Ammo"] = "Munition"
L["CT_ExpenseHistory/Flight"] = "Flug"
L["CT_ExpenseHistory/Log/Char"] = "Charakter"
L["CT_ExpenseHistory/Log/Cost"] = "Kosten"
L["CT_ExpenseHistory/Log/Date"] = "Datum"
L["CT_ExpenseHistory/Log/Heading"] = "Log"
L["CT_ExpenseHistory/Log/RecordingSince"] = "Datenaufzeichnung von |c00FFFFFF%s|r."
L["CT_ExpenseHistory/Log/Type"] = "Typ"
L["CT_ExpenseHistory/Log/Viewing"] = "Besichtigung |c00FFFFFF%s|r"
L["CT_ExpenseHistory/Mail"] = "Post"
L["CT_ExpenseHistory/Reagent"] = "Zutat"
L["CT_ExpenseHistory/Repair"] = "Reparatur"
L["CT_ExpenseHistory/Summary/AmmoCost"] = "Munition:"
L["CT_ExpenseHistory/Summary/AverageExpenses"] = "Durchschnittliche Ausgaben/Tag:"
L["CT_ExpenseHistory/Summary/AverageRepair"] = "Durchschnittliche Reparaturkosten:"
L["CT_ExpenseHistory/Summary/FlightCost"] = "FlÃ¼ge:"
L["CT_ExpenseHistory/Summary/Heading"] = "Zusammenfassung"
L["CT_ExpenseHistory/Summary/MailCost"] = "Portokosten:"
L["CT_ExpenseHistory/Summary/PlayerDistribution"] = "Spielerverteilung:"
L["CT_ExpenseHistory/Summary/PlayerDistribution/AllCharacters"] = "Alle Charaktere"
L["CT_ExpenseHistory/Summary/PlayerDistribution/AllServers"] = "All Servers"
L["CT_ExpenseHistory/Summary/ReagentCost"] = "Zutaten:"
L["CT_ExpenseHistory/Summary/RepairCost"] = "Reparaturen:"
L["CT_ExpenseHistory/Summary/TotalCost"] = "Gesamtausgaben:"
L["CT_ExpenseHistory/Ammo/Accurate Slugs"] = "Genaue Patronen"
L["CT_ExpenseHistory/Ammo/Balanced Throwing Dagger"] = "Ausbalancierter Wurfdolch"
L["CT_ExpenseHistory/Reagent/Ankh"] = "Ankh"


	-- Classes
	CT_EH_WARRIOR = "Krieger";
	CT_EH_MAGE = "Magier";
	CT_EH_DRUID = "Druide";
	CT_EH_ROGUE = "Schurke";
	CT_EH_PRIEST = "Priester";
	CT_EH_WARLOCK = "Hexenmeister";
	CT_EH_HUNTER = "J\195\164ger";
	CT_EH_SHAMAN = "Schamane";
	CT_EH_PALADIN = "Paladin";
	CT_EH_DEATHKNIGHT = "Death Knight";
	CT_EH_MONK = "Monk";

	CT_EH_MODINFO = {
		"Expense History",
		"Zeige Dialogfenster",
		"Zeigt ein dialogfenster, in dem du eine auflistung und zusammenfassung deiner ausgaben sehen kannst."
	};


-- reRU (Credits: imposeren)

elseif ( GetLocale() == "ruRU" ) then

L["CT_ExpenseHistory/Ammo"] = "Патроны"
L["CT_ExpenseHistory/Reagent"] = "Реагент"
L["CT_ExpenseHistory/Ammo/Accurate Slugs"] = "Точные пули"
L["CT_ExpenseHistory/Ammo/Crude Throwing Axe"] = "Грубый метательный топорик"
L["CT_ExpenseHistory/Ammo/Deadly Throwing Axe"] = "Смертоносный метательный топорик"
L["CT_ExpenseHistory/Ammo/Gleaming Throwing Axe"] = "Блестящий метательный топорик"
L["CT_ExpenseHistory/Ammo/Heavy Shot"] = "Тяжелый патрон"
L["CT_ExpenseHistory/Ammo/Heavy Throwing Dagger"] = "Тяжелый метательный кинжал"
L["CT_ExpenseHistory/Ammo/Ice Threaded Arrow"] = "Пронизанная льдом стрела"
L["CT_ExpenseHistory/Ammo/Ice Threaded Bullet"] = "Пронизанная льдом пуля"
L["CT_ExpenseHistory/Ammo/Jagged Arrow"] = "Зазубренная стрела"
L["CT_ExpenseHistory/Ammo/Keen Throwing Knife"] = "Остро отточенный метательный нож"
L["CT_ExpenseHistory/Ammo/Light Shot"] = "Легкий патрон"
L["CT_ExpenseHistory/Ammo/Razor Arrow"] = "Стрела-бритва"
L["CT_ExpenseHistory/Ammo/Rough Arrow"] = "Грубая стрела"
L["CT_ExpenseHistory/Ammo/Sharp Arrow"] = "Острая стрела"
L["CT_ExpenseHistory/Ammo/Sharp Throwing Axe"] = "Острый метательный топорик"
L["CT_ExpenseHistory/Ammo/Small Throwing Knife"] = "Малый метательный нож"
L["CT_ExpenseHistory/Ammo/Smooth Pebble"] = "Шлифованный метательный камень"
L["CT_ExpenseHistory/Ammo/Solid Shot"] = "Твердый патрон"
L["CT_ExpenseHistory/Ammo/Weighted Throwing Axe"] = "Утяжеленный метательный топорик"
L["CT_ExpenseHistory/Reagent/Ankh"] = "Крест"
L["CT_ExpenseHistory/Reagent/Arcane Powder"] = "Порошок чар"
L["CT_ExpenseHistory/Reagent/Ashwood Seed"] = "Семена ясеня"
L["CT_ExpenseHistory/Reagent/Demonic Figurine"] = "Демоническая статуэтка"
L["CT_ExpenseHistory/Reagent/Flash Powder"] = "Воспламеняющийся порошок"
L["CT_ExpenseHistory/Reagent/Holy Candle"] = "Святая свеча"
L["CT_ExpenseHistory/Reagent/Hornbeam Seed"] = "Семена граба"
L["CT_ExpenseHistory/Reagent/Infernal Stone"] = "Камень инфернала"
L["CT_ExpenseHistory/Reagent/Ironwood Seed"] = "Семена железного дерева"
L["CT_ExpenseHistory/Reagent/Maple Seed"] = "Семена клена"
L["CT_ExpenseHistory/Reagent/Rune of Portals"] = "Руна порталов"
L["CT_ExpenseHistory/Reagent/Rune of Teleportation"] = "Руна телепортации"
L["CT_ExpenseHistory/Reagent/Sacred Candle"] = "Священная свеча"
L["CT_ExpenseHistory/Reagent/Stranglethorn Seed"] = "Семя из Тернистой долины"
L["CT_ExpenseHistory/Reagent/Symbol of Divinity"] = "Знак божественности"
L["CT_ExpenseHistory/Reagent/Symbol of Kings"] = "Знак королей"
L["CT_ExpenseHistory/Reagent/Wild Berries"] = "Лесные ягоды"
L["CT_ExpenseHistory/Reagent/Wild Thornroot"] = "Дикий шипокорень"

end