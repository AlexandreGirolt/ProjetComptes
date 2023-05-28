#!/bin/bash

#Récupération des variables pour envoi du mail
server="$1"
mail_login="$2"
mail_password="$3"
mail_port="$4"

########################################################################
###  Création des comptes et architecture de fichiers + envoi mails  ###
########################################################################

#supression des dosssiers pour relancer le script
sudo rmdir /home/shared

#création du dossier shared
sudo mkdir /home/shared
sudo chmod 755 /home/shared
sudo chown root /home/shared


tail -n +2 "accounts.csv" | while IFS=';' read -r name surname mail password
do
	#création du login avec la première lettre du prénom et le nom de famille
	surname=$(echo "$surname" | sed 's/ //g')
	login="${name:0:1}${surname}"
	
	#Suppression compte pour relancer le script
	sudo userdel "$login"
	sudo rm -rf "/home/$login"
	
	#création du compte du l'utilisateur
	sudo useradd -m -d "/home/$login" -s /bin/bash "$login"
    echo "$login:$password" | sudo chpasswd
	sudo chage -d 0 "$login"
	
	#création du dosssier a_sauver de l'utilisateur
	sudo mkdir "/home/$login/a_sauver"
    sudo chown "$login" "/home/$login/a_sauver"
	
	#création du dossier de l'utilisateur dans le dossier shared
	sudo mkdir "/home/shared/$login"
    sudo chown "$login" "/home/shared/$login"
    sudo chmod 755 "/home/shared/$login"
	
	#envoi du mail
	ssh agirol25@10.30.48.100 "mail --subject \"Création de votre compte\" --exec \"set sendmail=smtp://${mail_login/@/%40}:mail_password@$server:$mail_port\" --append \"From:$mail_login\" $mail <<< \"Votre compte à été créé avec succès! Voici vos identifiants : \nMail : $mail\nPassword : $password\nUne fois connecté(e) avec ce mot de passe, il vous sera demandé d'en choisir un nouveau.\""

done