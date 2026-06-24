------------------------------------------------
--               CT_BottomBar                 --
--                                            --
-- Breaks up the main menu bar into pieces,   --
-- allowing you to hide and move the pieces   --
-- independently of each other.               --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--                                            --
-- Original credits to Cide and TS (Vanilla)  --
-- Maintained by Resike from 2014 to 2017     --
-- Maintained by Dahk Celes since 2018        --
--                                            --
-- This file localizes the CT_BB options      --
------------------------------------------------


-- Please see CurseForge.com/Projects/CTMod/Localization to contribute additional translations

local module = _G["CT_BottomBar"]
module.text = module.text or { }
local L = module.text


-----------------------------------------------
-- enUS (Default) Unlocalized Strings

L["CT_BottomBar/Options/ActionBarPage"] = "Arrows Page-Up/Down"
L["CT_BottomBar/Options/AddonList/CommonBarsSubheading"] = "Common Button Bars"
L["CT_BottomBar/Options/AddonList/InformationalBarsSubheading"] = "Informational Display Bars"
L["CT_BottomBar/Options/AddonList/SpecialBarsSubheading"] = "Special Button Bars"
L["CT_BottomBar/Options/AddonList/StatusTrackingBarsSubheading"] = "Status Tracking Bars"
L["CT_BottomBar/Options/BagsBar"] = "Bags Bar"
L["CT_BottomBar/Options/ClassBar"] = "Class Bar"
L["CT_BottomBar/Options/ClassicKeyRingButton"] = "Key Ring Button"
L["CT_BottomBar/Options/ClassicPerformanceBar"] = "Performance Bar"
L["CT_BottomBar/Options/ExpBar"] = "Experience Bar"
L["CT_BottomBar/Options/FlightBar"] = "Stop Flying Button"
L["CT_BottomBar/Options/FPSBar"] = "FPS Indicator"
L["CT_BottomBar/Options/General/BackgroundTextures/Heading"] = "Background Textures"
L["CT_BottomBar/Options/General/BackgroundTextures/HideActionBarCheckButton"] = "Hide the action bar textures"
L["CT_BottomBar/Options/General/BackgroundTextures/HideGryphonsCheckButton"] = "Hide the gryphons/lions"
L["CT_BottomBar/Options/General/BackgroundTextures/HideMenuAndBagsCheckButton"] = "Hide the menu and bags textures"
L["CT_BottomBar/Options/General/BackgroundTextures/Line1"] = "Control the grey backgrounds behind the default UI bar positions"
L["CT_BottomBar/Options/General/BackgroundTextures/ShowLionsCheckButton"] = "Show lions instead of gryphons"
L["CT_BottomBar/Options/General/Heading"] = "Important General Options"
L["CT_BottomBar/Options/MenuBar"] = "Menu Bar"
L["CT_BottomBar/Options/MovableBars/Activate"] = "Activate"
L["CT_BottomBar/Options/MovableBars/Hide"] = "Hide"
L["CT_BottomBar/Options/MultiCastBar"] = "Totem Bar"
L["CT_BottomBar/Options/PetBar"] = "Pet Bar"
L["CT_BottomBar/Options/RepBar"] = "Reputation Bar"
L["CT_BottomBar/Options/StanceBar"] = "Stance Bar"
L["CT_BottomBar/Options/StatusBar"] = "Status Bar (XP & Rep)"
L["CT_BottomBar/Options/TalkingHead"] = "Quest Dialogue"
L["CT_BottomBar/Options/ZoneAbilityBar"] = "Zone Bar"


-----------------------------------------------
-- frFR (credit: ddc)

if (GetLocale() == "frFR") then

L["CT_BottomBar/Options/ActionBarPage"] = "Les flèches haut/bas"
L["CT_BottomBar/Options/AddonList/CommonBarsSubheading"] = "Les barres d'action habituelles"
L["CT_BottomBar/Options/AddonList/InformationalBarsSubheading"] = "Les barres de renseignements"
L["CT_BottomBar/Options/AddonList/SpecialBarsSubheading"] = "Les barres d'action spéciales"
L["CT_BottomBar/Options/AddonList/StatusTrackingBarsSubheading"] = "Les barres de complétion"
L["CT_BottomBar/Options/BagsBar"] = "Les sacs"
L["CT_BottomBar/Options/ClassBar"] = "La classe"
L["CT_BottomBar/Options/ClassicKeyRingButton"] = "Le trousseau de clés"
L["CT_BottomBar/Options/ClassicPerformanceBar"] = "La performance"
L["CT_BottomBar/Options/ExpBar"] = "L'expérience"
L["CT_BottomBar/Options/FlightBar"] = "Le bouton d'arrêt-vol"
L["CT_BottomBar/Options/FPSBar"] = "Les images/seconde"
L["CT_BottomBar/Options/MenuBar"] = "Le menu"
L["CT_BottomBar/Options/MovableBars/Activate"] = "Activer"
L["CT_BottomBar/Options/MovableBars/Hide"] = "Cacher"
L["CT_BottomBar/Options/PetBar"] = "L'animal de compangnie"
L["CT_BottomBar/Options/RepBar"] = "La réputation"
L["CT_BottomBar/Options/StanceBar"] = "La position"
L["CT_BottomBar/Options/StatusBar"] = "Les statuts (PX & rép)"
L["CT_BottomBar/Options/TalkingHead"] = "Le discours de quête"


-----------------------------------------------
-- deDE (credit: 00jones00)

elseif (GetLocale() == "deDE") then

L["CT_BottomBar/Options/ActionBarPage"] = "Bild-Auf/Ab Pfeiltasten"
L["CT_BottomBar/Options/AddonList/CommonBarsSubheading"] = "Gemeinsame Buttonleisten"
L["CT_BottomBar/Options/AddonList/InformationalBarsSubheading"] = "Informationsanzeigeleiste"
L["CT_BottomBar/Options/AddonList/SpecialBarsSubheading"] = "Spezialbuttons Leiste"
L["CT_BottomBar/Options/AddonList/StatusTrackingBarsSubheading"] = "Statusverfolgungsleiste"
L["CT_BottomBar/Options/BagsBar"] = "Taschen Leiste"
L["CT_BottomBar/Options/ClassBar"] = "Klassen Leiste"
L["CT_BottomBar/Options/ClassicKeyRingButton"] = "Schlüsselbund Button"
L["CT_BottomBar/Options/ClassicPerformanceBar"] = "Leistungsleiste"
L["CT_BottomBar/Options/ExpBar"] = "Erfahrungsleiste"
L["CT_BottomBar/Options/FlightBar"] = "Flug unterbrechen Button"
L["CT_BottomBar/Options/FPSBar"] = "FPS Anzeige"
L["CT_BottomBar/Options/General/BackgroundTextures/Heading"] = "Hintergrundtexturen"
L["CT_BottomBar/Options/General/BackgroundTextures/HideActionBarCheckButton"] = "Aktionsleisten Texturen ausblenden"
L["CT_BottomBar/Options/General/BackgroundTextures/HideGryphonsCheckButton"] = "Greifen/Löwen ausblenden"
L["CT_BottomBar/Options/General/BackgroundTextures/HideMenuAndBagsCheckButton"] = "Menü- und Taschentexturen ausblenden"
L["CT_BottomBar/Options/General/BackgroundTextures/Line1"] = "Kontrolliert die grauen Hintergründe hinter den Standard UI Leistenpositionen"
L["CT_BottomBar/Options/General/BackgroundTextures/ShowLionsCheckButton"] = "Löwen statt Greifen anzeigen"
L["CT_BottomBar/Options/General/Heading"] = "Wichtige allgemeine Optionen"
L["CT_BottomBar/Options/MenuBar"] = "Menüleiste"
L["CT_BottomBar/Options/MovableBars/Activate"] = "Aktivieren"
L["CT_BottomBar/Options/MovableBars/Hide"] = "Verstecken"
L["CT_BottomBar/Options/PetBar"] = "Begleiterleiste"
L["CT_BottomBar/Options/RepBar"] = "Rufleiste"
L["CT_BottomBar/Options/StanceBar"] = "Haltungsleiste"
L["CT_BottomBar/Options/StatusBar"] = "Statusleiste (EP & Ruf)"
L["CT_BottomBar/Options/TalkingHead"] = "Questdialoge"


-----------------------------------------------
-- zhCN (credit: 萌丶汉丶纸)

elseif GetLocale() == "zhCN" then

L["CT_BottomBar/Options/ActionBarPage"] = "箭头上/下翻页"
L["CT_BottomBar/Options/AddonList/CommonBarsSubheading"] = "普通按钮栏"
L["CT_BottomBar/Options/AddonList/InformationalBarsSubheading"] = "信息显示栏"
L["CT_BottomBar/Options/AddonList/SpecialBarsSubheading"] = "特殊按钮栏"
L["CT_BottomBar/Options/AddonList/StatusTrackingBarsSubheading"] = "状态追踪栏"
L["CT_BottomBar/Options/BagsBar"] = "背包栏"
L["CT_BottomBar/Options/ClassBar"] = "职业栏"
L["CT_BottomBar/Options/ClassicKeyRingButton"] = "钥匙环按钮"
L["CT_BottomBar/Options/ClassicPerformanceBar"] = "性能栏"
L["CT_BottomBar/Options/ExpBar"] = "经验栏"
L["CT_BottomBar/Options/FlightBar"] = "停止飞行按钮"
L["CT_BottomBar/Options/FPSBar"] = "FPS指示"
L["CT_BottomBar/Options/General/BackgroundTextures/Heading"] = "背景材质"
L["CT_BottomBar/Options/General/BackgroundTextures/HideActionBarCheckButton"] = "隐藏动作栏材质"
L["CT_BottomBar/Options/General/BackgroundTextures/HideGryphonsCheckButton"] = "隐藏银龙/狮鹫"
L["CT_BottomBar/Options/General/BackgroundTextures/HideMenuAndBagsCheckButton"] = "隐藏菜单和背包材质"
L["CT_BottomBar/Options/General/BackgroundTextures/Line1"] = "控制默认UI栏位置后面的灰色背景"
L["CT_BottomBar/Options/General/BackgroundTextures/ShowLionsCheckButton"] = "显示狮鹫替代银龙"
L["CT_BottomBar/Options/General/Heading"] = "重要的常规选项"
L["CT_BottomBar/Options/MenuBar"] = "菜单栏"
L["CT_BottomBar/Options/MovableBars/Activate"] = "激活"
L["CT_BottomBar/Options/MovableBars/Hide"] = "隐藏"
L["CT_BottomBar/Options/PetBar"] = "宠物栏"
L["CT_BottomBar/Options/RepBar"] = "声望栏"
L["CT_BottomBar/Options/StanceBar"] = "姿态栏"
L["CT_BottomBar/Options/StatusBar"] = "状态栏 (经验 & 声望)"
L["CT_BottomBar/Options/TalkingHead"] = "任务对话"


end