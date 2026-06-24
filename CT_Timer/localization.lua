------------------------------------------------
--                  CT_Timer                  --
--                                            --
-- Provides a simple timer that counts up or  --
-- down using /timer slash commands.
--					      --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--					      --
-- Original credits to Cide and TS            --
-- Maintained by Resike from 2014 to 2017     --
-- and by Dahk Celes (DDCorkum) since 2019    --
------------------------------------------------

local module = select(2, ...);
module.text = module.text or { };

local L = module.text

-----------------------------------------------
-- enUS (Default) Unlocalized Strings 

L["CT_Timer/DRAG1"] = "Click to start/stop."
L["CT_Timer/DRAG2"] = "Right-click to reset."
L["CT_Timer/DRAG3"] = "Shift-click to drag."
L["CT_Timer/FINISHCOUNT"] = "The timer has finished counting down (counted from '%s')"
L["CT_Timer/HELP[1]"] = "Use the following commands to customize the timer:"
L["CT_Timer/HELP[10]"] = "/timer options - Shows the options dialog."
L["CT_Timer/HELP[2]"] = "/timer [show/hide] - Shows/hides the timer (still continues counting)."
L["CT_Timer/HELP[3]"] = "/timer secs [on/off] - Toggles showing seconds on/off."
L["CT_Timer/HELP[4]"] = "/timer start - Starts the timer from 00:00."
L["CT_Timer/HELP[5]"] = "/timer stop - Stops the timer."
L["CT_Timer/HELP[6]"] = "/timer reset - Resets the timer."
L["CT_Timer/HELP[7]"] = "/timer [minutes] - Starts the timer, counting down from [minutes] minutes."
L["CT_Timer/HELP[8]"] = "/timer [minutes]:[seconds] - Starts the timer, counting down from [minutes] minutes and [seconds] seconds."
L["CT_Timer/HELP[9]"] = "/timer bg [on/off] - Shows/hides the background of the timer frame."
L["CT_Timer/HOUR"] = "hour"
L["CT_Timer/HOURS"] = "hours"
L["CT_Timer/MIN"] = "minute"
L["CT_Timer/MINS"] = "minutes"
L["CT_Timer/MODNAME"] = "Timer Mod"
L["CT_Timer/RESET"] = "Reset"
L["CT_Timer/SECS_MODNAME"] = "Timer Seconds"
L["CT_Timer/SECS_SUBNAME"] = "Show Seconds"
L["CT_Timer/SECS_TOOLTIP"] = "Toggles showing seconds for the timer mod."
L["CT_Timer/SHOW_OFF"] = "The timer is now hidden"
L["CT_Timer/SHOW_ON"] = "The timer is now shown"
L["CT_Timer/SHOWSECS_OFF"] = "The timer is no longer showing seconds."
L["CT_Timer/SHOWSECS_ON"] = "The timer is now showing seconds."
L["CT_Timer/SUBNAME"] = "Open Options"
L["CT_Timer/TOOLTIP"] = "Displays the timer options dialog."



--------------------------------------------
-- frFR
-- Originally credited to Sasmira (c. 2005)

if ( GetLocale() == "frFR" ) then

L["CT_Timer/DRAG1"] = "ON/OFF sur Clic Gauche."
L["CT_Timer/DRAG2"] = "La déplacer sur Clic Droit."
L["CT_Timer/FINISHCOUNT"] = "La minuterie du compte à rebours est finie (à compté de '<time>')"
L["CT_Timer/HELP[1]"] = "Utiliser les lignes de commandes pour configurer la minuterie:"
L["CT_Timer/HELP[2]"] = "/timer [show/hide] - Afficher/Cacher la minuterie."
L["CT_Timer/HELP[3]"] = "/timer secs [on/off] - ON/OFF l'affichage en secondes."
L["CT_Timer/HOUR"] = "heure"
L["CT_Timer/HOURS"] = "heures"
L["CT_Timer/MIN"] = "minute"
L["CT_Timer/MINS"] = "minutes"
L["CT_Timer/MODNAME"] = "Minuterie"
L["CT_Timer/RESET"] = "Remise à zéro"
L["CT_Timer/SECS_MODNAME"] = "Minuterie en Secondes"
L["CT_Timer/SECS_SUBNAME"] = "Voir les Secondes"
L["CT_Timer/SECS_TOOLTIP"] = "Affichage de la Minuterie en secondes."
L["CT_Timer/SHOW_OFF"] = "La minuterie est maintenant cachée"
L["CT_Timer/SHOW_ON"] = "La minuterie est maintenant affichée"
L["CT_Timer/SHOWSECS_OFF"] = "L'affichage de la minuterie n'est plus en secondes."
L["CT_Timer/SHOWSECS_ON"] = "L'affichage de la minuterie est maintenant en secondes."
L["CT_Timer/SUBNAME"] = "ON/OFF"
L["CT_Timer/TOOLTIP"] = "Affichage de la Minuterie."


--------------------------------------------
-- deDE
-- Originally credited to Hjörvarör

elseif ( GetLocale() == "deDE" ) then

L["CT_Timer/DRAG1"] = "Klick um zu Starten/Stoppen."
L["CT_Timer/DRAG2"] = "Rechtsklick zum Verschieben."
L["CT_Timer/FINISHCOUNT"] = "Der Timer hat das Herunterzählen abgeschlossen. (gezählt von '%s')"
L["CT_Timer/HELP[1]"] = "Benutze die folgenden Befehle um den Timer anzupassen:"
L["CT_Timer/HELP[2]"] = "/timer [show/hide] - Anzeigen/Verstecken des Timer (zählt nach wie vor weiter)."
L["CT_Timer/HELP[3]"] = "/timer secs [on/off] - Schaltet das Anzeigen von Sekunden ein/aus."
L["CT_Timer/HOUR"] = "Stunde"
L["CT_Timer/HOURS"] = "Stunden"
L["CT_Timer/MIN"] = "Minute"
L["CT_Timer/MINS"] = "Minuten"
L["CT_Timer/MODNAME"] = "Timer Mod"
L["CT_Timer/RESET"] = "Reset"
L["CT_Timer/SECS_MODNAME"] = "Timer Sekunden"
L["CT_Timer/SECS_SUBNAME"] = "Zeigt Sekunden"
L["CT_Timer/SECS_TOOLTIP"] = "Schaltet das Anzeigen von Sekunden im Timer Mod um."
L["CT_Timer/SHOW_OFF"] = "Der Timer wird nun versteckt."
L["CT_Timer/SHOW_ON"] = "Der Timer wird nun angezeigt."
L["CT_Timer/SHOWSECS_OFF"] = "Der Timer zeigt nicht länger Sekunden an."
L["CT_Timer/SHOWSECS_ON"] = "Der Timer zeigt nun Sekunden an."
L["CT_Timer/SUBNAME"] = "Ein/Aus Schalter"
L["CT_Timer/TOOLTIP"] = "Schaltet den Timer Mod ein/aus."

end

-----------------------------------------------
-- Construct a table using localized strings

L["CT_Timer/HELP"] =
{
	L["CT_Timer/HELP[1]"],
	L["CT_Timer/HELP[2]"],
	L["CT_Timer/HELP[3]"],
	L["CT_Timer/HELP[4]"],
	L["CT_Timer/HELP[5]"],
	L["CT_Timer/HELP[6]"],
	L["CT_Timer/HELP[7]"],
	L["CT_Timer/HELP[8]"],
	L["CT_Timer/HELP[9]"],
	L["CT_Timer/HELP[10]"],
}