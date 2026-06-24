------------------------------------------------
--            CT_RaidAssist (CTRA)            --
--                                            --
-- Provides features to assist raiders incl.  --
-- customizable raid frames.  CTRA was the    --
-- original raid frame in Vanilla (pre 1.11)  --
-- but has since been re-written completely   --
-- to integrate with the more modern UI.      --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--					      --
-- Original credits to Cide and TS            --
-- Improved by Dargen circa late Vanilla      --
-- Maintained by Resike from 2014 to 2017     --
-- Rebuilt by Dahk Celes (ddc) in 2019        --
------------------------------------------------

-- Please contribute new translations at <https://wow.curseforge.com/projects/ctmod/localization>

local MODULE_NAME, module = ...;
module.text = module.text or { };
local L = module.text

-- enUS (other languages follow underneath)

L["CT_RaidAssist/AfterNotReadyFrame/MissedCheck"] = "You might have missed a ready check!"
L["CT_RaidAssist/AfterNotReadyFrame/WasAFK"] = "You were afk, are you back now?"
L["CT_RaidAssist/AfterNotReadyFrame/WasNotReady"] = "Are you ready now?"
L["CT_RaidAssist/PlayerFrame/TooltipFooter"] = "/ctra to move and configure"
L["CT_RaidAssist/PlayerFrame/TooltipItemsBroken"] = "%d%% durability, %d broken items (as of %d:%02d mins ago)"
L["CT_RaidAssist/PlayerFrame/TooltipItemsNotBroken"] = "%d%% durability (as of %d:%02d mins ago)"
L["CT_RaidAssist/WindowTitle"] = "Window %d"
L["CT_RaidAssist/Options/ClickCast/BuffSubheading"] = "Apply buffs outside combat:"
L["CT_RaidAssist/Options/ClickCast/DropDownOptions"] = "#Right Click#Shift-Right Click#Ctrl-Right Click#Alt-Right Click#Disabled#Left Click#Shift-Left Click#Ctrl-Left Click#Alt-Left Click"
L["CT_RaidAssist/Options/ClickCast/Heading"] = "Click casting"
L["CT_RaidAssist/Options/ClickCast/RemoveDebuffSubheading"] = "Remove debuffs :"
L["CT_RaidAssist/Options/ClickCast/RezCombatSubheading"] = "Resurrect during combat:"
L["CT_RaidAssist/Options/ClickCast/RezNoCombatSubheading"] = "Resurrect outside combat:"
L["CT_RaidAssist/Options/ClickCast/TargetDropDown"] = "#All other clicks#Disabled"
L["CT_RaidAssist/Options/ClickCast/TargetLabel"] = "Target"
L["CT_RaidAssist/Options/ClickCast/ToggleMenuLabel"] = "Toggle Menu"
L["CT_RaidAssist/Options/ClickCast/UtilitySubheading"] = "General actions:"
L["CT_RaidAssist/Options/Frames/DisabledTip"] = "Raid frames are disabled!"
L["CT_RaidAssist/Options/Frames/EnableDropDown"] = "#Always#During Raids#During Groups#Never"
L["CT_RaidAssist/Options/Frames/EnableLabel"] = "Enable custom frames:"
L["CT_RaidAssist/Options/Frames/Heading"] = "Custom Raid Frames"
L["CT_RaidAssist/Options/Frames/HideBlizzardDefaultCheckButton"] = "Hide Blizzard's Default Raid Frames"
L["CT_RaidAssist/Options/Frames/HideBlizzardDefaultTooltip"] = [=[Prevents default raid groups from appearing whenever custom CTRA frames are present.
Has no effect if CTRA frames are disabled.

Note: some other addons may also disable the default frames.]=]
L["CT_RaidAssist/Options/Frames/ShareClassicHealPredictionCheckButton"] = "Let CTRA share your healing with the raid"
L["CT_RaidAssist/Options/Frames/ShareClassicHealPredictionTip"] = [=[Share your outgoing heals with peers using addons like CTRA, Shadowed, Grid or IceHud.

Notes:
- This Classic-only option mimics a Retail feature
- Info about your heals will be transmitted to raid members
- Other addons may enable sharing even if CTRA does not
- This requires a /reload to disable]=]
L["CT_RaidAssist/Options/ReadyCheckMonitor/ExtendReadyChecksCheckButton"] = "Extend missed ready checks"
L["CT_RaidAssist/Options/ReadyCheckMonitor/ExtendReadyChecksTooltip"] = [=[Provides a button to announce returning 
after missing a /readycheck]=]
L["CT_RaidAssist/Options/ReadyCheckMonitor/Heading"] = "Ready Check Enhancements"
L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilityLabel"] = "Provide warnings if your durability is getting low"
L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilityMessage"] = [=[Please /reload for CTRA to stop sharing durability.
Other raid addons like DBM and oRA may re-activate this feature.]=]
L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilitySlider"] = "Warn if gear below <value>%:Off:50%"
L["CT_RaidAssist/Options/ReadyCheckMonitor/ShareDurabilityCheckButton"] = "Let CTRA share your durability with the raid"
L["CT_RaidAssist/Options/ReadyCheckMonitor/ShareDurabilityTooltip"] = [=[Share your durability with peers using addons like CTRA, DBM or oRA.

Notes:
- Other addons may enable sharing even if you opt out with CTRA
- This requires a /reload to take effect]=]
L["CT_RaidAssist/Options/ReadyCheckMonitor/Tooltip"] = "These settings are meant for raiding guilds using CT"
L["CT_RaidAssist/Options/Window/Appearance/EnablePowerBarCheckButton"] = "Show power bar"
L["CT_RaidAssist/Options/Window/Appearance/EnablePowerBarTooltip"] = "Show the mana, energy, rage, etc. at the bottom"
L["CT_RaidAssist/Options/Window/Appearance/EnableTargetFrameCheckButton"] = "Show the target underneath"
L["CT_RaidAssist/Options/Window/Appearance/EnableTargetFrameTooltip"] = "Add a frame underneath each player with the name of its target (often used for tanks)"
L["CT_RaidAssist/Options/Window/Appearance/Heading"] = "Appearance"
L["CT_RaidAssist/Options/Window/Appearance/HealthBarAsBackgroundCheckButton"] = "Show health as full-size background"
L["CT_RaidAssist/Options/Window/Appearance/HealthBarAsBackgroundTooltip"] = "Fill the entire background as one large health metre.  Otherwise, health is just a small bar at the bottom"
L["CT_RaidAssist/Options/Window/Appearance/Line1"] = "Do you want the retro CTRA feel, or more a modern look?"
L["CT_RaidAssist/Options/Window/Appearance/ShowHealthTextCheckButton"] = "Show health percentage"
L["CT_RaidAssist/Options/Window/Appearance/ShowHealthTextTooltip"] = "Adds text in front of the health bar while injured"
L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsDropDown"] = "#Yes#My heals only#No"
L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsLabel"] = "Show incoming heals:"
L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsTip"] = [=[Lengthens the health bar (but not beyond full health) to show incoming heals from...
- On Retail, everyone
- On Classic, players with a compatible addon (CTRA, Shadowed, Grid, IceHUD, etc.)]=]
L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsDropDown"] = "#Yes#My shields only#No"
L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsLabel"] = "Show total absorbs:"
L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsTip"] = "Lengthens the health bar (but not beyond full health) to show how much damage can be absorbed before further health is lost."
L["CT_RaidAssist/Options/Window/Appearance/TargetHealthCheckButton"] = "Also show target's health bar"
L["CT_RaidAssist/Options/Window/Appearance/TargetHealthTip"] = "Uses the same settings as the player frame's health bar"
L["CT_RaidAssist/Options/Window/Appearance/TargetPowerCheckButton"] = "Also show target's power bar"
L["CT_RaidAssist/Options/Window/Appearance/TargetPowerTip"] = "Uses the same settings as the player's frame's power bar to show the target's mana, rage, energy, etc."
L["CT_RaidAssist/Options/Window/Auras/CombatLabel"] = "Show during combat:"
L["CT_RaidAssist/Options/Window/Auras/DropDown"] = "#Group buffs I can apply#Debuffs I can remove#All group buffs#All debuffs#Group buffs I applied#Nothing"
L["CT_RaidAssist/Options/Window/Auras/Heading"] = "Buffs and Debuffs"
L["CT_RaidAssist/Options/Window/Auras/NoCombatLabel"] = "Show out of combat:"
L["CT_RaidAssist/Options/Window/Auras/RemovableDebuffColorCheckButton"] = "Add colour to removable debuffs"
L["CT_RaidAssist/Options/Window/Auras/RemovableDebuffColorTip"] = "Changes the background and border when you can remove a harmful debuff."
L["CT_RaidAssist/Options/Window/Auras/ShowBossCheckButton"] = "Show important boss auras at middle"
L["CT_RaidAssist/Options/Window/Auras/ShowBossTip"] = [=[Certain boss encounters create important buffs/debuffs critical to the fight.
These will appear larger at the middle for emphasis.]=]
L["CT_RaidAssist/Options/Window/Auras/ShowReverseCooldownCheckButton"] = "Identify auras expiring soon"
L["CT_RaidAssist/Options/Window/Auras/ShowReverseCooldownTip"] = [=[Adds a cooldown animation to auras with less than 50% of time remaining
Note: this feature is limited on WoW Classic due to game restrictions]=]
L["CT_RaidAssist/Options/Window/Color/BackgroundClassHeading"] = "Class background color"
L["CT_RaidAssist/Options/Window/Color/BackgroundClassSlider"] = "Background = <value>%"
L["CT_RaidAssist/Options/Window/Color/BackgroundClassTip"] = [=[Changes the background color by a proportionate amount.
However, uses the same transparency (alpha) as the standard background color. ]=]
L["CT_RaidAssist/Options/Window/Color/BorderClassHeading"] = "Class border color"
L["CT_RaidAssist/Options/Window/Color/BorderClassSlider"] = "Border = <value>%"
L["CT_RaidAssist/Options/Window/Color/BorderClassTip"] = [=[Changes the border color by a proportionate amount.
However, uses the same transparency (alpha) as the standard border color. ]=]
L["CT_RaidAssist/Options/Window/Color/Line1"] = "First, set a standard colour palette:"
L["CT_RaidAssist/Options/Window/Color/Line2"] = "Next, blend in class colours:"
L["CT_RaidAssist/Options/Window/Groups/ClassHeader"] = "Classes"
L["CT_RaidAssist/Options/Window/Groups/GroupHeader"] = "Groups"
L["CT_RaidAssist/Options/Window/Groups/GroupTooltipContent"] = [=[0.9:0.9:0.9#|cFFFFFF99During a raid: |r
- self-explanatory

|cFFFFFF99Outside of raiding: |r
- Gp 1 is you and your party]=]
L["CT_RaidAssist/Options/Window/Groups/GroupTooltipHeader"] = "Groups 1 to 8"
L["CT_RaidAssist/Options/Window/Groups/Header"] = "Group and Class Selections"
L["CT_RaidAssist/Options/Window/Groups/Line1"] = "Which groups, roles or classes should this window show?"
L["CT_RaidAssist/Options/Window/Groups/RoleHeader"] = "Roles"
L["CT_RaidAssist/Options/Window/Groups/ShowDuplicatesOnceOnlyCheckButton"] = "Avoid duplicates"
L["CT_RaidAssist/Options/Window/Groups/ShowDuplicatesOnceOnlyTip"] = "If a player could appear more than once, show them the first time only."
L["CT_RaidAssist/Options/Window/Groups/ShowGroupLabelsCheckButton"] = "Show group labels"
L["CT_RaidAssist/Options/Window/Groups/ShowGroupLabelsTip"] = [=[Adds a label before each column to indicate its groups/roles/classes.
This option looks best when a new column is made for each group.]=]
L["CT_RaidAssist/Options/Window/Layout/Heading"] = "Layout"
L["CT_RaidAssist/Options/Window/Layout/OrientationDropdown"] = "#New |cFFFFFF00column|r for each group#New |cFFFFFF00row|r for each group#Merge raid to a |cFFFFFF00single column|r (subject to wrapping)#Merge raid to a |cFFFFFF00single row|r (subject to wrapping)"
L["CT_RaidAssist/Options/Window/Layout/OrientationLabel"] = "Use rows or columns?"
L["CT_RaidAssist/Options/Window/Layout/Tip"] = [=[The raid frames will expand/shrink into
rows and columns using these settings]=]
L["CT_RaidAssist/Options/Window/Layout/WrapLabel"] = "Large rows/cols:"
L["CT_RaidAssist/Options/Window/Layout/WrapSlider"] = "Wrap after <value>"
L["CT_RaidAssist/Options/Window/Layout/WrapTooltipContent"] = [=[0.9:0.9:0.9#Starts a new row or column when it is too long

|cFFFFFF99Example:|r 
- Set earlier checkboxes to show all eight groups
- Set earlier dropdown to 'Merge raid to a single row'
- Set this slider to wrap after 10 players
- Now a 40-man raid appears as four rows of 10]=]
L["CT_RaidAssist/Options/Window/Layout/WrapTooltipHeader"] = "Wrapping large rows/columns:"
L["CT_RaidAssist/Options/Window/Size/BorderThicknessDropDown"] = "#Fine#Medium#Heavy"
L["CT_RaidAssist/Options/Window/Size/BorderThicknessLabel"] = "Border Thickness:"
L["CT_RaidAssist/Options/WindowControls/AddButton"] = "Add"
L["CT_RaidAssist/Options/WindowControls/AddTooltip"] = "Add a new window with default settings."
L["CT_RaidAssist/Options/WindowControls/CloneButton"] = "Clone"
L["CT_RaidAssist/Options/WindowControls/CloneTooltip"] = "Add a new window with settings that duplicate those of the currently selected window."
L["CT_RaidAssist/Options/WindowControls/DeleteButton"] = "Delete"
L["CT_RaidAssist/Options/WindowControls/DeleteTooltip"] = "|cFFFFFF00Shift-click|r this button to delete the currently selected window."
L["CT_RaidAssist/Options/WindowControls/Heading"] = "Windows"
L["CT_RaidAssist/Options/WindowControls/Line1"] = "Each window has its own appearance, configurable below."
L["CT_RaidAssist/Options/WindowControls/SelectionLabel"] = "Select window:"
L["CT_RaidAssist/Options/WindowControls/WindowAddedMessage"] = "Window %d added."
L["CT_RaidAssist/Options/WindowControls/WindowClonedMessage"] = "Window %d added, copying settings from window %d."
L["CT_RaidAssist/Options/WindowControls/WindowDeletedMessage"] = "Window %d deleted."
L["CT_RaidAssist/Options/WindowControls/WindowSelectedMessage"] = "Window %d selected."


-----------------------------------------------
-- frFR
-- Credits to ddc, FTB_Exper

if (GetLocale() == "frFR") then

L["CT_RaidAssist/AfterNotReadyFrame/MissedCheck"] = "Vous pourriez manquer un appel; êtes-vous prêt?"
L["CT_RaidAssist/AfterNotReadyFrame/WasAFK"] = "Vous étiez absent.  Revenez-vous?"
L["CT_RaidAssist/AfterNotReadyFrame/WasNotReady"] = "Êtes-vous prêt maintenant?"
L["CT_RaidAssist/PlayerFrame/TooltipFooter"] = "/ctra pour déplacer et configurer"
L["CT_RaidAssist/PlayerFrame/TooltipItemsBroken"] = "%d%% durabilité, %d objets brisés (il y a %d:%02d mins)"
L["CT_RaidAssist/PlayerFrame/TooltipItemsNotBroken"] = "%d%% durabilité (il y a %d:%02d mins)"
L["CT_RaidAssist/WindowTitle"] = "Fenêtre %d"
L["CT_RaidAssist/Options/ClickCast/BuffSubheading"] = "Ajouter des auras utiles dehors le combat :"
L["CT_RaidAssist/Options/ClickCast/DropDownOptions"] = "#Clic-droit#MAJ clic-droit#CTRL clic-droitk#ALT clic-droit#Désactivé#Clic-gauche#MAJ clic-gauche#CTRL clic-gauche#ALT clic-gauche"
L["CT_RaidAssist/Options/ClickCast/Heading"] = "Lancer des sorts par souris"
L["CT_RaidAssist/Options/ClickCast/RemoveDebuffSubheading"] = "Annuler des auras nocives :"
L["CT_RaidAssist/Options/ClickCast/RezCombatSubheading"] = "Faire revivre pendant le combat :"
L["CT_RaidAssist/Options/ClickCast/RezNoCombatSubheading"] = "Faire revivre dehors le combat :"
L["CT_RaidAssist/Options/ClickCast/TargetDropDown"] = "#Tous les autres clics#Désactivé"
L["CT_RaidAssist/Options/ClickCast/TargetLabel"] = "Cibler"
L["CT_RaidAssist/Options/ClickCast/ToggleMenuLabel"] = "Basculer le menu"
L["CT_RaidAssist/Options/ClickCast/UtilitySubheading"] = "Actions générales :"
L["CT_RaidAssist/Options/Frames/DisabledTip"] = "Les cadres personnalisés sont désactivées!"
L["CT_RaidAssist/Options/Frames/EnableDropDown"] = "#Toujours#Pendant les raids#Pendant les groupes#Jamais"
L["CT_RaidAssist/Options/Frames/EnableLabel"] = "Activer les cadres personnalisés :"
L["CT_RaidAssist/Options/Frames/Heading"] = "Les cadres personnalisés"
L["CT_RaidAssist/Options/Frames/HideBlizzardDefaultCheckButton"] = "Masquer les cadres de raid par défaut de Blizzard"
L["CT_RaidAssist/Options/Frames/HideBlizzardDefaultTooltip"] = [=[Empêche les groupes de raid par défaut d'apparaître 
chaque fois que des cadres CTRA personnalisés sont présents.
N'a aucun effet si les trames CTRA sont désactivées.

Remarque:
Certains autres compléments peuvent également désactiver les cadres par défaut.]=]
L["CT_RaidAssist/Options/Frames/ShareClassicHealPredictionCheckButton"] = "Permettre CTRA de partager vos sorts de soins"
L["CT_RaidAssist/Options/Frames/ShareClassicHealPredictionTip"] = [=[Partager vos sorts de soins avec les membres du raid à l'aide d'addons comme CTRA, Shadowed, Grid or IceHud.

Avis:
- Ceci permet les addons classiques de montre les soins en progrès 
- Les renseignements serons transmis aux membres du groupe
- Même si l'option est désactivé, les autres addons peuvent encore les transmettre
- Il faut /reload pour déactiver cette option]=]
L["CT_RaidAssist/Options/ReadyCheckMonitor/ExtendReadyChecksCheckButton"] = "Prolonger un /readycheck manqué"
L["CT_RaidAssist/Options/ReadyCheckMonitor/ExtendReadyChecksTooltip"] = "Fournir un bouton pour annoncer le retour après avoir manqué un /readycheck"
L["CT_RaidAssist/Options/ReadyCheckMonitor/Heading"] = "Améliorations de Ready Check"
L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilityLabel"] = "Fournir des avertissements si votre durabilité est faible"
L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilityMessage"] = "Veuillez /reload pour que CTRA cesse de partager la durabilité. D'autres extensions de raid comme DBM et oRA peuvent réactiver cette fonctionnalité."
L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilitySlider"] = "Avertir si la durabilité est inférieure à <value>%:désactivé:50%"
L["CT_RaidAssist/Options/ReadyCheckMonitor/ShareDurabilityCheckButton"] = "Permettre CTRA de partager votre durabilité avec le raid"
L["CT_RaidAssist/Options/ReadyCheckMonitor/ShareDurabilityTooltip"] = [=[Partager votre durabilité avec les membres du groupe à l'aide d'addons comme CTRA, DBM ou oRA.

Remarques: 
- D'autres extensions peuvent permettre le partage même si vous vous désabonnez avec CTRA 
- Cela nécessite un /reload pour prendre effet]=]
L["CT_RaidAssist/Options/ReadyCheckMonitor/Tooltip"] = "Ces paramètres sont destinés aux raids en guilde utilisant CT"
L["CT_RaidAssist/Options/Window/Appearance/EnablePowerBarCheckButton"] = "Afficher la barre de ressource"
L["CT_RaidAssist/Options/Window/Appearance/EnablePowerBarTooltip"] = "Montrer le mana, l'énergie, la rage, etc. en bas"
L["CT_RaidAssist/Options/Window/Appearance/EnableTargetFrameCheckButton"] = "Montrer la cible en dessous?"
L["CT_RaidAssist/Options/Window/Appearance/EnableTargetFrameTooltip"] = "Ajouter un cadre sous chaque joueur avec le nom de sa cible (souvent utilisé pour les tanks)"
L["CT_RaidAssist/Options/Window/Appearance/Heading"] = "Apparence"
L["CT_RaidAssist/Options/Window/Appearance/HealthBarAsBackgroundCheckButton"] = "Afficher la santé en arrière-plan en taille réelle"
L["CT_RaidAssist/Options/Window/Appearance/HealthBarAsBackgroundTooltip"] = "Remplisser tout l'arrière-plan comme un grand compteur de santé. Sinon, la santé n'est qu'une petite barre en bas"
L["CT_RaidAssist/Options/Window/Appearance/Line1"] = "Voulez-vous un style rétro CTRA, ou plutôt un look moderne?"
L["CT_RaidAssist/Options/Window/Appearance/ShowHealthTextCheckButton"] = "Afficher le pourcentage de santé"
L["CT_RaidAssist/Options/Window/Appearance/ShowHealthTextTooltip"] = "Afficher le pourcentage de santé lors de blessure"
L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsDropDown"] = "#Oui#Mes sorts de soins#Non"
L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsLabel"] = "Montrer les soins en progrès :"
L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsTip"] = [=[Allonger la barre de santé (pas dépasser plein santé) pour montrer les sorts de soins en progrès, de...
- sur WoW moderne, tout le monde
- sur WoW classique, les joueurs avec un addon compatible (CTRA, Shadowed, Grid, IceHUD, etc.)]=]
L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsDropDown"] = "#Oui#Mes sorts de protection#Non"
L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsLabel"] = "Montre la protection totale :"
L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsTip"] = "Allonger la barre de santé (pas dépasser plein santé) pour montrer combien de dommage peut être absorbé avant de perdre plus de santé."
L["CT_RaidAssist/Options/Window/Appearance/TargetHealthCheckButton"] = "Montrer la santé de la cible"
L["CT_RaidAssist/Options/Window/Appearance/TargetHealthTip"] = "La santé de la cible apparaîtrait même que celle du joueur."
L["CT_RaidAssist/Options/Window/Appearance/TargetPowerCheckButton"] = "Montrer la ressource de la cible"
L["CT_RaidAssist/Options/Window/Appearance/TargetPowerTip"] = "La ressource (le mana, l'énergie, la rage, etc.) de la cible apparaîtrait même que celle du joueur."
L["CT_RaidAssist/Options/Window/Auras/CombatLabel"] = [=[Montrer pendant 
le combat :]=]
L["CT_RaidAssist/Options/Window/Auras/DropDown"] = "#Les auras utiles que je peux appliquer aux autres#Les auras nocives que je peux retirer#Tous les auras utiles de groupe#Tous les auras nocives#Les auras utiles de groupe que j'ai appliqué#Rien"
L["CT_RaidAssist/Options/Window/Auras/Heading"] = "Les auras"
L["CT_RaidAssist/Options/Window/Auras/NoCombatLabel"] = "Montrer hors combat :"
L["CT_RaidAssist/Options/Window/Auras/RemovableDebuffColorCheckButton"] = "Ajouter de la couleur aux debuffs amovibles"
L["CT_RaidAssist/Options/Window/Auras/RemovableDebuffColorTip"] = "Changer le fond et bordure quand vous pouvez réduire un aura nocive."
L["CT_RaidAssist/Options/Window/Auras/ShowBossCheckButton"] = "Montrer les auras de combat de boss au milieu"
L["CT_RaidAssist/Options/Window/Auras/ShowBossTip"] = "Souligner les mécaniques des combats de boss en mettre l'aura au milieu avec plus grandeur."
L["CT_RaidAssist/Options/Window/Auras/ShowReverseCooldownCheckButton"] = "Indiquer les auras qui expirent bientôt"
L["CT_RaidAssist/Options/Window/Auras/ShowReverseCooldownTip"] = [=[Ajouter une animation de temps de recharge aux auras avec moins de 50% de temps resté.

Avis: cette option est limité sur WoW classique à cause des restrictions de jeu.]=]
L["CT_RaidAssist/Options/Window/Color/Line1"] = "Premièrement, choisissez une palette de couleurs :"
L["CT_RaidAssist/Options/Window/Color/Line2"] = "Après, mélangez les couleurs de classe :"
L["CT_RaidAssist/Options/Window/Groups/ClassHeader"] = "Classes"
L["CT_RaidAssist/Options/Window/Groups/GroupHeader"] = "Groupes"
L["CT_RaidAssist/Options/Window/Groups/GroupTooltipContent"] = [=[0.9:0.9:0.9#|cFFFFFF99Pendent un raid: |r
- Explicite

|cFFFFFF99Hors un raid: |r
- Le 1re groupe devient vous et votre partie]=]
L["CT_RaidAssist/Options/Window/Groups/GroupTooltipHeader"] = "Les groupes 1 à 8"
L["CT_RaidAssist/Options/Window/Groups/Header"] = "Les sélections de groupes et classes"
L["CT_RaidAssist/Options/Window/Groups/Line1"] = "Ce fenêtre montre lesquels groupes, rôles et classes?"
L["CT_RaidAssist/Options/Window/Groups/RoleHeader"] = "Rôles"
L["CT_RaidAssist/Options/Window/Layout/WrapLabel"] = [=[Des grands 
rangs/colonnes :]=]
L["CT_RaidAssist/Options/Window/Layout/WrapSlider"] = "Habillage du texte après <value>"
L["CT_RaidAssist/Options/WindowControls/AddButton"] = "Ajouter"
L["CT_RaidAssist/Options/WindowControls/AddTooltip"] = "Ajouter une fenêtre avec les options defauts."
L["CT_RaidAssist/Options/WindowControls/CloneButton"] = "Copier"
L["CT_RaidAssist/Options/WindowControls/CloneTooltip"] = "Ajouter une fenêtre qui copie les options de celle-ci."
L["CT_RaidAssist/Options/WindowControls/DeleteButton"] = "Supprimer"
L["CT_RaidAssist/Options/WindowControls/DeleteTooltip"] = "|cFFFFFF00Maj-clic|r ce bouton pour supprimer la fênetre sélectionnée"
L["CT_RaidAssist/Options/WindowControls/Heading"] = "Des fenêtres"
L["CT_RaidAssist/Options/WindowControls/Line1"] = "Chaque fenêtre a une apparence unique, configurable ci-dessous"
L["CT_RaidAssist/Options/WindowControls/SelectionLabel"] = "Sélectionner :"
L["CT_RaidAssist/Options/WindowControls/WindowAddedMessage"] = "La fenêtre %d ajoutée."
L["CT_RaidAssist/Options/WindowControls/WindowClonedMessage"] = "La fenêtre %d ajoutée, comme un copier de la fenêtre %d."
L["CT_RaidAssist/Options/WindowControls/WindowDeletedMessage"] = "La fenêtre %d supprimée."
L["CT_RaidAssist/Options/WindowControls/WindowSelectedMessage"] = "La fenêtre %d sélectionnée."


-----------------------------------------------
-- deDE
-- Credits to dynaletik

elseif (GetLocale() == "deDE") then

L["CT_RaidAssist/AfterNotReadyFrame/MissedCheck"] = "Ggf. hast Du einen Bereitschaftscheck verpasst!"
L["CT_RaidAssist/AfterNotReadyFrame/WasAFK"] = "Du warst AFK, bist Du zurück?"
L["CT_RaidAssist/AfterNotReadyFrame/WasNotReady"] = "Bist Du jetzt bereit?"
L["CT_RaidAssist/PlayerFrame/TooltipFooter"] = "/ctra zum Verschieben und Konfigurieren"
L["CT_RaidAssist/PlayerFrame/TooltipItemsBroken"] = "%d%% Haltbarkeit, %d kaputte Gegenstände (vor %d:%02d Minuten)"
L["CT_RaidAssist/PlayerFrame/TooltipItemsNotBroken"] = "%d%% Haltbarkeit (vor %d:%02d Minuten)"
L["CT_RaidAssist/WindowTitle"] = "Fenster %d"
L["CT_RaidAssist/Options/ClickCast/BuffSubheading"] = "Zauber außerhalb des Kampfes wirken:"
L["CT_RaidAssist/Options/ClickCast/DropDownOptions"] = "#Rechtsklick#Shift-Rechtsklick#Strg-Rechtsklick#Alt-Rechtsklick#Deaktiviert#Linksklick#Shift-Linksklick#Strg-Linksklick#Alt-Linksklick"
L["CT_RaidAssist/Options/ClickCast/Heading"] = "Zauber per Klick wirken"
L["CT_RaidAssist/Options/ClickCast/RemoveDebuffSubheading"] = "Schwächungszauber entfernen:"
L["CT_RaidAssist/Options/ClickCast/RezCombatSubheading"] = "Wiederbelebung während des Kampfes:"
L["CT_RaidAssist/Options/ClickCast/RezNoCombatSubheading"] = "Wiederbelebung außerhalb des Kampfes:"
L["CT_RaidAssist/Options/ClickCast/TargetDropDown"] = "#Alle anderen Klicks#Deaktiviert"
L["CT_RaidAssist/Options/ClickCast/TargetLabel"] = "Ziel"
L["CT_RaidAssist/Options/ClickCast/ToggleMenuLabel"] = "Menü ein-/ausblenden"
L["CT_RaidAssist/Options/ClickCast/UtilitySubheading"] = "Generelle Aktionen:"
L["CT_RaidAssist/Options/Frames/DisabledTip"] = "Schlachtzugsfenster sind deaktiviert!"
L["CT_RaidAssist/Options/Frames/EnableDropDown"] = "#Immer#In Schlachtzügen#In Gruppen#Nie"
L["CT_RaidAssist/Options/Frames/EnableLabel"] = "Benutzerdefinierte Fenster aktivieren:"
L["CT_RaidAssist/Options/Frames/Heading"] = "Benutzerdefinierte Schlachtzugsfenster"
L["CT_RaidAssist/Options/Frames/HideBlizzardDefaultCheckButton"] = "Blizzard's Standard-Schlachtzugfenster ausblenden"
L["CT_RaidAssist/Options/Frames/HideBlizzardDefaultTooltip"] = "Blendet die Standard-Schlachtzugsgruppen aus sobald CTRA Fenster aktiv sind. Hat keine Auswirkungen, wenn CTRA Fenster deaktiviert sind. Hinweis: Einige andere Addons können die Standard Fenster ebenfalls ausblenden."
L["CT_RaidAssist/Options/Frames/ShareClassicHealPredictionCheckButton"] = "Deine Heilung über CTRA mit dem Schlachtzug teilen"
L["CT_RaidAssist/Options/Frames/ShareClassicHealPredictionTip"] = "Ausgehende Heilung mit Nutzern von Addons wie CTRA, Shadowed, Grid oder IceHud teilen. Hinweise: - Diese auf Classic beschränkte Option imitiert eine Retail Funktion - Infos über Deine Heilung werden an den Schlachtzug gesendet. - Weitere Addons können das Senden aktivieren, auch wenn CTRA dies nicht tut - Benötigt /reload zum Deaktivieren"
L["CT_RaidAssist/Options/ReadyCheckMonitor/ExtendReadyChecksCheckButton"] = "Erweiterte Bereitschaftschecks anzeigen"
L["CT_RaidAssist/Options/ReadyCheckMonitor/ExtendReadyChecksTooltip"] = "Zeigt nach Verpassen eines Bereitschaftschecks eine Schaltfläche an um mitzuteilen, dass man wieder da ist"
L["CT_RaidAssist/Options/ReadyCheckMonitor/Heading"] = "Erweiterter Bereitschaftscheck"
L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilityLabel"] = "Warnungen anzeigen wenn die Haltbarkeit niedrig ist."
L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilityMessage"] = "Bitte nutze /reload damit CTRA nicht länger die Haltbarkeit teilt. Andere Addons wie DBM und oRA können diese Funktion reaktivieren."
L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilitySlider"] = "Warnen bei Haltbarkeit unter <value>%:Aus:50%"
L["CT_RaidAssist/Options/ReadyCheckMonitor/ShareDurabilityCheckButton"] = "CTRA die Haltbarkeit an den Schlachtzug senden lassen"
L["CT_RaidAssist/Options/ReadyCheckMonitor/ShareDurabilityTooltip"] = "Teilt Deine Haltbarkeit mit anderen Nutzern von Addons wie CTRA, DBM oder oRA. Hinweis: -Andere Addons können diese Funktion aktivieren, auch wenn diese in CTRA deaktiviert ist - Benötigt /reload um in Kraft zu treten"
L["CT_RaidAssist/Options/ReadyCheckMonitor/Tooltip"] = "Diese Einstellungen sind für Raidgilden gedacht, welche CT nutzen"
L["CT_RaidAssist/Options/Window/Appearance/EnablePowerBarCheckButton"] = "Energieleiste anzeigen"
L["CT_RaidAssist/Options/Window/Appearance/EnablePowerBarTooltip"] = "Mana, Energie, Wut, etc. am unteren Rand anzeigen"
L["CT_RaidAssist/Options/Window/Appearance/EnableTargetFrameCheckButton"] = "Ziel unter Spieler anzeigen"
L["CT_RaidAssist/Options/Window/Appearance/EnableTargetFrameTooltip"] = "Unter jedem Spieler ein Fenster mit dem Namen seines Ziels einfügen (oft für Tanks genutzt)"
L["CT_RaidAssist/Options/Window/Appearance/Heading"] = "Aussehen"
L["CT_RaidAssist/Options/Window/Appearance/HealthBarAsBackgroundCheckButton"] = "Gesundheit als vollflächigen Hintergrund anzeigen"
L["CT_RaidAssist/Options/Window/Appearance/HealthBarAsBackgroundTooltip"] = "Füllt den gesamten Hintergrund als eine große Gesundheitsanzeige auf. Andernfalls ist die Gesundheitsanzeige lediglich eine kleine Leiste am unteren Rand."
L["CT_RaidAssist/Options/Window/Appearance/Line1"] = "Soll CTRA im alten oder neueren Design angezeigt werden?"
L["CT_RaidAssist/Options/Window/Appearance/ShowHealthTextCheckButton"] = "Gesundheit in Prozent anzeigen"
L["CT_RaidAssist/Options/Window/Appearance/ShowHealthTextTooltip"] = "Fügt bei Verwundung den Text vor der Gesundheitsleiste ein"
L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsDropDown"] = "#Ja#Nur meine Heilung#Nein"
L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsLabel"] = "Eingehende Heilung zeigen:"
L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsTip"] = [=[Verlängert die HP Leiste (nicht über volle HP hinaus) um eingehende Heilung anzuzeigen von...
- In Retail von jedem - In Classic von Nutzern kompatibler Addons (CTRA, Shadowed, Grid, IceHUD, etc.)]=]
L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsDropDown"] = "#Ja#Nur meine Schilde#Nein"
L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsLabel"] = "Gesamte Absorbtion anzeigen:"
L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsTip"] = "Verlängert die HP Leiste (nicht über volle HP hinaus) um anzuzeigen, wieviel Schaden absorbiert werden kann, bevor Gesundheit verloren wird."
L["CT_RaidAssist/Options/Window/Appearance/TargetHealthCheckButton"] = "Leiste mit Zielgesundheit anzeigen"
L["CT_RaidAssist/Options/Window/Appearance/TargetHealthTip"] = "Nutzt die Einstellungen der Gesundheitsleiste des Spielers"
L["CT_RaidAssist/Options/Window/Appearance/TargetPowerCheckButton"] = "Leiste mit Zielenergie anzeigen"
L["CT_RaidAssist/Options/Window/Appearance/TargetPowerTip"] = "Nutzt die Einstellungen der Energieleiste des Spielers um Mana, Wut, Energie, etc. des Ziels anzuzeigen"
L["CT_RaidAssist/Options/Window/Auras/CombatLabel"] = "Während des Kampfes anzeigen:"
L["CT_RaidAssist/Options/Window/Auras/DropDown"] = "#Wirkbare Gruppenzauber#Entfernbare Schwächungszauber#Alle Gruppenzauber#Alle Schwächungszauber#Gewirkte Gruppenzauber#Nichts"
L["CT_RaidAssist/Options/Window/Auras/Heading"] = "Stärkungs- und Schwächungszauber"
L["CT_RaidAssist/Options/Window/Auras/NoCombatLabel"] = "Außerhalb des Kampfes anzeigen:"
L["CT_RaidAssist/Options/Window/Auras/RemovableDebuffColorCheckButton"] = "Entfernbaren Schwächungszaubern Farbe hinzufügen"
L["CT_RaidAssist/Options/Window/Auras/RemovableDebuffColorTip"] = "Ändert den Hintergrund und Rahmen wenn Du einen Schwächungszauber entfernen kannst."
L["CT_RaidAssist/Options/Window/Auras/ShowBossCheckButton"] = "Wichtige Bossauren mittig anzeigen"
L["CT_RaidAssist/Options/Window/Auras/ShowBossTip"] = "Einige Bosse besitzen wichtige Stärkungs-/Schwächungszauber während des Kampfes. Diese erscheinen zur Erregung der Aufmerksamkeit vergrößert in der Mitte."
L["CT_RaidAssist/Options/Window/Auras/ShowReverseCooldownCheckButton"] = "Bald endende Auren kennzeichnen"
L["CT_RaidAssist/Options/Window/Auras/ShowReverseCooldownTip"] = "Fügt eine Abklingzeit-Animation zu Auren mit weniger als 50% Ihrer Dauer hinzu. Hinweis: Diese Funktion besitzt in WoW Classic durch Spieleinschränkungen einen limitierten Umfang."
L["CT_RaidAssist/Options/Window/Color/BackgroundClassHeading"] = "Hintergrundfarbe der Klassen"
L["CT_RaidAssist/Options/Window/Color/BackgroundClassSlider"] = "Hintergrund = <value>%"
L["CT_RaidAssist/Options/Window/Color/BackgroundClassTip"] = "Ändert die Hintergrundfarbe um einen angegebenen Wert. Benutzt allerdings die gleiche Transparenz wie die Standard-Hintergrundfarbe."
L["CT_RaidAssist/Options/Window/Color/BorderClassHeading"] = "Farbe der Klassenrahmen"
L["CT_RaidAssist/Options/Window/Color/BorderClassSlider"] = "Rahmen = <value>%"
L["CT_RaidAssist/Options/Window/Color/BorderClassTip"] = "Ändert die Rahmenfarbe um einen angegebenen Wert. Benutzt allerdings die gleiche Transparenz wie die Standard-Rahmenfarbe."
L["CT_RaidAssist/Options/Window/Color/Line1"] = "Zuerst die Standard-Farbpalette festlegen:"
L["CT_RaidAssist/Options/Window/Color/Line2"] = "Dann Klassenfarben einblenden:"
L["CT_RaidAssist/Options/Window/Groups/ClassHeader"] = "Klassen"
L["CT_RaidAssist/Options/Window/Groups/GroupHeader"] = "Gruppen"
L["CT_RaidAssist/Options/Window/Groups/GroupTooltipContent"] = [=[0.9:0.9:0.9#|cFFFFFF99Im Schlachtzug: |r
 - selbsterklärend
 |cFFFFFF99Außerhalb Schlachtzug: |r
 - Gruppe 1 seid Ihr und Eure Gruppe]=]
L["CT_RaidAssist/Options/Window/Groups/GroupTooltipHeader"] = "Gruppen 1 bis 8"
L["CT_RaidAssist/Options/Window/Groups/Header"] = "Gruppen- und Klassenauswahl"
L["CT_RaidAssist/Options/Window/Groups/Line1"] = "Welche Gruppen, Rollen oder Klassen soll dieses Fenster zeigen?"
L["CT_RaidAssist/Options/Window/Groups/RoleHeader"] = "Rollen"
L["CT_RaidAssist/Options/Window/Groups/ShowDuplicatesOnceOnlyCheckButton"] = "Duplikate vermeiden"
L["CT_RaidAssist/Options/Window/Groups/ShowDuplicatesOnceOnlyTip"] = "Wenn ein Spieler öfter auftauchen könnte, wird dieser nur einmalig angezeigt."
L["CT_RaidAssist/Options/Window/Groups/ShowGroupLabelsCheckButton"] = "Gruppenbezeichnungen anzeigen"
L["CT_RaidAssist/Options/Window/Groups/ShowGroupLabelsTip"] = "Fügt vor jeder Spalte eine Bezeichnung ein, um die Gruppen/Rollen/Klassen zu kennzeichnen. Am Besten wird für diese Option für jede Gruppe eine neue Spalte angelegt."
L["CT_RaidAssist/Options/Window/Layout/Heading"] = "Anordnung"
L["CT_RaidAssist/Options/Window/Layout/OrientationDropdown"] = "#Neue |cFFFFFF00Spalte|r für jede Gruppe#Neue |cFFFFFF00Zeile|r für jede Gruppe#Schlachtzug in einer |cFFFFFF00einzelnen Spalte|r anzeigen (ggf. mit Umbruch)#Schlachtzug in einerFFFFFF00einzelnen Zeile|r anzeigen (ggf. mit Umbruch)"
L["CT_RaidAssist/Options/Window/Layout/OrientationLabel"] = "Zeilen oder Spalten verwenden?"
L["CT_RaidAssist/Options/Window/Layout/Tip"] = "Die Schlachtzugsfenster werden in Zeilen und Spalten mit diesen Einstellungen angezeigt"
L["CT_RaidAssist/Options/Window/Layout/WrapLabel"] = "Große Zeilen/Spalten:"
L["CT_RaidAssist/Options/Window/Layout/WrapSlider"] = "Umbruch nach <value>"
L["CT_RaidAssist/Options/Window/Layout/WrapTooltipContent"] = "0.9:0.9:0.9#Beginnt eine neue Zeile oder Spalte wenn diese zu lang wird |cFFFFFF99Beispiel:|r - Obige Haken setzen, um alle acht Gruppen anzuzeigen - Obiges DropDown-Menü auf 'Schlachtzug in einer einzelnen Zeile anzeigen' einstellen - Diesen Schieberegler zum Umbruch nach 10 Spielern einstellen - Nun wird ein 40-Spieler Schlachtzug in 4 Zeilen mit je 10 Spielern angezeigt"
L["CT_RaidAssist/Options/Window/Layout/WrapTooltipHeader"] = "Große Zeilen/Spalten umbrechen:"
L["CT_RaidAssist/Options/Window/Size/BorderThicknessDropDown"] = "#Dünn#Mittel#Dick"
L["CT_RaidAssist/Options/Window/Size/BorderThicknessLabel"] = "Rahmenbreite:"
L["CT_RaidAssist/Options/WindowControls/AddButton"] = "Hinzufügen"
L["CT_RaidAssist/Options/WindowControls/AddTooltip"] = "Neues Fenster mit Standardeinstellungen hinzufügen."
L["CT_RaidAssist/Options/WindowControls/CloneButton"] = "Duplizieren"
L["CT_RaidAssist/Options/WindowControls/CloneTooltip"] = "Erstellt ein neues Fenster mit den Einstellungen des derzeit ausgewählten Fensters."
L["CT_RaidAssist/Options/WindowControls/DeleteButton"] = "Löschen"
L["CT_RaidAssist/Options/WindowControls/DeleteTooltip"] = "|cFFFFFF00Shift-Klick|r auf diese Schaltfläche um das derzeit gewählte Fenster zu entfernen."
L["CT_RaidAssist/Options/WindowControls/Heading"] = "Fenster"
L["CT_RaidAssist/Options/WindowControls/Line1"] = "Jedes Fenster hat sein eigenes Aussehen mit folgender Konfiguration."
L["CT_RaidAssist/Options/WindowControls/SelectionLabel"] = "Fenster wählen:"
L["CT_RaidAssist/Options/WindowControls/WindowAddedMessage"] = "Fenster %d hinzugefügt."
L["CT_RaidAssist/Options/WindowControls/WindowClonedMessage"] = "Fenster %d mit Einstellungen von Fenster %d hinzugefügt."
L["CT_RaidAssist/Options/WindowControls/WindowDeletedMessage"] = "Fenster %d entfernt."
L["CT_RaidAssist/Options/WindowControls/WindowSelectedMessage"] = "Fenster %d ausgewählt."


-----------------------------------------------
-- esES

elseif (GetLocale() == "esES" or GetLocale() == "esMX") then

L["CT_RaidAssist/AfterNotReadyFrame/MissedCheck"] = "Puede que hayas omitido un \"Estas Listo\" de la Raid."
L["CT_RaidAssist/AfterNotReadyFrame/WasAFK"] = "Estabas lejos del teclado, Has vuelto ya?"
L["CT_RaidAssist/AfterNotReadyFrame/WasNotReady"] = "Estás listo ya?"


-----------------------------------------------
-- zhCN
-- Credits to 萌丶汉丶纸

elseif (GetLocale() == "zhCN") then

L["CT_RaidAssist/AfterNotReadyFrame/MissedCheck"] = "你可能错过了就位确认!"
L["CT_RaidAssist/AfterNotReadyFrame/WasAFK"] = "你已经暂离, 现在要回来么?"
L["CT_RaidAssist/AfterNotReadyFrame/WasNotReady"] = "你准备好了么?"
L["CT_RaidAssist/PlayerFrame/TooltipFooter"] = "/ctra 来移动和设置"
L["CT_RaidAssist/PlayerFrame/TooltipItemsBroken"] = "%d%% 耐久, 有%d 破损装备 (截止 %d:%02d 分钟前)"
L["CT_RaidAssist/PlayerFrame/TooltipItemsNotBroken"] = "%d%% 耐久 (截止 %d:%02d 分钟前)"
L["CT_RaidAssist/WindowTitle"] = "%d窗"
L["CT_RaidAssist/Options/ClickCast/BuffSubheading"] = "脱战使用Buff:"
L["CT_RaidAssist/Options/ClickCast/DropDownOptions"] = "#右键#Shift-右键#Ctrl-右键#Alt-右键#无效 "
L["CT_RaidAssist/Options/ClickCast/Heading"] = "点击施法"
L["CT_RaidAssist/Options/ClickCast/RemoveDebuffSubheading"] = "移除debuff:"
L["CT_RaidAssist/Options/ClickCast/RezCombatSubheading"] = "战斗中复活:"
L["CT_RaidAssist/Options/ClickCast/RezNoCombatSubheading"] = "脱战复活:"
L["CT_RaidAssist/Options/ClickCast/TargetDropDown"] = "#所有其他点击#已禁用"
L["CT_RaidAssist/Options/ClickCast/TargetLabel"] = "目标"
L["CT_RaidAssist/Options/ClickCast/ToggleMenuLabel"] = "切换菜单"
L["CT_RaidAssist/Options/ClickCast/UtilitySubheading"] = "总体:"
L["CT_RaidAssist/Options/Frames/DisabledTip"] = "团队框架被禁用!"
L["CT_RaidAssist/Options/Frames/EnableDropDown"] = "#总是#团队#小队#从不"
L["CT_RaidAssist/Options/Frames/EnableLabel"] = "启用自定义框架:"
L["CT_RaidAssist/Options/Frames/Heading"] = "自定义团队框"
L["CT_RaidAssist/Options/Frames/HideBlizzardDefaultCheckButton"] = "隐藏暴雪的默认团队框架"
L["CT_RaidAssist/Options/Frames/HideBlizzardDefaultTooltip"] = [=[防止在出现自定义CTRA框架时出现默认团队框架.
如果禁用CTRA框架则无效.

注意: 其他一些插件也可能禁用默认框架.]=]
L["CT_RaidAssist/Options/Frames/ShareClassicHealPredictionCheckButton"] = "让CTRA与团队分享你的血量"
L["CT_RaidAssist/Options/Frames/ShareClassicHealPredictionTip"] = [=[使用诸如CTRA、Shadowed、Grid或IceHud之类的插件与团队分享你的损失血量.
注意：
-这个怀旧服的选项模仿了正式服功能
-关于你的血量信息将被传送给团队成员
-即使CTRA不支持共享，其他插件也可以启用共享
-这需要/reload才能禁用]=]
L["CT_RaidAssist/Options/ReadyCheckMonitor/ExtendReadyChecksCheckButton"] = "延长错过就位确认"
L["CT_RaidAssist/Options/ReadyCheckMonitor/ExtendReadyChecksTooltip"] = "提供在缺少/readycheck后通知返回的按钮"
L["CT_RaidAssist/Options/ReadyCheckMonitor/Heading"] = "就位确认功能"
L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilityLabel"] = "如果你装备的耐久度过低则提供警告"
L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilityMessage"] = [=[键入 /reload 为CTRA停止共享耐久度.
其他团队插件如DBM和oRA可能会重新激活此功能.]=]
L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilitySlider"] = "当装备低于<value>%时发出警告:关闭:50%"
L["CT_RaidAssist/Options/ReadyCheckMonitor/ShareDurabilityCheckButton"] = "让CTRA与团队分享你装备的耐久度"
L["CT_RaidAssist/Options/ReadyCheckMonitor/ShareDurabilityTooltip"] = [=[使用CTRA, DBM 或 oRA等插件与队友分享你装备的耐久度.

注意:
- 即使你选择退出CTRA，其他插件也可以启用共享功能
- 这需要 /reload才能生效]=]
L["CT_RaidAssist/Options/ReadyCheckMonitor/Tooltip"] = "这些设置适用于使用CT团队公会"
L["CT_RaidAssist/Options/Window/Appearance/EnablePowerBarCheckButton"] = "显示能量条?"
L["CT_RaidAssist/Options/Window/Appearance/EnablePowerBarTooltip"] = "在底部显示法力, 能量, 怒气等"
L["CT_RaidAssist/Options/Window/Appearance/EnableTargetFrameCheckButton"] = "在下方显示目标? "
L["CT_RaidAssist/Options/Window/Appearance/EnableTargetFrameTooltip"] = "在每个玩家下方添加一个带有其目标名称的框架 (通常用于坦克)"
L["CT_RaidAssist/Options/Window/Appearance/Heading"] = "显示"
L["CT_RaidAssist/Options/Window/Appearance/HealthBarAsBackgroundCheckButton"] = "以全尺寸背景显示血量"
L["CT_RaidAssist/Options/Window/Appearance/HealthBarAsBackgroundTooltip"] = "将整个背景填充为一大血条.  否则血条只是底部的一个小条"
L["CT_RaidAssist/Options/Window/Appearance/Line1"] = "你想要复古的CTRA感觉还是更现代的外观?"
L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsDropDown"] = "#是#仅自己血量#否"
L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsLabel"] = "显示预读血量:"
L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsTip"] = "延长血条(但不超过满血)以显示来自... -正式服，每个人-怀旧服，玩家与兼容的插件(CTRA, Shadowed, Grid, IceHUD等)"
L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsDropDown"] = "#是#仅自己护盾#否"
L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsLabel"] = "显示总吸收:"
L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsTip"] = "延长血条(但不能超过满血)以显示在进一步失去血量之前可以吸收多少伤害."
L["CT_RaidAssist/Options/Window/Appearance/TargetHealthCheckButton"] = "同时显示目标的血条"
L["CT_RaidAssist/Options/Window/Appearance/TargetHealthTip"] = "使用与玩家框架的血条相同的设置"
L["CT_RaidAssist/Options/Window/Appearance/TargetPowerCheckButton"] = "同时显示目标的能量条"
L["CT_RaidAssist/Options/Window/Appearance/TargetPowerTip"] = "使用与玩家框架的能量条相同的设置来显示目标的法力、怒气、能量等."
L["CT_RaidAssist/Options/Window/Auras/CombatLabel"] = "在战斗中显示:"
L["CT_RaidAssist/Options/Window/Auras/DropDown"] = "#我可以施放的团队Buff#我可以驱散的Debuffs#所有团队buffs#所有debuffs#我施放过的Group buffs#无"
L["CT_RaidAssist/Options/Window/Auras/Heading"] = "Buffs 和 Debuffs"
L["CT_RaidAssist/Options/Window/Auras/NoCombatLabel"] = "退出战斗显示:"
L["CT_RaidAssist/Options/Window/Auras/RemovableDebuffColorCheckButton"] = "为可移除debuffs添加颜色"
L["CT_RaidAssist/Options/Window/Auras/RemovableDebuffColorTip"] = "当你可以移除一个有害debuff时改变背景和边框."
L["CT_RaidAssist/Options/Window/Auras/ShowBossCheckButton"] = "在中间显示重要的BOSS光环"
L["CT_RaidAssist/Options/Window/Auras/ShowBossTip"] = [=[某些BOSS战会产生对战斗至关重要的buffs/debuffs.
这些将在中间显示较大以进行强调.]=]
L["CT_RaidAssist/Options/Window/Auras/ShowReverseCooldownCheckButton"] = "识别即将到期的光环"
L["CT_RaidAssist/Options/Window/Auras/ShowReverseCooldownTip"] = [=[在剩余时间少于50%的情况下为光环添加CD动画
注意: 由于游戏限制此功能仅限于怀旧服]=]
L["CT_RaidAssist/Options/Window/Color/BackgroundClassHeading"] = "职业背景颜色"
L["CT_RaidAssist/Options/Window/Color/BackgroundClassSlider"] = "背景 = <value>%"
L["CT_RaidAssist/Options/Window/Color/BackgroundClassTip"] = [=[按比例更改背景颜色.
但是使用与标准背景色相同的透明度.]=]
L["CT_RaidAssist/Options/Window/Color/BorderClassHeading"] = "职业边框颜色"
L["CT_RaidAssist/Options/Window/Color/BorderClassSlider"] = "边框 =<value>%"
L["CT_RaidAssist/Options/Window/Color/BorderClassTip"] = [=[按比例更改边框颜色.
但是使用与标准边框颜色相同的透明度.]=]
L["CT_RaidAssist/Options/Window/Color/Line1"] = "首先, 设置标准调色板:"
L["CT_RaidAssist/Options/Window/Color/Line2"] = "然后, 融入职业颜色:"
L["CT_RaidAssist/Options/Window/Groups/ClassHeader"] = "职业"
L["CT_RaidAssist/Options/Window/Groups/GroupHeader"] = "组"
L["CT_RaidAssist/Options/Window/Groups/GroupTooltipContent"] = [=[0.9:0.9:0.9#|cFFFFFF99在团队中: |r
- 不言而喻

|cFFFFFF99团队之外: |r
- Gp 1 是你和你的队伍]=]
L["CT_RaidAssist/Options/Window/Groups/GroupTooltipHeader"] = "组 1 到 8"
L["CT_RaidAssist/Options/Window/Groups/Header"] = "组和职业选择"
L["CT_RaidAssist/Options/Window/Groups/Line1"] = "此窗口应显示哪些组, 角色或职业?"
L["CT_RaidAssist/Options/Window/Groups/RoleHeader"] = "角色"
L["CT_RaidAssist/Options/Window/Groups/ShowDuplicatesOnceOnlyCheckButton"] = "避免重复"
L["CT_RaidAssist/Options/Window/Groups/ShowDuplicatesOnceOnlyTip"] = "如果玩家可以出现不止一次,只在第一次出现."
L["CT_RaidAssist/Options/Window/Groups/ShowGroupLabelsCheckButton"] = "显示群组标签"
L["CT_RaidAssist/Options/Window/Groups/ShowGroupLabelsTip"] = "在每列之前添加一个标签以指示其组/角色/职业. 当为每个组创建新列时此选项看起来最好。"
L["CT_RaidAssist/Options/Window/Layout/Heading"] = "布局"
L["CT_RaidAssist/Options/Window/Layout/OrientationDropdown"] = "#每个组的新 |cFFFFFF00列|r#每个组的新 |cFFFFFF00行|r #将团队合并到 |cFFFFFF00单个列|r (以换行为准)#将团队合并到 |cFFFFFF00单个行|r (以换行为准)"
L["CT_RaidAssist/Options/Window/Layout/OrientationLabel"] = "使用行或列?"
L["CT_RaidAssist/Options/Window/Layout/Tip"] = "使用这些设置团队框架将扩展/收缩成行和列"
L["CT_RaidAssist/Options/Window/Layout/WrapLabel"] = "行/列大小:"
L["CT_RaidAssist/Options/Window/Layout/WrapSlider"] = "在<value>后面换行"
L["CT_RaidAssist/Options/Window/Layout/WrapTooltipContent"] = [=[0.9:0.9:0.9#当新行或列太长时启动它

|cFFFFFF99比如:|r 
- 设置前面的复选框以显示所有八个组
- 将前面的下拉列表设置为 '将团队合并为一行'
- 将此滑块设置为在10名玩家之后换行
- 现在一个40人的团队出现了4排10人]=]
L["CT_RaidAssist/Options/Window/Layout/WrapTooltipHeader"] = "换行/换列大小:"
L["CT_RaidAssist/Options/Window/Size/BorderThicknessDropDown"] = "#薄#中#厚"
L["CT_RaidAssist/Options/Window/Size/BorderThicknessLabel"] = "边界厚度:"
L["CT_RaidAssist/Options/WindowControls/AddButton"] = "添加"
L["CT_RaidAssist/Options/WindowControls/AddTooltip"] = "使用默认设置添加新窗口."
L["CT_RaidAssist/Options/WindowControls/CloneButton"] = "克隆"
L["CT_RaidAssist/Options/WindowControls/CloneTooltip"] = "添加一个具有与当前所选窗口重复的设置的新窗口."
L["CT_RaidAssist/Options/WindowControls/DeleteButton"] = "删除"
L["CT_RaidAssist/Options/WindowControls/DeleteTooltip"] = "|cFFFFFF00Shift+左键|r 该按钮删除当前选择的窗口."
L["CT_RaidAssist/Options/WindowControls/Heading"] = "窗口"
L["CT_RaidAssist/Options/WindowControls/Line1"] = "每个窗口都有自己的外观, 可在下面配置."
L["CT_RaidAssist/Options/WindowControls/SelectionLabel"] = "选择窗口:"
L["CT_RaidAssist/Options/WindowControls/WindowAddedMessage"] = "窗口 %d 已添加."
L["CT_RaidAssist/Options/WindowControls/WindowClonedMessage"] = "窗口 %d 已添加, 从%d复制的设置."
L["CT_RaidAssist/Options/WindowControls/WindowDeletedMessage"] = "窗口 %d 已删除."
L["CT_RaidAssist/Options/WindowControls/WindowSelectedMessage"] = "窗口 %d 已选择."


end