------------------------------------------------
--                 CT_MailMod                 --
--                                            --
-- Mail several items at once with almost no  --
-- effort at all. Also takes care of opening  --
-- several mail items at once, reducing the   --
-- time spent on maintaining the inbox for    --
-- bank mules and such.                       --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

local _G = getfenv(0);
local module = _G["CT_MailMod"];

--------------------------------------------
-- Localization
module.text = module.text or { }
local L = module.text

-- enUS (default)

L["CT_MailMod/AutoCompleteFilter/Account"] = "Own toons on this account"
L["CT_MailMod/AutoCompleteFilter/Friends"] = "Friends list (including offline)"
L["CT_MailMod/AutoCompleteFilter/Group"] = "Current Group"
L["CT_MailMod/AutoCompleteFilter/Guild"] = "Guild list (including offline)"
L["CT_MailMod/AutoCompleteFilter/Online"] = "Online and/or nearby toons"
L["CT_MailMod/AutoCompleteFilter/Recent"] = "Recently Interacted"
L["CT_MailMod/DELETE_POPUP1"] = "%d items including %s"
L["CT_MailMod/DELETE_POPUP2"] = "some money and %s"
L["CT_MailMod/DELETE_POPUP3"] = "some money and %d items including %s"
L["CT_MailMod/Inbox/OpenSelectedButton"] = "Open"
L["CT_MailMod/Inbox/OpenSelectedTip"] = "Open selected messages"
L["CT_MailMod/Inbox/OpenSelectedTip2"] = "Only open mail from the Auction House"
L["CT_MailMod/Inbox/ReturnSelectedButton"] = "Return"
L["CT_MailMod/Inbox/ReturnSelectedTip"] = "Return the selected messages"
L["CT_MailMod/MAIL_DELETE_NO"] = "Not deleted."
L["CT_MailMod/MAIL_DELETE_OK"] = "Deleting mail."
L["CT_MailMod/MAIL_DOWNLOAD_BEGIN"] = "Waiting for mail to download into the inbox."
L["CT_MailMod/MAIL_DOWNLOAD_END"] = "Mail has downloaded into the inbox."
L["CT_MailMod/MAIL_LOG"] = "Log"
L["CT_MailMod/MAIL_LOOT_ERROR"] = "Item not taken:"
L["CT_MailMod/MAIL_OPEN_CLICK"] = "Press |c0080A0FFAlt-click|r to take the contents."
L["CT_MailMod/MAIL_OPEN_IS_COD"] = "Mail is Cash on Delivery."
L["CT_MailMod/MAIL_OPEN_IS_GM"] = "Mail is from Blizzard."
L["CT_MailMod/MAIL_OPEN_NO"] = "Not opened."
L["CT_MailMod/MAIL_OPEN_NO_ITEMS_MONEY"] = "Mail has no items or money."
L["CT_MailMod/MAIL_OPEN_OK"] = "Opening mail."
L["CT_MailMod/MAIL_RETURN_CLICK"] = "Press |c0080A0FFCtrl-click|r to return the message."
L["CT_MailMod/MAIL_RETURN_IS_GM"] = "Mail is from Blizzard."
L["CT_MailMod/MAIL_RETURN_IS_RETURNED"] = "Mail is returning to you."
L["CT_MailMod/MAIL_RETURN_NO"] = "Not returned."
L["CT_MailMod/MAIL_RETURN_NO_ITEMS_MONEY"] = "Mail has no items or money."
L["CT_MailMod/MAIL_RETURN_NO_REPLY"] = "Mail cannot be replied to."
L["CT_MailMod/MAIL_RETURN_NO_SENDER"] = "Mail has no sender."
L["CT_MailMod/MAIL_RETURN_OK"] = "Returning mail."
L["CT_MailMod/MAIL_SEND_OK"] = "Mail sent."
L["CT_MailMod/MAIL_TAKE_ITEM_OK"] = "Taking attachment."
L["CT_MailMod/MAIL_TAKE_MONEY_OK"] = "Taking money."
L["CT_MailMod/MAIL_TIMEOUT"] = "Action timed out."
L["CT_MailMod/MAILBOX_BUTTON_TIP1"] = "Download mail"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_NOW"] = "Download more mail"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_SOON"] = [=[Download more mail
in %d seconds]=]
L["CT_MailMod/MAILBOX_OPTIONS_TIP1"] = [=[To access CT_MailMod options and tips, click this button or type /ctmail.
Right click to toggle the mail log window or type /maillog.]=]
L["CT_MailMod/MAILBOX_OVERFLOW_COUNT"] = "Overflow: %d"
L["CT_MailMod/MailLog/Date"] = "Date"
L["CT_MailMod/MailLog/Delete"] = "Delete"
L["CT_MailMod/MailLog/Items"] = "Items"
L["CT_MailMod/MailLog/Money"] = "Money"
L["CT_MailMod/MailLog/Open"] = "Open"
L["CT_MailMod/MailLog/Receiver"] = "Receiver"
L["CT_MailMod/MailLog/Return"] = "Return"
L["CT_MailMod/MailLog/Send"] = "Send"
L["CT_MailMod/MailLog/Sender"] = "Sender"
L["CT_MailMod/MailLog/Subject"] = "Subject"
L["CT_MailMod/MONEY_DECREASED"] = "Your money decreased by: %s"
L["CT_MailMod/MONEY_INCREASED"] = "Your money increased by: %s"
L["CT_MailMod/NOTHING_FROM_AH"] = "None of the messages were from the auction house"
L["CT_MailMod/NOTHING_SELECTED"] = "No messages are selected."
L["CT_MailMod/NUMBER_SELECTED_PLURAL"] = "%d selected"
L["CT_MailMod/NUMBER_SELECTED_SINGLE"] = "%d selected"
L["CT_MailMod/NUMBER_SELECTED_ZERO"] = "%d selected"
L["CT_MailMod/PROCESSING_CANCELLED"] = "Mailbox processing cancelled."
L["CT_MailMod/QUICK_DELETE_TIP1"] = "Delete the message now"
L["CT_MailMod/QUICK_RETURN_TIP1"] = "Return the message now"
L["CT_MailMod/SELECT_ALL"] = "Select All"
L["CT_MailMod/SELECT_MESSAGE_TIP1"] = "Update message selection"
L["CT_MailMod/SELECT_MESSAGE_TIP2"] = [=[
|c0080A0FFClick:|r Select or unselect single

|c0080A0FFAlt Left-click:|r Select similar subjects
|c0080A0FFAlt Right-click:|r Unselect similar subjects

|c0080A0FFCtrl Left-click:|r Select same sender
|c0080A0FFCtrl Right-click:|r Unselect same sender

|c0080A0FFShift click:|r Mark start of range
|c0080A0FFShift Left-click:|r End range and select mail
|c0080A0FFShift Right-click:|r End range and unselect mail]=]
L["CT_MailMod/Send/AutoComplete/Heading"] = "Auto-complete settings"
L["CT_MailMod/Send/AutoComplete/Tip"] = "Select down-arrow to change the filters"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_COPPER"] = "%d copper"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_GOLD"] = "%d gold %d silver %d copper"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_SILVER"] = "%d silver %d copper"
L["CT_MailMod/STOP_SELECTED"] = "Cancel"
L["CT_MailMod/Options/Bags/CloseAllCheckButton"] = "Close all bags"
L["CT_MailMod/Options/Bags/CloseLabel"] = "When the mailbox closes:"
L["CT_MailMod/Options/Bags/Heading"] = "Inventory Bags"
L["CT_MailMod/Options/Bags/Line1"] = "Disabling these options may be necessary for compatability with other bag management addons"
L["CT_MailMod/Options/Bags/OpenAllCheckButton"] = "Open all bags"
L["CT_MailMod/Options/Bags/OpenBackpackCheckButton"] = "Open the backpack"
L["CT_MailMod/Options/Bags/OpenLabel"] = "When the mailbox opens:"
L["CT_MailMod/Options/General/BlockTradesCheckButton"] = "Block trades while using the mailbox"
L["CT_MailMod/Options/General/Heading"] = "General Options"
L["CT_MailMod/Options/General/NetIncomeCheckButton"] = "Show net income when the mailbox closes"
L["CT_MailMod/Options/Inbox/Checkboxes/Heading"] = "Message Checkboxes"
L["CT_MailMod/Options/Inbox/Checkboxes/Line1"] = "Mouseover the '?' for additional info"
L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewCheckButton"] = "Clear selection when shift-clicking a range"
L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewTip"] = [=[Choose a range by shift-clicking twice, 
or remove a range by shift-right-clicking the second time. 

This option clears prior selections when doing so.]=]
L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewCheckButton"] = "Clear selection when ctrl-clicking a sender"
L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewTip"] = [=[Shift-click to choose all messages from the same sender; 
or shift-right-click to choose all messages from other senders. 

This option clears your prior selections before doing so.]=]
L["CT_MailMod/Options/Inbox/Checkboxes/ShowCheckboxesCheckButton"] = "Show checkboxes and open/close buttons"
L["CT_MailMod/Options/Inbox/Checkboxes/ShowNumbersCheckButton"] = "Show message numbers"
L["CT_MailMod/Options/Inbox/Heading"] = "Inbox"
L["CT_MailMod/Options/Inbox/HideLogCheckButton"] = "|cFFFF9999Hide|r the 'Mail Log' button"
L["CT_MailMod/Options/Inbox/MouseWheelCheckButton"] = "Enable mouse wheel scrolling"
L["CT_MailMod/Options/Inbox/MultipleItemsCheckButton"] = "Show all attachments in message tooltips"
L["CT_MailMod/Options/Inbox/SelectMsgCheckButton"] = "Show tooltip for message checkboxes"
L["CT_MailMod/Options/Inbox/ShowExpiryCheckButton"] = "Show message expiry buttons"
L["CT_MailMod/Options/Inbox/ShowInboxCheckButton"] = "Show number of messages in the inbox"
L["CT_MailMod/Options/Inbox/ShowLongCheckButton"] = "Show long subjects on two lines"
L["CT_MailMod/Options/Inbox/ShowMailboxCheckButton"] = "Show number of messages not in the inbox"
L["CT_MailMod/Options/MailLog/BackgroundLabel"] = "Background color"
L["CT_MailMod/Options/MailLog/Delete/Button"] = "Delete log"
L["CT_MailMod/Options/MailLog/Delete/ConfirmationCheckButton"] = "I want to delete all of the log entries"
L["CT_MailMod/Options/MailLog/Delete/Heading"] = "Delete Log Entries"
L["CT_MailMod/Options/MailLog/Heading"] = "Mail Log"
L["CT_MailMod/Options/MailLog/LogDeletedButton"] = "Log deleted mail"
L["CT_MailMod/Options/MailLog/LogOpennedCheckButton"] = "Log opened mail"
L["CT_MailMod/Options/MailLog/LogReturnedCheckButton"] = "Log returned mail"
L["CT_MailMod/Options/MailLog/LogSentCheckButton"] = "Log sent mail"
L["CT_MailMod/Options/MailLog/PrintCheckButton"] = "Print log messages to chat"
L["CT_MailMod/Options/MailLog/SaveCheckButton"] = "Save log messages in the mail log"
L["CT_MailMod/Options/MailLog/ScaleSliderLabel"] = "Mail Log Scale = <value>"
L["CT_MailMod/Options/MailLog/Tip"] = [=[Type /maillog to see a log of every letter sent/received.

Resize the log by dragging its left or right edges, or by
using the scale slider below to make it bigger or smaller]=]
L["CT_MailMod/Options/Reset/Heading"] = "Reset Options"
L["CT_MailMod/Options/Reset/Line 1"] = "Note: This will reset the options to default and then reload your UI."
L["CT_MailMod/Options/Reset/ResetAllCheckbox"] = "Reset options for all of your characters"
L["CT_MailMod/Options/Reset/ResetButton"] = "Reset Options"
L["CT_MailMod/Options/SendMail/AltClickCheckButton"] = "Alt left-click adds items to the Send Mail tab"
L["CT_MailMod/Options/SendMail/FilterAutoCompleteCheckButton"] = "Filter auto-completion of Send To field"
L["CT_MailMod/Options/SendMail/FilterAutoCompleteTip"] = "When enabled, click on the button next to the recipient field to filter by:"
L["CT_MailMod/Options/SendMail/Heading"] = "Send Mail"
L["CT_MailMod/Options/SendMail/ProtectEditFocusCheckButton"] = "Prevent mailbox from losing keyboard focus"
L["CT_MailMod/Options/SendMail/ProtectEditFocusTip"] = [=[Returns the keyboard cursor to the mailbox after clicking on:
- Backpack and bag slots
- Mail attachment slots
- COD or Send Money buttons]=]
L["CT_MailMod/Options/SendMail/ReplaceSubjectCheckButton"] = "Replace blank subject with money amount"
L["CT_MailMod/Options/Tips/Heading"] = "Tips"
L["CT_MailMod/Options/Tips/Line1"] = "You can write /ctmail or /ctmailmod to open this options window directly."


--frFR (credits: ddc)

if (GetLocale() == "frFR") then

L["CT_MailMod/AutoCompleteFilter/Account"] = "Autres toons de cette compte"
L["CT_MailMod/AutoCompleteFilter/Friends"] = "Les amis (incluant ceux qui est hors ligne)"
L["CT_MailMod/AutoCompleteFilter/Group"] = "La groupe actuelle"
L["CT_MailMod/AutoCompleteFilter/Guild"] = "La guilde (incluant ceux qui est hors ligne)"
L["CT_MailMod/AutoCompleteFilter/Online"] = "Ceux qui est en ligne et/ou proche"
L["CT_MailMod/AutoCompleteFilter/Recent"] = "Ceux qui ont parlé récemment"
L["CT_MailMod/DELETE_POPUP1"] = "%d objets incluant %s"
L["CT_MailMod/DELETE_POPUP2"] = "d'argent et %s"
L["CT_MailMod/DELETE_POPUP3"] = "d'argent et %d objets incluant %s"
L["CT_MailMod/Inbox/OpenSelectedButton"] = "Ouvrir"
L["CT_MailMod/Inbox/OpenSelectedTip"] = "Ouvrir les courriers sélectionnés"
L["CT_MailMod/Inbox/OpenSelectedTip2"] = "Ouvrir seulement les messages de l'hôtel des ventes."
L["CT_MailMod/Inbox/ReturnSelectedButton"] = "Renvoyer"
L["CT_MailMod/Inbox/ReturnSelectedTip"] = "Renvoyer les courriers sélectionnés"
L["CT_MailMod/MAIL_DELETE_NO"] = "Pas supprimé."
L["CT_MailMod/MAIL_DELETE_OK"] = "Supprimant le courrier"
L["CT_MailMod/MAIL_DOWNLOAD_BEGIN"] = "Attendant du courrier d'arriver à la boîte de réception"
L["CT_MailMod/MAIL_DOWNLOAD_END"] = "Du courrier a arrivé à la boîte de réception"
L["CT_MailMod/MAIL_LOG"] = "Journ."
L["CT_MailMod/MAIL_LOOT_ERROR"] = "Objet non reçu:"
L["CT_MailMod/MAIL_OPEN_CLICK"] = "Appuyez sur |c0080A0FFAlt-clic|r pour prendre les contenus."
L["CT_MailMod/MAIL_OPEN_IS_COD"] = "Ce courrier demande un paiement à la livraison."
L["CT_MailMod/MAIL_OPEN_IS_GM"] = "Ce courrier est envoyé par Blizzard."
L["CT_MailMod/MAIL_OPEN_NO"] = "Pas ouverte."
L["CT_MailMod/MAIL_OPEN_NO_ITEMS_MONEY"] = "Ce courrier ne contient aucun objet ni argent."
L["CT_MailMod/MAIL_OPEN_OK"] = "Ouvrir le courrier."
L["CT_MailMod/MAIL_RETURN_CLICK"] = "Appuyez sur |c0080A0FFCtrl-clic|r pour renvoyer ce courrier."
L["CT_MailMod/MAIL_RETURN_IS_GM"] = "Ce courrier est envoyé par Blizzard."
L["CT_MailMod/MAIL_RETURN_IS_RETURNED"] = "Ce courrier est vous renvoyé."
L["CT_MailMod/MAIL_RETURN_NO"] = "Pas renvoyé."
L["CT_MailMod/MAIL_RETURN_NO_ITEMS_MONEY"] = "Ce courrier ne contient aucun objet ni argent."
L["CT_MailMod/MAIL_RETURN_NO_REPLY"] = "Ce n'est pas possible de répondre à ce courrier."
L["CT_MailMod/MAIL_RETURN_NO_SENDER"] = "Ce courrier manque un envoyeur."
L["CT_MailMod/MAIL_RETURN_OK"] = "Renvoyer le courrier."
L["CT_MailMod/MAIL_SEND_OK"] = "Le courrier est envoyé."
L["CT_MailMod/MAIL_TAKE_ITEM_OK"] = "Prendre l'objet."
L["CT_MailMod/MAIL_TAKE_MONEY_OK"] = "Prendre l'argent."
L["CT_MailMod/MAIL_TIMEOUT"] = "L'action a arrêté après le dépassement de délai."
L["CT_MailMod/MAILBOX_BUTTON_TIP1"] = "Obtenir plus de courrier"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_NOW"] = "Obtenir plus de courrier"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_SOON"] = [=[Plus de courrier arrive
dans %d seconds]=]
L["CT_MailMod/MAILBOX_OPTIONS_TIP1"] = [=[Cliquez ce bouton, tapez "/ctmail" ou tapez "/ctcourrier" pour accéder les options de CT_MailMod.

Faites un clic-droit ou tapez "/mailog" pour ouvrir le journal de courrier.]=]
L["CT_MailMod/MAILBOX_OVERFLOW_COUNT"] = "Débordement : %d"
L["CT_MailMod/MailLog/Date"] = "La date"
L["CT_MailMod/MailLog/Delete"] = "Supprimer"
L["CT_MailMod/MailLog/Items"] = "Les objets"
L["CT_MailMod/MailLog/Money"] = "L'argent"
L["CT_MailMod/MailLog/Open"] = "Ouvrir"
L["CT_MailMod/MailLog/Receiver"] = "Le receveur"
L["CT_MailMod/MailLog/Return"] = "Renvoyer"
L["CT_MailMod/MailLog/Send"] = "Envoyer"
L["CT_MailMod/MailLog/Sender"] = "L'expéditeur"
L["CT_MailMod/MailLog/Subject"] = "Le sujet"
L["CT_MailMod/MONEY_DECREASED"] = "Votre argent diminue de : %s"
L["CT_MailMod/MONEY_INCREASED"] = "Votre argent augmente de : %s"
L["CT_MailMod/NOTHING_FROM_AH"] = "Aucune des messages sélectionnés origine de l'hotel des ventes."
L["CT_MailMod/NOTHING_SELECTED"] = "Aucune courrier sélectionné."
L["CT_MailMod/NUMBER_SELECTED_PLURAL"] = "%d sélectionnés"
L["CT_MailMod/NUMBER_SELECTED_SINGLE"] = "%d sélectionné"
L["CT_MailMod/NUMBER_SELECTED_ZERO"] = "Aucune sélection"
L["CT_MailMod/PROCESSING_CANCELLED"] = "Le traitement des courriers annulé."
L["CT_MailMod/QUICK_DELETE_TIP1"] = "Supprimer ce courrier maintenant"
L["CT_MailMod/QUICK_RETURN_TIP1"] = "Renvoyer ce courrier maintenant"
L["CT_MailMod/SELECT_ALL"] = "Tous"
L["CT_MailMod/SELECT_MESSAGE_TIP1"] = "Mettre à jour la sélection des courriers"
L["CT_MailMod/SELECT_MESSAGE_TIP2"] = [=[|c0080A0FFClic:|r Sélecter un seul courrier

|c0080A0FFAlt-click-gauche:|r Sélectionner tous ayant le même sujet
|c0080A0FFAlt-clic-droite:|r Sélectionner tous ayant un sujet différent

|c0080A0FFCtrl-clic-gauche:|r Sélectionner tous de cet envoyeur
|c0080A0FFCtrl-clic-droite:|r Sélectionner tous d'autres envoyeurs

|c0080A0FFMaj-clic:|r Commencer une gamme
|c0080A0FFMaj-clic-gauche:|r Finir la gamme et sélectionner les courriers
|c0080A0FFMaj-clic-droite:|r Finir la gamme et désélectionner les courriers]=]
L["CT_MailMod/Send/AutoComplete/Heading"] = "La saisie automatique"
L["CT_MailMod/Send/AutoComplete/Tip"] = "Appuyez pour changer les filtres"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_COPPER"] = "%d cuivre"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_GOLD"] = "%d or %d argent %d cuivre"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_SILVER"] = "%d argent %d cuivre"
L["CT_MailMod/STOP_SELECTED"] = "Annuler"
L["CT_MailMod/Options/Bags/CloseAllCheckButton"] = "Fermer tous les sacs"
L["CT_MailMod/Options/Bags/CloseLabel"] = "Quand la boîte ferme :"
L["CT_MailMod/Options/Bags/Heading"] = "Les sacs d'inventaire"
L["CT_MailMod/Options/Bags/Line1"] = "Désactivant ces options peut être nécessaire pour compatabilité aux autres addons de gestion des sacs"
L["CT_MailMod/Options/Bags/OpenAllCheckButton"] = "Ouvrir tous les sacs"
L["CT_MailMod/Options/Bags/OpenBackpackCheckButton"] = "Ouvrir le sac à dos"
L["CT_MailMod/Options/Bags/OpenLabel"] = "Quand la boîte ouvre :"
L["CT_MailMod/Options/General/BlockTradesCheckButton"] = "Bloquer les échanges en lisant le courrier"
L["CT_MailMod/Options/General/Heading"] = "Les options génerales"
L["CT_MailMod/Options/General/NetIncomeCheckButton"] = "Imprimer le revenu net quand le courrier ferme"
L["CT_MailMod/Options/Inbox/Checkboxes/Heading"] = "Les cases à cocher"
L["CT_MailMod/Options/Inbox/Checkboxes/Line1"] = "Passez la souris sur le '?' pour plus d'info"
L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewCheckButton"] = "Réinitialiser avant de faire une gamme (Maj)"
L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewTip"] = [=[Choisir une gamme en appuyant Maj-clic deux fois, 
ou réduire une gamme en appuyant Maj-clic-droite la deuxième fois. 

Cet option efface les sélections antérieures.]=]
L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewCheckButton"] = "Réinitialiser avant de choisir une exp. (ctrl)"
L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewTip"] = [=[Choisir chaque courrier du même expéditeur (ctrl-clic-gauche), 
ou des autres expéditeurs (ctrl-clic-droite). 

Cet option efface les sélections antérieures.]=]
L["CT_MailMod/Options/Inbox/Checkboxes/ShowCheckboxesCheckButton"] = "Montrer les cases à cocher et boutons d'ouv./fer."
L["CT_MailMod/Options/Inbox/Checkboxes/ShowNumbersCheckButton"] = "Numéroter les courriers"
L["CT_MailMod/Options/Inbox/Heading"] = "Boîte de réception"
L["CT_MailMod/Options/Inbox/HideLogCheckButton"] = "|cFFFF9999Cacher|r le bouton 'Log' (journal)"
L["CT_MailMod/Options/Inbox/MouseWheelCheckButton"] = "Activer le défilement de la souris"
L["CT_MailMod/Options/Inbox/MultipleItemsCheckButton"] = "Montrer les attaches dans les info-bulles"
L["CT_MailMod/Options/Inbox/SelectMsgCheckButton"] = "Montrer l'info-bulle des cases à cocher"
L["CT_MailMod/Options/Inbox/ShowExpiryCheckButton"] = "Montrer les boutons d'éxpiration de courrier"
L["CT_MailMod/Options/Inbox/ShowInboxCheckButton"] = "Montrer combien de courrier est arrivé"
L["CT_MailMod/Options/Inbox/ShowLongCheckButton"] = "Diviser des sujets longs en deux lignes"
L["CT_MailMod/Options/Inbox/ShowMailboxCheckButton"] = "Montrer combien de courrier ne peut pas arriver"
L["CT_MailMod/Options/MailLog/BackgroundLabel"] = "Le couleur de fond"
L["CT_MailMod/Options/MailLog/Delete/Button"] = "Effacer"
L["CT_MailMod/Options/MailLog/Delete/ConfirmationCheckButton"] = "Je veux effacer tous les entrées dans le journal"
L["CT_MailMod/Options/MailLog/Delete/Heading"] = "Effacer le journal"
L["CT_MailMod/Options/MailLog/Heading"] = "Le journal de courrier"
L["CT_MailMod/Options/MailLog/LogDeletedButton"] = "Enregistrer le courrier supprimé"
L["CT_MailMod/Options/MailLog/LogOpennedCheckButton"] = "Enregistrer le courrier ouvert"
L["CT_MailMod/Options/MailLog/LogReturnedCheckButton"] = "Enregistrer le courrier renvoyé"
L["CT_MailMod/Options/MailLog/LogSentCheckButton"] = "Enregistrer le courrier envoyé"
L["CT_MailMod/Options/MailLog/PrintCheckButton"] = "Imprimer des entrées au fenêtre de discussion"
L["CT_MailMod/Options/MailLog/SaveCheckButton"] = "Sauvguarder des entrées au journal"
L["CT_MailMod/Options/MailLog/ScaleSliderLabel"] = "Échelle du journal = <value>"
L["CT_MailMod/Options/MailLog/Tip"] = [=[Tapez /maillog pour voir un journal de tous courriers envoyés/reçus.
Changer la grandeur par glisser les bordures gauche et droite,
ou en utilisant la glissière d’échelle en-bas.]=]
L["CT_MailMod/Options/Reset/Heading"] = "Réinitialiser les options"
L["CT_MailMod/Options/Reset/Line 1"] = "Note: Ce bouton réinitialise les options aux valeurs par défaut, et il recharge l'interface"
L["CT_MailMod/Options/Reset/ResetAllCheckbox"] = "Réinitialiser les options pour tous les personnages"
L["CT_MailMod/Options/Reset/ResetButton"] = "Réinitialiser"
L["CT_MailMod/Options/SendMail/AltClickCheckButton"] = "Alt-clic-gauche ajoute des objets à l'onglet Envoyer un Message"
L["CT_MailMod/Options/SendMail/FilterAutoCompleteCheckButton"] = "Filtrer la saisie automatique du destinataire"
L["CT_MailMod/Options/SendMail/FilterAutoCompleteTip"] = "Ajouter un menu à côté du destinataire pour filtrer la saisie automatique par :"
L["CT_MailMod/Options/SendMail/Heading"] = "Envoyer un message"
L["CT_MailMod/Options/SendMail/ProtectEditFocusCheckButton"] = "Maintenir le curseur sur les saisies"
L["CT_MailMod/Options/SendMail/ProtectEditFocusTip"] = [=[Retourner le curseur aux saisies de l'onglet Envoyer un Message après qu'on appuie sur:
- Des objets dans les sacs 
- Des pièces jointes
- Les boutons "C.R." ou "Env. Argent"]=]
L["CT_MailMod/Options/SendMail/ReplaceSubjectCheckButton"] = "Remplir le sujet vide avec le montant d'argent"
L["CT_MailMod/Options/Tips/Heading"] = "Des conseils"
L["CT_MailMod/Options/Tips/Line1"] = "Vous pouvez écrire /ctcourrier or /ctmailmod pour ouvrir ces options."


--deDE (credits: dynaletik)

elseif (GetLocale() == "deDE") then

L["CT_MailMod/AutoCompleteFilter/Account"] = "Eigene Twinks auf diesem Account"
L["CT_MailMod/AutoCompleteFilter/Friends"] = "Kontaktliste (inklusive offline)"
L["CT_MailMod/AutoCompleteFilter/Group"] = "Aktuelle Gruppe"
L["CT_MailMod/AutoCompleteFilter/Guild"] = "Gildenliste (inklusive offline)"
L["CT_MailMod/AutoCompleteFilter/Online"] = "Online und/oder Twinks in der Nähe"
L["CT_MailMod/AutoCompleteFilter/Recent"] = "Zuletzt interagiert"
L["CT_MailMod/DELETE_POPUP1"] = "%d Gegenstände enthalten %s"
L["CT_MailMod/DELETE_POPUP2"] = "etwas Geld und %s"
L["CT_MailMod/DELETE_POPUP3"] = "etwas Geld und %d Gegenstände enthalten %s"
L["CT_MailMod/Inbox/OpenSelectedButton"] = "Öffnen"
L["CT_MailMod/Inbox/OpenSelectedTip"] = "Gewählte Nachrichten öffnen"
L["CT_MailMod/Inbox/ReturnSelectedButton"] = "Zurücksenden"
L["CT_MailMod/Inbox/ReturnSelectedTip"] = "Gewählte Nachrichten zurücksenden"
L["CT_MailMod/MAIL_DELETE_NO"] = "Nicht gelöscht."
L["CT_MailMod/MAIL_DELETE_OK"] = "Lösche Post."
L["CT_MailMod/MAIL_DOWNLOAD_BEGIN"] = "Post wird in Eingang heruntergeladen."
L["CT_MailMod/MAIL_DOWNLOAD_END"] = "Post wurde in Eingang heruntergeladen."
L["CT_MailMod/MAIL_LOG"] = "Protokoll"
L["CT_MailMod/MAIL_LOOT_ERROR"] = "Gegenstand nicht entnommen:"
L["CT_MailMod/MAIL_OPEN_CLICK"] = "Drücke |c0080A0FFAlt-Klick|r um Anhänge zu entnehmen."
L["CT_MailMod/MAIL_OPEN_IS_COD"] = "Post besitzt Nachnahme-Gebühr."
L["CT_MailMod/MAIL_OPEN_IS_GM"] = "Post von Blizzard"
L["CT_MailMod/MAIL_OPEN_NO"] = "Nicht geöffnet"
L["CT_MailMod/MAIL_OPEN_NO_ITEMS_MONEY"] = "Post enthält keine Gegenstände oder Geld."
L["CT_MailMod/MAIL_OPEN_OK"] = "Öffne Post."
L["CT_MailMod/MAIL_RETURN_CLICK"] = "Drücke |c0080A0FFStrg-Klick|r um den Brief zurückzusenden."
L["CT_MailMod/MAIL_RETURN_IS_GM"] = "Post von Blizzard."
L["CT_MailMod/MAIL_RETURN_IS_RETURNED"] = "Post wird zu Dir zurückgesendet."
L["CT_MailMod/MAIL_RETURN_NO"] = "Nicht zurückgesendet."
L["CT_MailMod/MAIL_RETURN_NO_ITEMS_MONEY"] = "Post enthält keine Gegenstände oder Geld."
L["CT_MailMod/MAIL_RETURN_NO_REPLY"] = "Post kann nicht beantwortet werden."
L["CT_MailMod/MAIL_RETURN_NO_SENDER"] = "Post hat keinen Absender."
L["CT_MailMod/MAIL_RETURN_OK"] = "Sende Post zurück."
L["CT_MailMod/MAIL_SEND_OK"] = "Post verschickt."
L["CT_MailMod/MAIL_TAKE_ITEM_OK"] = "Entnehme Anhang."
L["CT_MailMod/MAIL_TAKE_MONEY_OK"] = "Entnehme Geld."
L["CT_MailMod/MAIL_TIMEOUT"] = "Zeitüberschreitung bei Aktion."
L["CT_MailMod/MAILBOX_BUTTON_TIP1"] = "Post herunterladen"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_NOW"] = "Weitere Post herunterladen"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_SOON"] = "Weitere Post in %d Sekunden herunterladen"
L["CT_MailMod/MAILBOX_OPTIONS_TIP1"] = [=[Klicke diese Schaltfläche oder gebe /ctmail ein, um CTMailMod Optionen oder Hinweise anzuzeigen. 

Rechtsklick oder /maillog eingeben um Protokollfenster ein-/auszublenden.]=]
L["CT_MailMod/MAILBOX_OVERFLOW_COUNT"] = "Überlauf: %d"
L["CT_MailMod/MailLog/Date"] = "Datum"
L["CT_MailMod/MailLog/Delete"] = "Löschen"
L["CT_MailMod/MailLog/Items"] = "Gegenstände"
L["CT_MailMod/MailLog/Money"] = "Geld"
L["CT_MailMod/MailLog/Open"] = "Öffnen"
L["CT_MailMod/MailLog/Receiver"] = "Empfänger"
L["CT_MailMod/MailLog/Return"] = "Zurücksenden"
L["CT_MailMod/MailLog/Send"] = "Senden"
L["CT_MailMod/MailLog/Sender"] = "Absender"
L["CT_MailMod/MailLog/Subject"] = "Betreff"
L["CT_MailMod/MONEY_DECREASED"] = "Geld verringert um: %s"
L["CT_MailMod/MONEY_INCREASED"] = "Geld erhöht um: %s"
L["CT_MailMod/NOTHING_SELECTED"] = "Es sind keine Briefe ausgewählt."
L["CT_MailMod/NUMBER_SELECTED_PLURAL"] = "%d gewählt"
L["CT_MailMod/NUMBER_SELECTED_SINGLE"] = "%d gewählt"
L["CT_MailMod/NUMBER_SELECTED_ZERO"] = "%d gewählt"
L["CT_MailMod/PROCESSING_CANCELLED"] = "Briefkasten Bearbeitung abgebrochen."
L["CT_MailMod/QUICK_DELETE_TIP1"] = "Brief jetzt löschen"
L["CT_MailMod/QUICK_RETURN_TIP1"] = "Brief jetzt zurücksenden"
L["CT_MailMod/SELECT_ALL"] = "Alle wählen"
L["CT_MailMod/SELECT_MESSAGE_TIP1"] = "Briefwahl aktualisieren"
L["CT_MailMod/SELECT_MESSAGE_TIP2"] = [=[|c0080A0FFKlick:|r Einzeln auswählen oder abwählen
 
 |c0080A0FFAlt Linksklick:|r Gleichen Betreff auswählen
 |c0080A0FFAlt Rechtsklick:|r Gleichen Betreff abwählen
 
 |c0080A0FFStrg Linksklick:|r Gleichen Absender auswählen
 |c0080A0FFStrg Rechtsklick:|r Gleichen Absender abwählen
 
 |c0080A0FFShift Klick:|r Anfang der Auswahl markieren
 |c0080A0FFShift Linksklick:|r Ende der Auswahl markieren und auswählen
 |c0080A0FFShift Rechtsklick:|r Ende der Auswahl markieren und Abwählen]=]
L["CT_MailMod/Send/AutoComplete/Heading"] = "Auto-Vervollständigung Einstellungen"
L["CT_MailMod/Send/AutoComplete/Tip"] = "Abwärts-Pfeil zum Ändern der Filter wählen"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_COPPER"] = "%d Kupfer"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_GOLD"] = "%d Gold %d Silber %d Kupfer"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_SILVER"] = "%d Silber %d Kupfer"
L["CT_MailMod/STOP_SELECTED"] = "Abbrechen"
L["CT_MailMod/Options/Bags/CloseAllCheckButton"] = "Alle Taschen schließen"
L["CT_MailMod/Options/Bags/CloseLabel"] = "Wenn sich der Briefkasten schließt:"
L["CT_MailMod/Options/Bags/Heading"] = "Inventar Behälter"
L["CT_MailMod/Options/Bags/Line1"] = "Das Deaktivieren dieser Optionen kann für die Kompatibilität zu anderen Rucksack-Addons erforderlich sein"
L["CT_MailMod/Options/Bags/OpenAllCheckButton"] = "Alle Taschen öffnen"
L["CT_MailMod/Options/Bags/OpenBackpackCheckButton"] = "Rucksack öffnen"
L["CT_MailMod/Options/Bags/OpenLabel"] = "Wenn der Briefkasten geöffnet wird:"
L["CT_MailMod/Options/General/BlockTradesCheckButton"] = "Handel während der Nutzung des Briefkastens blockieren"
L["CT_MailMod/Options/General/Heading"] = "Allgemeine Optionen"
L["CT_MailMod/Options/General/NetIncomeCheckButton"] = "Gesamteinkommen beim Schließen des Briefkastens anzeigen"
L["CT_MailMod/Options/Inbox/Checkboxes/Heading"] = "Nachrichten Kontrollkästchen"
L["CT_MailMod/Options/Inbox/Checkboxes/Line1"] = "Für zusätzliche Info mit der Maus über das '?' fahren"
L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewCheckButton"] = "Auswahl durch Shift-Linksklick auf einen Bereich aufheben"
L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewTip"] = "Auswahl durch Shift-Doppelklick treffen oder Auswahl entfernen durch Shift-Linksklick und dann Shift-Rechtsklick. Diese Option entfernt dabei vorherige Auswahlen."
L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewCheckButton"] = "Auswahl durch Strg-Linksklick auf einen Absender aufheben"
L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewTip"] = "Shift-Klick um alle Nachrichten vom gleichen Absender zu wählen oder Shift-Rechtsklick um alle Nachrichten von anderen Absenders zu wählen. Diese Option entfernt dabei vorherige Auswahlen."
L["CT_MailMod/Options/Inbox/Checkboxes/ShowCheckboxesCheckButton"] = "Kontrollkästchen und Öffnen/Schließen Buttons verstecken"
L["CT_MailMod/Options/Inbox/Checkboxes/ShowNumbersCheckButton"] = "Nachrichtenanzahl auf Kontrollkästchen anzeigen"
L["CT_MailMod/Options/Inbox/Heading"] = "Posteingang"
L["CT_MailMod/Options/Inbox/HideLogCheckButton"] = "'Protokoll' Button |cFFFF9999verstecken|r"
L["CT_MailMod/Options/Inbox/MouseWheelCheckButton"] = "Mausrad-Scrolling aktivieren"
L["CT_MailMod/Options/Inbox/MultipleItemsCheckButton"] = "Alle Anhänge in Tooltips der Briefe anzeigen"
L["CT_MailMod/Options/Inbox/SelectMsgCheckButton"] = "Tooltip für Nachrichten Kontrollkästchen anzeigen"
L["CT_MailMod/Options/Inbox/ShowExpiryCheckButton"] = "Ablaufbuttons der Nachrichten anzeigen"
L["CT_MailMod/Options/Inbox/ShowInboxCheckButton"] = "Anzahl der Briefe im Posteingang anzeigen"
L["CT_MailMod/Options/Inbox/ShowLongCheckButton"] = "Langen Betreff in zwei Zeilen anzeigen"
L["CT_MailMod/Options/Inbox/ShowMailboxCheckButton"] = "Anzahl der Briefe außerhalb des Posteingangs anzeigen"
L["CT_MailMod/Options/MailLog/BackgroundLabel"] = "Hintergrundfarbe"
L["CT_MailMod/Options/MailLog/Delete/Button"] = "Protokoll löschen"
L["CT_MailMod/Options/MailLog/Delete/ConfirmationCheckButton"] = "Ich möchte alle Protokolle löschen"
L["CT_MailMod/Options/MailLog/Delete/Heading"] = "Protokolle löschen"
L["CT_MailMod/Options/MailLog/Heading"] = "Briefprotokoll"
L["CT_MailMod/Options/MailLog/LogDeletedButton"] = "Gelöschte Briefe protokollieren"
L["CT_MailMod/Options/MailLog/LogOpennedCheckButton"] = "Geöffnete Briefe protokollieren"
L["CT_MailMod/Options/MailLog/LogReturnedCheckButton"] = "Zurückgesandte Briefe protokollieren"
L["CT_MailMod/Options/MailLog/LogSentCheckButton"] = "Gesendete Briefe protokollieren"
L["CT_MailMod/Options/MailLog/PrintCheckButton"] = "Protokollnachrichten im Chat ausgeben"
L["CT_MailMod/Options/MailLog/SaveCheckButton"] = "Protokollnachrichten im Briefprotokoll speichern"
L["CT_MailMod/Options/MailLog/ScaleSliderLabel"] = "Nachrichtenprotokoll Maßstab = <value>"
L["CT_MailMod/Options/MailLog/Tip"] = "Gebe /maillog ein um ein Protokoll aller gesendeten/empfangenen Briefe anzuzeigen. Die Fenster des Protokolls kann durch Ziehen an den linken oder rechten Rändern angepasst werden oder durch den Schieberegler hierunter im Maßstab verstellt werden."
L["CT_MailMod/Options/Reset/Heading"] = "Optionen zurücksetzen"
L["CT_MailMod/Options/Reset/Line 1"] = "Hinweis: Setzt Optionen auf Standardwerte zurück und lädt das Interface neu."
L["CT_MailMod/Options/Reset/ResetAllCheckbox"] = "Optionen für alle Charaktere zurücksetzen"
L["CT_MailMod/Options/Reset/ResetButton"] = "Zurücksetzen"
L["CT_MailMod/Options/SendMail/AltClickCheckButton"] = "Alt-Linksklick fügt Gegenstände zum Register gesendeter Briefe hinzu"
L["CT_MailMod/Options/SendMail/FilterAutoCompleteCheckButton"] = "Auto-Vervollständigung des Empfängerfeldes filtern"
L["CT_MailMod/Options/SendMail/FilterAutoCompleteTip"] = "Bei Aktivierung auf den Button neben dem Empfängerfeld klicken um zu filtern nach:"
L["CT_MailMod/Options/SendMail/Heading"] = "Briefe versenden"
L["CT_MailMod/Options/SendMail/ProtectEditFocusCheckButton"] = "Tastatureingaben im Briefkasten forcieren"
L["CT_MailMod/Options/SendMail/ProtectEditFocusTip"] = "Startet nach folgenden Klicks im Briefkasten wieder die Tastatureingabe: - Rucksack und Taschenplätze - Brief Anhangplätze - Nachnahme oder Geld senden Schaltflächen"
L["CT_MailMod/Options/SendMail/ReplaceSubjectCheckButton"] = "Leeren Betreff durch Geldbetrag ersetzen"
L["CT_MailMod/Options/Tips/Heading"] = "Hinweise"
L["CT_MailMod/Options/Tips/Line1"] = "Durch Eingabe von  /ctmail oder /ctmailmod wird dieses Optionsfenster direkt geöffnet."


--esES (credits: n/a)

elseif (GetLocale() == "esES" or GetLocale() == "esMX") then

L["CT_MailMod/DELETE_POPUP2"] = "algún dinero y %s"
L["CT_MailMod/DELETE_POPUP3"] = "algún dinero y %d objetos incluyendo %s"


--reRU (credits: imposeren)

elseif (GetLocale() == "ruRU") then

L["CT_MailMod/Inbox/OpenSelectedButton"] = "Открыть"
L["CT_MailMod/Inbox/OpenSelectedTip"] = "Открыть выбранные сообщения"
L["CT_MailMod/Inbox/ReturnSelectedButton"] = "Вернуть"
L["CT_MailMod/Inbox/ReturnSelectedTip"] = "Вернуть выбранные сообщения"
L["CT_MailMod/Options/Bags/CloseLabel"] = "Когда закрывается почта:"
L["CT_MailMod/Options/Bags/OpenAllCheckButton"] = "Открыть все сумки"
L["CT_MailMod/Options/Bags/OpenLabel"] = "Когда открывается почта:"
L["CT_MailMod/Options/General/BlockTradesCheckButton"] = "Блокировать обмен когда используется почта"
L["CT_MailMod/Options/General/NetIncomeCheckButton"] = "Показывать общую прибыль по закрытию почты"
L["CT_MailMod/Options/Inbox/Checkboxes/Line1"] = "Наведите мышь на '?' для доп. информации"


-- ptBR (credits: BansheeLyris )

elseif (GetLocale() == "ptBR") then

L["CT_MailMod/AutoCompleteFilter/Account"] = "Reconhecer personagens nessa conta"
L["CT_MailMod/AutoCompleteFilter/Friends"] = "Lista de amigos (incluindo offline)"
L["CT_MailMod/AutoCompleteFilter/Group"] = "Grupo atual"
L["CT_MailMod/AutoCompleteFilter/Guild"] = "Lista da Guilda (incluindo offline)"
L["CT_MailMod/AutoCompleteFilter/Online"] = "Online e/ou personagems próximos"
L["CT_MailMod/AutoCompleteFilter/Recent"] = "Interagido recentemente"
L["CT_MailMod/Options/Bags/CloseAllCheckButton"] = "Fechar todas as bolsas"
L["CT_MailMod/Options/Bags/CloseLabel"] = "Quando o correio é fechado: "
L["CT_MailMod/Options/Bags/Heading"] = "Bolsas do inventório "
L["CT_MailMod/Options/Bags/Line1"] = "A desativação dessas opções pode ser necessária para compatibilidade com outros addons de gerenciamento de bolsas"
L["CT_MailMod/Options/Bags/OpenAllCheckButton"] = "Abrir todas as bolsas"
L["CT_MailMod/Options/Bags/OpenLabel"] = "Quando a caixa de correio é aberta:"


--zhCN (credits: 萌丶汉丶纸 )

elseif (GetLocale() == "zhCN") then

L["CT_MailMod/AutoCompleteFilter/Account"] = "此战网上的自己的角色"
L["CT_MailMod/AutoCompleteFilter/Friends"] = "好友列表 (包括离线)"
L["CT_MailMod/AutoCompleteFilter/Group"] = "当前组"
L["CT_MailMod/AutoCompleteFilter/Guild"] = "公会名单 (包括离线)"
L["CT_MailMod/AutoCompleteFilter/Online"] = "在线和/或附近的人物"
L["CT_MailMod/AutoCompleteFilter/Recent"] = "最近互动"
L["CT_MailMod/DELETE_POPUP1"] = "%d 物品包括 %s"
L["CT_MailMod/DELETE_POPUP2"] = "一些钱和 %s"
L["CT_MailMod/DELETE_POPUP3"] = "一些钱和 %d 物品包括 %s"
L["CT_MailMod/Inbox/OpenSelectedButton"] = "打开"
L["CT_MailMod/Inbox/OpenSelectedTip"] = "打开选择消息"
L["CT_MailMod/Inbox/ReturnSelectedButton"] = "退回"
L["CT_MailMod/Inbox/ReturnSelectedTip"] = "退回选定消息"
L["CT_MailMod/MAIL_DELETE_NO"] = "不删除."
L["CT_MailMod/MAIL_DELETE_OK"] = "删除邮件."
L["CT_MailMod/MAIL_DOWNLOAD_BEGIN"] = "等待邮件下载到收件箱中."
L["CT_MailMod/MAIL_DOWNLOAD_END"] = "邮件已下载到收件箱."
L["CT_MailMod/MAIL_LOG"] = "日志"
L["CT_MailMod/MAIL_LOOT_ERROR"] = "物品未拿走:"
L["CT_MailMod/MAIL_OPEN_CLICK"] = "|c0080A0FFAlt+左键|r 取东西."
L["CT_MailMod/MAIL_OPEN_IS_COD"] = "邮件是货到付款."
L["CT_MailMod/MAIL_OPEN_IS_GM"] = "邮件来自暴雪."
L["CT_MailMod/MAIL_OPEN_NO"] = "未开启."
L["CT_MailMod/MAIL_OPEN_NO_ITEMS_MONEY"] = "邮件没有任何物品或钱."
L["CT_MailMod/MAIL_OPEN_OK"] = "打开邮件."
L["CT_MailMod/MAIL_RETURN_CLICK"] = "|c0080A0FFCtrl+左键|r 退回消息."
L["CT_MailMod/MAIL_RETURN_IS_GM"] = "邮件来自暴雪."
L["CT_MailMod/MAIL_RETURN_IS_RETURNED"] = "邮件退回给你."
L["CT_MailMod/MAIL_RETURN_NO"] = "没退回."
L["CT_MailMod/MAIL_RETURN_NO_ITEMS_MONEY"] = "邮件没有任何物品或钱."
L["CT_MailMod/MAIL_RETURN_NO_REPLY"] = "邮件无法回复."
L["CT_MailMod/MAIL_RETURN_NO_SENDER"] = "邮件没有发件人."
L["CT_MailMod/MAIL_RETURN_OK"] = "退回邮件."
L["CT_MailMod/MAIL_SEND_OK"] = "邮件已发送."
L["CT_MailMod/MAIL_TAKE_ITEM_OK"] = "拿附件."
L["CT_MailMod/MAIL_TAKE_MONEY_OK"] = "拿钱."
L["CT_MailMod/MAIL_TIMEOUT"] = "操作超时."
L["CT_MailMod/MAILBOX_BUTTON_TIP1"] = "下载邮件"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_NOW"] = "下载更多邮件"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_SOON"] = [=[下载更多邮件
在 %d 秒内]=]
L["CT_MailMod/MAILBOX_OPTIONS_TIP1"] = [=[要访问CT_MailMod选项和提示, 单击此按钮或键入 /ctmail.
右键单击可切换邮件日志窗口或键入 /maillog.]=]
L["CT_MailMod/MAILBOX_OVERFLOW_COUNT"] = "溢出: %d"
L["CT_MailMod/MailLog/Date"] = "日期"
L["CT_MailMod/MailLog/Delete"] = "删除"
L["CT_MailMod/MailLog/Items"] = "物品"
L["CT_MailMod/MailLog/Money"] = "钱"
L["CT_MailMod/MailLog/Open"] = "打开"
L["CT_MailMod/MailLog/Receiver"] = "接收者"
L["CT_MailMod/MailLog/Return"] = "退回"
L["CT_MailMod/MailLog/Send"] = "发送"
L["CT_MailMod/MailLog/Sender"] = "发送者"
L["CT_MailMod/MailLog/Subject"] = "主题"
L["CT_MailMod/MONEY_DECREASED"] = "你的钱减少了: %s"
L["CT_MailMod/MONEY_INCREASED"] = "你的钱增加了: %s"
L["CT_MailMod/NOTHING_SELECTED"] = "未选择任何消息."
L["CT_MailMod/NUMBER_SELECTED_PLURAL"] = "%d 已选择"
L["CT_MailMod/NUMBER_SELECTED_SINGLE"] = "%d 已选择"
L["CT_MailMod/NUMBER_SELECTED_ZERO"] = "%d 已选择"
L["CT_MailMod/PROCESSING_CANCELLED"] = "邮箱处理已取消."
L["CT_MailMod/QUICK_DELETE_TIP1"] = "立即清除消息"
L["CT_MailMod/QUICK_RETURN_TIP1"] = "立即退回消息"
L["CT_MailMod/SELECT_ALL"] = "选择所有"
L["CT_MailMod/SELECT_MESSAGE_TIP1"] = "更新消息选择"
L["CT_MailMod/SELECT_MESSAGE_TIP2"] = [=[|c0080A0FF左键:|r 选择或取消选择单个

|c0080A0FFAlt+左键:|r 选择相似的主题
|c0080A0FFAlt+右键:|r 取消选择相似的主题

|c0080A0FFCtrl+左键:|r 选择相同发件人
|c0080A0FFCtrl+右键:|r 取消选择相同发件人

|c0080A0FFShift+左键:|r 标记范围的开始
|c0080A0FFShift+左键:|r 结束范围并选择邮件
|c0080A0FFShift+右键:|r 结束范围并取消选择邮件]=]
L["CT_MailMod/Send/AutoComplete/Heading"] = "自动完成设置"
L["CT_MailMod/Send/AutoComplete/Tip"] = "选择向下箭头以更改过滤器"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_COPPER"] = "%d 铜"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_GOLD"] = "%d 金 %d 银 %d 铜"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_SILVER"] = "%d 银 %d 铜"
L["CT_MailMod/STOP_SELECTED"] = "取消"
L["CT_MailMod/Options/Bags/CloseAllCheckButton"] = "关闭所有背包"
L["CT_MailMod/Options/Bags/CloseLabel"] = "邮箱关闭时:"
L["CT_MailMod/Options/Bags/Heading"] = "背包清单"
L["CT_MailMod/Options/Bags/Line1"] = "要与其他背包管理插件兼容，可能需要禁用这些选项"
L["CT_MailMod/Options/Bags/OpenAllCheckButton"] = "打开所有背包"
L["CT_MailMod/Options/Bags/OpenBackpackCheckButton"] = "打开背包"
L["CT_MailMod/Options/Bags/OpenLabel"] = "邮箱打开时:"
L["CT_MailMod/Options/General/BlockTradesCheckButton"] = "使用邮箱时阻止交易"
L["CT_MailMod/Options/General/Heading"] = "常规选项"
L["CT_MailMod/Options/General/NetIncomeCheckButton"] = "在邮箱关闭时显示净收入"
L["CT_MailMod/Options/Inbox/Checkboxes/Heading"] = "消息复选框"
L["CT_MailMod/Options/Inbox/Checkboxes/Line1"] = "将鼠标悬停在 '?' 上显示有关其他信息"
L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewCheckButton"] = "按住Shift并单击范围时清除选择"
L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewTip"] = [=[按住Shift两次单击以选择范围, 
或通过再次右击鼠标来移除范围. 

这样做时，此选项会清除先前的选择.]=]
L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewCheckButton"] = "按住Ctrl键单击发件人时清除选择"
L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewTip"] = [=[按住Shift键单击以选择来自同一发件人的所有邮件; 
或Shift右键单击以选择来自其他发件人的所有消息. 

此选项会清除之前的先前选择.]=]
L["CT_MailMod/Options/Inbox/Checkboxes/ShowCheckboxesCheckButton"] = "显示复选框和打开/关闭按钮"
L["CT_MailMod/Options/Inbox/Checkboxes/ShowNumbersCheckButton"] = "显示消息数量"
L["CT_MailMod/Options/Inbox/Heading"] = "收件箱"
L["CT_MailMod/Options/Inbox/HideLogCheckButton"] = "|cFFFF9999隐藏|r'邮件日志' 按钮"
L["CT_MailMod/Options/Inbox/MouseWheelCheckButton"] = "启用鼠标滚轮滚动"
L["CT_MailMod/Options/Inbox/MultipleItemsCheckButton"] = "在消息鼠标提示中显示所有附件"
L["CT_MailMod/Options/Inbox/SelectMsgCheckButton"] = "显示消息复选框的鼠标提示"
L["CT_MailMod/Options/Inbox/ShowExpiryCheckButton"] = "显示消息到期按钮"
L["CT_MailMod/Options/Inbox/ShowInboxCheckButton"] = "在收件箱中显示消息数"
L["CT_MailMod/Options/Inbox/ShowLongCheckButton"] = "两行显示较长的主题"
L["CT_MailMod/Options/Inbox/ShowMailboxCheckButton"] = "显示收件箱中未显示的消息数"
L["CT_MailMod/Options/MailLog/BackgroundLabel"] = "背景颜色"
L["CT_MailMod/Options/MailLog/Delete/Button"] = "删除日志"
L["CT_MailMod/Options/MailLog/Delete/ConfirmationCheckButton"] = "我想删除所有日志条目"
L["CT_MailMod/Options/MailLog/Delete/Heading"] = "删除日志条目"
L["CT_MailMod/Options/MailLog/Heading"] = "邮件日志"
L["CT_MailMod/Options/MailLog/LogDeletedButton"] = "记录已删除的邮件"
L["CT_MailMod/Options/MailLog/LogOpennedCheckButton"] = "记录打开的邮件"
L["CT_MailMod/Options/MailLog/LogReturnedCheckButton"] = "记录退回的邮件"
L["CT_MailMod/Options/MailLog/LogSentCheckButton"] = "记录发送邮件"
L["CT_MailMod/Options/MailLog/PrintCheckButton"] = "打印日志消息到聊天"
L["CT_MailMod/Options/MailLog/SaveCheckButton"] = "将日志消息保存在邮件日志中"
L["CT_MailMod/Options/MailLog/ScaleSliderLabel"] = "邮件日志规模 = <value>"
L["CT_MailMod/Options/MailLog/Tip"] = [=[键入/maillog 查看发送/接收的每个信件的日志.

通过拖动日志的左边缘或右边缘或使用下面的缩放滑块将其放大或缩小来调整日志大小]=]
L["CT_MailMod/Options/Reset/Heading"] = "重置设置"
L["CT_MailMod/Options/Reset/Line 1"] = "注意: 这会将选项重置为默认值然后重新加载UI."
L["CT_MailMod/Options/Reset/ResetAllCheckbox"] = "重置所有角色的选项"
L["CT_MailMod/Options/Reset/ResetButton"] = "重置设置"
L["CT_MailMod/Options/SendMail/AltClickCheckButton"] = "Alt左键单击将物品添加到发送邮件"
L["CT_MailMod/Options/SendMail/FilterAutoCompleteCheckButton"] = "自动完成筛选发送到字段"
L["CT_MailMod/Options/SendMail/FilterAutoCompleteTip"] = "启用后, 单击收件人字段旁边的按钮进行筛选:"
L["CT_MailMod/Options/SendMail/Heading"] = "发送邮件"
L["CT_MailMod/Options/SendMail/ProtectEditFocusCheckButton"] = "防止邮箱失去键盘焦点"
L["CT_MailMod/Options/SendMail/ProtectEditFocusTip"] = "单击后将键盘光标返回到邮箱：-背包和行李槽-邮件附件槽-货到付款或汇款按钮"
L["CT_MailMod/Options/SendMail/ReplaceSubjectCheckButton"] = "用金额替换空白主题"
L["CT_MailMod/Options/Tips/Heading"] = "提示"
L["CT_MailMod/Options/Tips/Line1"] = "你可以键入 /ctmail 或 /ctmailmod 直接打开设置窗口."


end