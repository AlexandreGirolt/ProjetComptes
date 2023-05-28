#!/bin/bash

#Récupération des variables pour envoi du mail
server="$1"
mail_login="$2"
mail_password="$3"
mail_port="$4"

########################################################################
###  Création des comptes et architecture de fichiers + envoi mails  ###
########################################################################

#création du dossier shared
sudo mkdir /home/shared
sudo chmod 755 /home/shared
sudo chown root /home/shared


tail -n +2 "accounts.csv" | while IFS=';' read -r name surname mail password
do
	#création du login avec la première lettre du prénom et le nom de famille
	surname=$(echo "$surname" | sed 's/ //g')
	login="${name:0:1}${surname}"
	
	
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


########################################################################
#############################  Sauvegarde  #############################
########################################################################

#Création du dossier saves sur la machine distante
ssh agirol25@10.30.48.100 "sudo mkdir /home/saves"
ssh agirol25@10.30.48.100 "sudo chmod 766 \"/home/saves\""

tail -n +2 "accounts.csv" | while IFS=';' read -r name surname mail password
do
	#création du login avec la première lettre du prénom et le nom de famille
	surname=$(echo "$surname" | sed 's/ //g')
	login="${name:0:1}${surname}"

	#Compression du contenu de a_sauver et envoie sur la machine distante
	tar -zcf "/tmp/save_${login}.tgz" -C "/home/a_sauver"
	scp "/tmp/save_${login}.tgz" "agirol25@10.30.48.100:home/saves/save_${login}.tgz"


	#Création programme retablir_sauvegarde
	echo "#!/bin/bash" > "/home/retablir_sauvegarde"
	echo "cd /home/a_sauver" >> "/home/retablir_sauvegarde"
	echo "wget /home/saves/${login}/save_${login}.tgz" >> "/home/retablir_sauvegarde"
	echo "tar -zxf save_${login}.tgz -C . --strip-components=1" >> "/home/retablir_sauvegarde"
	chmod +x "/home/retablir_sauvegarde"


########################################################################
#######################  Installation Eclipse  #########################
########################################################################

apt install snapd -y
ln -s /var/lib/snapd/snap /snap
snap refresh
snap install --classic eclipse


########################################################################
#############################  Pare feu  ###############################
########################################################################

iptables -A INPUT -p tcp --dport 21 -j DROP
iptables -A OUTPUT -p tcp --dport 21 -j DROP
iptables -A INPUT -p udp -j DROP
iptables -A OUTPUT -p udp -j DROP
iptables-save > /etc/iptables/rules.v4


