------------------------------------------------
--                 CT_Library                 --
--                                            --
-- A shared library for all CTMod addons to   --
-- simplify simple, yet time consuming tasks  --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--                                            --
-- Original credits to Cide and TS (Vanilla)  --
-- Maintained by Resike from 2014 to 2017     --
-- Maintained by Dahk Celes since 2018        --
--                                            --
-- This file localizes the CTMod window and   --
-- submodules installed by CT_Library         --
------------------------------------------------


-- Please see CurseForge.com/Projects/CTMod/Localization to contribute additional translations

local module = select(2,...)
module.text = module.text or { }
local L = module.text

--  Gracefully handle errors
local metatable = getmetatable(L) or {}
metatable.__index = function(table, missingKey)
	return "[Not Found: " .. gsub(missingKey, "CT_Library/", "") .. "]";
end
setmetatable(L, metatable);


-----------------------------------------------
-- enUS (Default) Unlocalized Strings

L["CT_Library/ControlPanelCannotOpen"] = "Cannot open the CT options while in combat"
L["CT_Library/Frames/ResetOptionsTemplate/Button"] = "Reset Options"
L["CT_Library/Frames/ResetOptionsTemplate/Heading"] = "Reset Options"
L["CT_Library/Frames/ResetOptionsTemplate/Line1"] = "Resets options to defaults and reloads the UI."
L["CT_Library/Frames/ResetOptionsTemplate/ResetAllCheckbox"] = "Reset options for all of your characters"
L["CT_Library/Introduction"] = [=[Thank you for using CTMod!

You can open this window with /ct or /ctmod

Click below to open options for each module]=]
L["CT_Library/ModListing"] = "Mod Listing:"
L["CT_Library/Tooltip/DRAG"] = [=[Left click to drag
Right click to reset]=]
L["CT_Library/Tooltip/RESIZE"] = [=[Left click to resize
Right click to reset]=]
L["CT_Library/Help/About/Credits"] = [=[CTMod originated in Vanilla by Cide and TS
Resike and Dahk joined the team in '14 and '17]=]
L["CT_Library/Help/About/Heading"] = "About CTMod"
L["CT_Library/Help/About/Updates"] = "Updates are available at:"
L["CT_Library/Help/Heading"] = "Help"
L["CT_Library/Help/WhatIs/Heading"] = "What is CTMod?"
L["CT_Library/Help/WhatIs/Line1"] = "CTMod contains several modules:"
L["CT_Library/Help/WhatIs/NotInstalled"] = "not installed"
L["CT_Library/SettingsImport/Actions/DeleteOtherNote"] = "Reset that profile to default settings"
L["CT_Library/SettingsImport/Actions/DeleteSelfNote"] = "Reset the current profile and /reload"
L["CT_Library/SettingsImport/Actions/ExportNote"] = "Manual copy/paste to another account"
L["CT_Library/SettingsImport/Actions/Heading"] = "Select Action"
L["CT_Library/SettingsImport/Actions/ImportNote"] = "Overwrite the current profile and /reload"
L["CT_Library/SettingsImport/AddOns/Heading"] = "Select AddOns"
L["CT_Library/SettingsImport/Clipboard/AcceptTip"] = "Next step: select which AddOns to import"
L["CT_Library/SettingsImport/Clipboard/AddOnMissingWarning"] = "Warning: the string includes a missing or inactive AddOn"
L["CT_Library/SettingsImport/Clipboard/AddOnVersionWarning"] = "Warning: the string was made using a different AddOn version"
L["CT_Library/SettingsImport/Clipboard/ChecksumAlert"] = "The string appears incomplete or corrupted"
L["CT_Library/SettingsImport/Clipboard/FailureAlert"] = "Parsing the string caused an unknown error"
L["CT_Library/SettingsImport/Clipboard/GameVersionWarning"] = "Warning: the string was made using a different game version"
L["CT_Library/SettingsImport/Clipboard/NoAddOnsAlert"] = "No matching addons were found in the string"
L["CT_Library/SettingsImport/Clipboard/StringValidMessage"] = "Validation passed: the string appears usable"
L["CT_Library/SettingsImport/Heading"] = "Settings Import"
L["CT_Library/SettingsImport/NoAddonsSelected"] = "No addons are selected."
L["CT_Library/SettingsImport/Profiles/ExternalButton"] = "Use import string"
L["CT_Library/SettingsImport/Profiles/ExternalButtonTip"] = [=[To transfer settings from another account using a text string:
(1) Log in to the original character
(2) Choose that character from the menu
(3) Choose the export option
(4) Copy the text string
(5) Return to this character
(6) Start the import and paste the string]=]
L["CT_Library/SettingsImport/Profiles/ExternalSubHeading"] = "Option 2 - Import from another account"
L["CT_Library/SettingsImport/Profiles/Heading"] = "Select a profile"
L["CT_Library/SettingsImport/Profiles/InternalCharacterLabel"] = "Character:"
L["CT_Library/SettingsImport/Profiles/InternalServerLabel"] = "Server:"
L["CT_Library/SettingsImport/Profiles/InternalSubHeading"] = "Option 1 - My characters"


-----------------------------------------------
-- frFR
-- Credits: ddc, FTB_Exper

if (GetLocale() == "frFR") then

L["CT_Library/ControlPanelCannotOpen"] = "Il faut finir le combat avant d'acceder les options de CTMod"
L["CT_Library/Frames/ResetOptionsTemplate/Button"] = "Réinitialiser"
L["CT_Library/Frames/ResetOptionsTemplate/Heading"] = "Réinitialiser les options"
L["CT_Library/Frames/ResetOptionsTemplate/Line1"] = "Note: Ce bouton réinitialise les options aux valeurs par défaut, et il recharge l'interface"
L["CT_Library/Frames/ResetOptionsTemplate/ResetAllCheckbox"] = "Réinitialiser les options pour tous les personnages"
L["CT_Library/Introduction"] = [=[Merci pour utiliser CTMod!

Vous pouvez ouvrir cette fênetre avec /ct

Cliquez ci-dessous pour accéder aux modules]=]
L["CT_Library/ModListing"] = "Les modules :"
L["CT_Library/Tooltip/DRAG"] = [=[Clic gauche pour déplacer
Clic droit pour réinitialiser]=]
L["CT_Library/Tooltip/RESIZE"] = [=[Clic gauche pour redimensionner
Clic droit pour réinitialiser]=]
L["CT_Library/Help/About/Credits"] = "CTMod continue dupuis « Vanilla » par Cide et TS, 2014 par Resike, et 2017 par Dahk"
L["CT_Library/Help/About/Heading"] = "À propos de nous"
L["CT_Library/Help/About/Updates"] = "Pour mettre à jour :"
L["CT_Library/Help/Heading"] = "L'aide"
L["CT_Library/Help/WhatIs/Heading"] = "Qu'est-ce CTMod?"
L["CT_Library/Help/WhatIs/Line1"] = "CTMod contient des modules :"
L["CT_Library/Help/WhatIs/NotInstalled"] = "pas installée"
L["CT_Library/SettingsImport/Actions/DeleteOtherNote"] = "Remettre un profil aux options par défaut"
L["CT_Library/SettingsImport/Actions/DeleteSelfNote"] = "Remettre le profil actuel aux options par défaut"
L["CT_Library/SettingsImport/Actions/ExportNote"] = "Copier et coller manuellement à un autre compte"
L["CT_Library/SettingsImport/Actions/Heading"] = "Choisir l'action"
L["CT_Library/SettingsImport/Actions/ImportNote"] = "Remplacer le profile actuel et recharger"
L["CT_Library/SettingsImport/AddOns/Heading"] = "Choisir les addons"
L["CT_Library/SettingsImport/Clipboard/AcceptTip"] = "L'étape prochaine : choisir les addons pour importer"
L["CT_Library/SettingsImport/Clipboard/AddOnMissingWarning"] = "Avertissement : il y a des options pour un addon manquant ou désactivé"
L["CT_Library/SettingsImport/Clipboard/AddOnVersionWarning"] = "Avertissement : le texte vient d'une autre version de CTMod"
L["CT_Library/SettingsImport/Clipboard/ChecksumAlert"] = "Le texte apparaît incomplet ou corrompu."
L["CT_Library/SettingsImport/Clipboard/FailureAlert"] = "Il y avait un erreur inconnu en analysant le texte"
L["CT_Library/SettingsImport/Clipboard/GameVersionWarning"] = "Avertissement : le texte vient d'une autre version de jeu"
L["CT_Library/SettingsImport/Clipboard/NoAddOnsAlert"] = "Aucun addon actuel ne correspond au texte"
L["CT_Library/SettingsImport/Clipboard/StringValidMessage"] = "La validation réussie : prêt à importer"
L["CT_Library/SettingsImport/Heading"] = "Importer les configurations"
L["CT_Library/SettingsImport/NoAddonsSelected"] = "Aucun addon n'est sélectionné."
L["CT_Library/SettingsImport/Profiles/ExternalButton"] = "Coller un texte"
L["CT_Library/SettingsImport/Profiles/ExternalButtonTip"] = [=[Pour transférer les options d'un autre compte en copiant une chaîne de texte :
(1) Connectez-vous au personnage d'origine
(2) Choisissez le personnage-là dans le menu
(3) Choisissez l'option d'exporter
(4) Copier la chaîne de texte
(5) Revenez au personnage-ci
(6) Commencez l'import et collez la chaîne de texte]=]
L["CT_Library/SettingsImport/Profiles/ExternalSubHeading"] = "L'option 2 - importer d'un autre compte :"
L["CT_Library/SettingsImport/Profiles/Heading"] = "Choisir un profil"
L["CT_Library/SettingsImport/Profiles/InternalCharacterLabel"] = "Le personnage :"
L["CT_Library/SettingsImport/Profiles/InternalServerLabel"] = "Le serveur :"
L["CT_Library/SettingsImport/Profiles/InternalSubHeading"] = "L'option 1 - mes personnages :"


-----------------------------------------------
-- deDE
-- Credits: dynaletik

elseif (GetLocale() == "deDE") then

L["CT_Library/ControlPanelCannotOpen"] = "CT Optionen können nicht im Kampf geöffnet werden."
L["CT_Library/Frames/ResetOptionsTemplate/Button"] = "Zurücksetzen"
L["CT_Library/Frames/ResetOptionsTemplate/Heading"] = "Optionen zurücksetzen"
L["CT_Library/Frames/ResetOptionsTemplate/Line1"] = "Setzt Optionen auf Standardwerte zurück und lädt das Interface neu."
L["CT_Library/Frames/ResetOptionsTemplate/ResetAllCheckbox"] = "Optionen für alle Charaktere zurücksetzen"
L["CT_Library/Introduction"] = [=[Danke für die Nutzung von CTMod!

Dieses Fenster kann mit /ct oder /ctmod geöffnet werden. Unten klicken um Optionen des jeweiligen Moduls anzuzeigen]=]
L["CT_Library/ModListing"] = "Liste der Module:"
L["CT_Library/Tooltip/DRAG"] = [=[Linksklick zum Verschieben
Rechtsklick zum Zurücksetzen]=]
L["CT_Library/Tooltip/RESIZE"] = [=[Linksklick zum Anpassen
Rechtsklick zum Zurücksetzen]=]
L["CT_Library/Help/About/Credits"] = [=[CTMod ist von Cide und TS seit Vanille, 
Resike seit 2014 und Dahk seit 2017]=]
L["CT_Library/Help/About/Heading"] = "Über CTMod"
L["CT_Library/Help/About/Updates"] = "Updates sind verfügbar unter:"
L["CT_Library/Help/Heading"] = "Hilfe"
L["CT_Library/Help/WhatIs/Heading"] = "Was ist CTMod?"
L["CT_Library/Help/WhatIs/Line1"] = "CTMod beinhaltet verschiedene Module:"
L["CT_Library/Help/WhatIs/NotInstalled"] = "nicht installiert"
L["CT_Library/SettingsImport/Actions/DeleteOtherNote"] = "Dieses Profil auf Standardeinstellungen zurücksetzen"
L["CT_Library/SettingsImport/Actions/DeleteSelfNote"] = "Aktuelles Profil zurücksetzen und /reload"
L["CT_Library/SettingsImport/Actions/ExportNote"] = "Manuelles Kopieren/Einfügen zu anderem Account"
L["CT_Library/SettingsImport/Actions/Heading"] = "Aktion auswählen"
L["CT_Library/SettingsImport/Actions/ImportNote"] = "Aktuelles Profil überschreiben und /reload"
L["CT_Library/SettingsImport/AddOns/Heading"] = "AddOns auswählen"
L["CT_Library/SettingsImport/Clipboard/AcceptTip"] = "Nächster Schritt: Addons zum Importieren wählen"
L["CT_Library/SettingsImport/Clipboard/AddOnMissingWarning"] = "Warnung: Der String enthält fehlende oder inaktive Addons"
L["CT_Library/SettingsImport/Clipboard/AddOnVersionWarning"] = "Warnung: Der String wurde mit einer anderen Addon Version erstellt"
L["CT_Library/SettingsImport/Clipboard/ChecksumAlert"] = "Der String scheint unvollständig oder defekt zu sein"
L["CT_Library/SettingsImport/Clipboard/FailureAlert"] = "Übertragung des Strings hat einen unbekannten Fehler verursacht"
L["CT_Library/SettingsImport/Clipboard/GameVersionWarning"] = "Warnung: Der String wurde mit einer anderen Spielversion erstellt"
L["CT_Library/SettingsImport/Clipboard/NoAddOnsAlert"] = "Es wurden keine passenden Addons im String gefunden"
L["CT_Library/SettingsImport/Clipboard/StringValidMessage"] = "Überprüfung abgeschlossen: Der String scheint nutzbar zu sein"
L["CT_Library/SettingsImport/Heading"] = "Einstellungen importieren"
L["CT_Library/SettingsImport/NoAddonsSelected"] = "Keine Module ausgewählt."
L["CT_Library/SettingsImport/Profiles/ExternalButton"] = "Importstring verwenden"
L["CT_Library/SettingsImport/Profiles/ExternalButtonTip"] = [=[Um Einstellungen von einem anderen Account mit Hilfe eines Textstrings zu kopieren: 
(1) In den Original Charakter einloggen 
(2) Den Charakter im Menü auswählen 
(3) Export Option auswählen 
(4) Den Textstring kopieren 
(5) Zu diesem Charakter zurückkehren 
(6) Import starten und String einfügen]=]
L["CT_Library/SettingsImport/Profiles/ExternalSubHeading"] = "Option 2 - Von anderem Account importieren"
L["CT_Library/SettingsImport/Profiles/Heading"] = "Ein Profil auswählen"
L["CT_Library/SettingsImport/Profiles/InternalCharacterLabel"] = "Charakter:"
L["CT_Library/SettingsImport/Profiles/InternalServerLabel"] = "Server:"
L["CT_Library/SettingsImport/Profiles/InternalSubHeading"] = "Option 1 - Meine Charaktere"


-----------------------------------------------
-- esES Localizations

elseif (GetLocale() == "esES" or GetLocale() == "esMX") then

L["CT_Library/Help/About/Credits"] = [=[CTMod originado en Vanilla by Cide y TS
Resike y Dahk unieron en '14 y '17]=]
L["CT_Library/Help/About/Heading"] = "Acerca CTMod"
L["CT_Library/Help/About/Updates"] = "Actualización en:"


-----------------------------------------------
-- ruRU Localizations
-- Credits: M1Dnait, imposeren

elseif (GetLocale() == "ruRU") then

L["CT_Library/ControlPanelCannotOpen"] = "Нельзя открыть параметры CT во время боя"
L["CT_Library/Help/About/Credits"] = [=[CTMod создан в Ваниле авторами Cide и TS.
Resike и Dahk присоединившимся к команде в 14 и 17 году]=]
L["CT_Library/Help/About/Updates"] = "Обновление доступно тут:"
L["CT_Library/SettingsImport/Heading"] = "Импорт настроек"


-----------------------------------------------
-- zhCN Localizations
-- Credits: 萌丶汉丶纸

elseif (GetLocale() == "zhCN") then

L["CT_Library/ControlPanelCannotOpen"] = "在战斗中无法打开CT选项"
L["CT_Library/Frames/ResetOptionsTemplate/Button"] = "重置设置"
L["CT_Library/Frames/ResetOptionsTemplate/Heading"] = "重置设置"
L["CT_Library/Frames/ResetOptionsTemplate/Line1"] = "这会将选项重置为默认值然后重新加载UI."
L["CT_Library/Frames/ResetOptionsTemplate/ResetAllCheckbox"] = "重置所有角色的选项"
L["CT_Library/Introduction"] = "感谢使用CTMod!你可以使用/ct or /ctmod开启窗口.单击下面打开每个模块的选项"
L["CT_Library/ModListing"] = "模块列表:"
L["CT_Library/Tooltip/DRAG"] = [=[左击拖动
右击重置]=]
L["CT_Library/Tooltip/RESIZE"] = [=[左击可调整大小
右击重置]=]
L["CT_Library/Help/About/Credits"] = [=[CTMod起源于Cide 和 TS在香草时代
Resike 和 Dahk在'14 和 '17加入其中]=]
L["CT_Library/Help/About/Heading"] = "关于CTMod"
L["CT_Library/Help/About/Updates"] = "更新可在:"
L["CT_Library/Help/Heading"] = "帮助"
L["CT_Library/Help/WhatIs/Heading"] = "什么是CTMod?"
L["CT_Library/Help/WhatIs/Line1"] = "CTMod包含几个模块:"
L["CT_Library/Help/WhatIs/NotInstalled"] = "未安装"
L["CT_Library/SettingsImport/Actions/DeleteOtherNote"] = "将该配置重置为默认设置"
L["CT_Library/SettingsImport/Actions/DeleteSelfNote"] = "重置当前配置并/reload"
L["CT_Library/SettingsImport/Actions/ExportNote"] = "手动复制/粘贴到另一个战网"
L["CT_Library/SettingsImport/Actions/Heading"] = "选择操作"
L["CT_Library/SettingsImport/Actions/ImportNote"] = "覆盖当前的配置并/reload"
L["CT_Library/SettingsImport/AddOns/Heading"] = "选择插件"
L["CT_Library/SettingsImport/Clipboard/AcceptTip"] = "下一步:  选择要导入的插件"
L["CT_Library/SettingsImport/Clipboard/AddOnMissingWarning"] = "警告:  字符串包含一个缺失或未激活的插件"
L["CT_Library/SettingsImport/Clipboard/AddOnVersionWarning"] = "警告:  字符串是用不同的插件版本制作的"
L["CT_Library/SettingsImport/Clipboard/ChecksumAlert"] = "字符串不完整或损坏"
L["CT_Library/SettingsImport/Clipboard/FailureAlert"] = "解析字符串时出现未知错误"
L["CT_Library/SettingsImport/Clipboard/GameVersionWarning"] = "警告:  字符串是用不同的游戏版本制作的"
L["CT_Library/SettingsImport/Clipboard/NoAddOnsAlert"] = "在字符串中没有找到匹配的插件"
L["CT_Library/SettingsImport/Clipboard/StringValidMessage"] = "验证通过:  字符串显示可用"
L["CT_Library/SettingsImport/Heading"] = "设置导入"
L["CT_Library/SettingsImport/NoAddonsSelected"] = "未选择任何加载项."
L["CT_Library/SettingsImport/Profiles/ExternalButton"] = "使用导入字符串"
L["CT_Library/SettingsImport/Profiles/ExternalButtonTip"] = [=[使用文本从另一个账户或怀旧服/正式服复制设置, 要生成一个字符串。
(1) 登录到你想导出的角色 
(2) 在下拉菜单中选择你自己的配置文件 
(3) 现在插件列表下方会出现一个导出按钮]=]
L["CT_Library/SettingsImport/Profiles/ExternalSubHeading"] = "选项2 - 从另一个战网导入"
L["CT_Library/SettingsImport/Profiles/Heading"] = "选择一个配置"
L["CT_Library/SettingsImport/Profiles/InternalCharacterLabel"] = "角色:"
L["CT_Library/SettingsImport/Profiles/InternalServerLabel"] = "服务器:"
L["CT_Library/SettingsImport/Profiles/InternalSubHeading"] = "选项1 - 我的角色"


-----------------------------------------------
-- ptBR Localizations
-- Credits: BansheeLyris, pedrayy

elseif (GetLocale() == "ptBR") then

L["CT_Library/Help/About/Credits"] = "CTMod originou-se no Vanilla por Cide e TS Resike, e Dahk juntou-se à equipe em 2014 e 2017"
L["CT_Library/Help/About/Heading"] = "Sobre CTMod"
L["CT_Library/Help/About/Updates"] = "Atualizações disponíveis em: "
L["CT_Library/SettingsImport/Actions/DeleteOtherNote"] = "Redefinir este perfil para as configurações padrão"
L["CT_Library/SettingsImport/Actions/DeleteSelfNote"] = "Redefinir o perfil atual e recarregar a interface"
L["CT_Library/SettingsImport/Actions/ExportNote"] = "Manualmente copiar/colar para outra conta"
L["CT_Library/SettingsImport/Actions/Heading"] = "Selecionar ação"
L["CT_Library/SettingsImport/Actions/ImportNote"] = "Sobrescrever o perfil atual e recarregar a interface"
L["CT_Library/SettingsImport/AddOns/Heading"] = "Selecionar AddOns"


end