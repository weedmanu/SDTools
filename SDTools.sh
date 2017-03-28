#!/bin/bash

killeur()
{
PID_ZENITY=${!}

PID_CHILD=$(pgrep -o -P $$)

while [ "$PID_ZENITY" != "" ]
do
  PID_TASKS=$(pgrep -d ' ' -P ${PID_CHILD})
  PID_ZENITY=$(ps h -o pid --pid ${PID_ZENITY} | xargs)
  sleep 1
done
[ "${PID_TASKS}" != "" ] && kill -9 ${PID_TASKS}

(
fichier=`cat instal-sauv.log`
while [ -s $fichier ]
do	
	fichier=`cat instal-sauv.log`		 	
done 
) | zenity --title="SD tools" --progress --pulsate --width=400 --text="
					<span color=\"red\"><b><big>arrêt en cours</big></b></span>
<span color=\"blue\">veuillez patienter...</span>" --auto-close 2>/dev/null  

zenity --info --title "SD tools" --width=400 --text "

	<span color=\"red\"><b><big>Vous pouvez débrancher la carte SD </big></b></span>

" 2>/dev/null
}

exec &> sd.log
zenity --info --timeout=20 --title "SD tools" --width=400 --text "

<span color=\"red\"><b><big> Veuillez brancher votre carte SD </big></b></span>

<span color=\"blue\">Puis valider</span> <span color=\"green\">sdd</span>" 2>/dev/null


sudo fdisk -l | sed -n '/Disque \/dev\/sd/p' > /tmp/test.txt
tout=`sed '' /tmp/test.txt`

sudo fdisk -l | sed -n '/Disque \/dev\/sd/p' | sed -n '$ p' > /tmp/test.txt
cle=`cut -c 13-15 /tmp/test.txt`

rm /tmp/test.txt

exec &> sd.log
zenity --info --timeout=20 --title "SD tools" --width=400 --text "
<span color=\"blue\">Pour vérifier le nom de votre carte sd :  </span>	
<span color=\"red\"><b><big> sudo fdisk -l </big></b></span>
${tout}

<span color=\"blue\">En bas de liste logiquement, par ex:</span> <span color=\"green\">sdd</span>" 2>/dev/null

SD=$(zenity --title "SD tools" --entry --width=400 --text 'C est bien e nom de la carte sd ?  ' --entry-text ${cle} 2>/dev/null )
exitstatus=$?
if [ $exitstatus = 0 ]; then
	umount /dev/${SD}* 
	zenity --text-info --filename=sd.log --width=400 --height=300  --timeout=4 2>/dev/null	
	rm sd.log
else
	zenity --info --title "SD tools" --width=400 --text "<span color=\"red\"><b><big>Vous avez annulé</big></b></span>" 2>/dev/null
	exit
fi
CHEM=$(zenity --title "SD tools" --entry --width=400 --text "Chemin du dossier où se trouve les images de Raspbian " --entry-text "/home/manu/Documents/Raspi/" 2>/dev/null)
exitstatus=$?
if [ $exitstatus = 1 ]; then	
	zenity --info --title "SD tools" --width=400 --text "<span color=\"red\"><b><big>Vous avez annulé</big></b></span>" 2>/dev/null
	exit
fi	
exec &> instal-sauv.log
if (zenity --question --title "SD tools" --width=400 --text "Voulez-vous Installer Raspbian ou Sauvegarder votre carte SD ?" --ok-label="Installation" --cancel-label="Sauvegarde" 2>/dev/null); then  
	if (zenity --question --title "SD tools" --width=400 --text "Veux-tu formater la carte sd ?" --ok-label="Oui" --cancel-label="Non" 2>/dev/null); then					
		mkfs.vfat -n RASPI -F 32 -I /dev/${SD} > >(zenity --title "SD tools" --progress --pulsate --text "formatage de la carte sd en cours ... " --auto-close 2>/dev/null) >> format.log
		zenity --text-info --width=400 --height=300 --timeout=4 --filename=format.log	2>/dev/null	
		rm format.log
	else	
		zenity --info --title "SD tools" --width=400 --text "<span color=\"red\"><b><big>Vous avez annulé</big></b></span>" 2>/dev/null
		exit	
	fi		
	IMG=$(zenity  --list  --width=400 --text "Quelle image voulez vous installer ?" --radiolist  --column "Choix" --column "Images" TRUE raspi3ok FALSE raspbian 2>/dev/null )
	exitstatus=$?
	if [ $exitstatus = 0 ]; then		
		dd bs=4M if=${CHEM}${IMG}.img of=/dev/${SD} > >(zenity --title "SD tools" --progress --pulsate --text "Installation en cours patienter environ 5 à 10 minutes ..." --auto-close 2>/dev/null ) 
		killeur
	else
		zenity --info --title "SD tools" --width=400 --text "<span color=\"red\"><b><big>Vous avez annulé</big></b></span>" 2>/dev/null		
		exit		
	fi		
	zenity --text-info --width=400 --height=300 --timeout=4 --title='SD tools' --filename=instal-sauv.log 2>/dev/null
	zenity --info --width=400 --title='SD tools' --text="Voilà c'est terminé" 2>/dev/null	
	rm instal-sauv.log
else 
	NOM=$(zenity --entry --title "SD tools" --width=400 --text "donne un nom à cette image :" 2>/dev/null)	
	exitstatus=$?
	if [ $exitstatus = 0 ]; then	
		touch ${CHEM}${NOM}.img           
		dd bs=4M if=/dev/${SD} of=${CHEM}${NOM}.img > >(zenity --title "SD tools" --progress --pulsate --text "Sauvegarde en cours patienter environ 5 à 10 minutes ..." --auto-close 2>/dev/null & )	
		killeur
	else		
		zenity --info --title "SD tools" --width=400 --text "<span color=\"red\"><b><big>Vous avez annulé</big></b></span>" 2>/dev/null		
		exit
	fi		
	zenity --text-info --width=400 --height=300 --timeout=4 --title='SD tools' --filename=instal-sauv.log
	zenity --info --width=400 --title='SD tools' --text="Voilà c'est terminé" 2>/dev/null	
	rm instal-sauv.log
fi
exit 


