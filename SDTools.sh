#!/bin/bash

#fonction killeur qui sert a tuer le processus de la pulse bar quand la sauvegarde ou l'installation est terminée
# on sait qu'elle est terminé quand le fichier instal-sauv.log existe et n''est pas vide
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
PID_DD=`pidof dd`
until [ -e $PID_DD  ]
do
    kill  -s 9 $PID_DD
    sleep 1
    break
done

fichier=`cat instal-sauv.log`
while [ -s "$fichier" ]
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

# boite de dialogue intro
zenity --info --timeout=0 --title "SD tools" --width=400 --text "
<span color=\"blue\"><b><big>SDTools</big></b></span>
    <span color=\"green\" background=\"black\">Powered </span><span color=\"yellow\" background=\"black\">by</span><span color=\"red\" background=\"black\"> manu</span>


<b><big> Veuillez brancher votre carte SD </big></b>

<span color=\"blue\">Puis valider</span>" 2>/dev/null

# boite de dialogue qui demande le chemin du dossier où se trouve les images, vous pouvez changer le chemin par défaut  après --entry text
CHEM=$(zenity --title "SD tools" --entry --width=400 --text "Chemin du dossier où se trouve les images de Raspbian " --entry-text "/home/manu/Documents/Raspi/" 2>/dev/null)
exitstatus=$?
if [ $exitstatus = 1 ]; then    
    zenity --info --title "SD tools" --width=400 --text "<span color=\"red\"><b><big>Vous avez annulé</big></b></span>" 2>/dev/null
    exit
fi
cd ${CHEM}

# on lit le dossier courant et on met la liste des fichiers .img  dans une variable
i=0
for j in $(find *.img )
do 
  rep[$i]=$(basename $j)
  ((i++))
done

# on liste les disques branchés au pc et on place la liste dans une variable
fdisk -l | sed -n '/Disque \/dev\/sd/p' > /tmp/test.txt
tout=`sed '' /tmp/test.txt`

# on récupère que le nom (ex: sdd) du dernier disque branché au pc et on le place dans une variable
fdisk -l | sed -n '/Disque \/dev\/sd/p' | sed -n '$ p' > /tmp/test.txt
cle=`cut -c 13-15 /tmp/test.txt`

# on supprime le fichier tampon ( pas nécessaire car dans /tmp)
rm /tmp/test.txt

# boite de dialogue qui affiche la liste des disques du pc et propose le dernier monté comme clé a utiliser
zenity --info --timeout=0 --title "SD tools" --width=400 --text "
<span color=\"blue\">Voici la liste des disques :  </span>  
${tout}
<span color=\"blue\">votre clé est :</span> <span color=\"green\">${cle}</span>
<span color=\"red\">Sinon pas de panique, </span><span color=\"blue\">vous pouvez changer à l'étape suivante</span>" 2>/dev/null

# on détourne la sortie du shell dans un fichier sd.log pour pouvoir l'afficher dans une boite de dialogue 
exec &> sd.log
# boite de dialogue qui demande le nom de la clé à utiliser, avec par défaut le dernière branché au pc
# si c'est ok on demonte la clé pour pouvoir travailler dessus et affiche le résultat
SD=$(zenity --title "SD tools" --entry --width=400 --text 'C est bien le nom de la carte sd ?  ' --entry-text ${cle} 2>/dev/null )
exitstatus=$?
if [ $exitstatus = 0 ]; then
    umount /dev/${SD}* 
    zenity --text-info --filename=sd.log --width=400 --height=300  --timeout=4 2>/dev/null  
    rm sd.log
else
    zenity --info --title "SD tools" --width=400 --text "<span color=\"red\"><b><big>Vous avez annulé</big></b></span>" 2>/dev/null
    rm sd.log
    exit
fi

# on détourne la sortie du shell dans un fichier instal-sauv.log pour pouvoir l'afficher dans une boite de dialogue 
exec &> instal-sauv.log
 # boite de dialogue installation ou sauvegarde 
if (zenity --question --title "SD tools" --width=400 --text "Voulez-vous Installer Raspbian ou Sauvegarder votre carte SD ?" --ok-label="Installation" --cancel-label="Sauvegarde" 2>/dev/null); then
    # si installation choisi 1ere étape, on propose de formater, si le formatage pas nécessaire, on annule et passe a l'étape suivante
    if (zenity --question --title "SD tools" --width=400 --text "Veux-tu formater la carte sd ?" --ok-label="Oui" --cancel-label="Non" 2>/dev/null); then                   
        mkfs.vfat -n RASPI -F 32 -I /dev/${SD} > >(zenity --title "SD tools" --progress --pulsate --text "formatage de la carte sd en cours ... " --auto-close 2>/dev/null) >> format.log
        zenity --text-info --width=400 --height=300 --timeout=4 --filename=format.log   2>/dev/null 
        rm format.log
    else    
        zenity --info --title "SD tools" --width=400 --text "<span color=\"red\"><b><big>Ok, pas besoin de formater.</big></b></span>" 2>/dev/null      
    fi
    # si installation choisi 2eme étape, boite de dialogue quelle image installer ? avec la liste des images présentes dans le dossier où se trouve ce script.
    # une fois l'image choisie on lance la copie et quand c'est fini affiche le log
    IMG=$(zenity --list --title="Quelle image voulez vous installer ?" --column="image" ${rep[@]}   2>/dev/null )
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        ./killdd.sh &
        dd bs=4M if=${CHEM}${IMG} of=/dev/${SD} > >(zenity --title "SD tools" --progress --pulsate --text "Installation en cours patienter environ 5 à 10 minutes ..." --auto-close 2>/dev/null )      
        killeur
    else
        zenity --info --title "SD tools" --width=400 --text "<span color=\"red\"><b><big>Vous avez annulé</big></b></span>" 2>/dev/null                    
    fi      
    zenity --text-info --width=400 --height=300 --timeout=4 --title='SD tools' --filename=instal-sauv.log 2>/dev/null
    zenity --info --width=400 --title='SD tools' --text="Voilà c'est terminé" 2>/dev/null 
    rm instal-sauv.log
else
    # si sauvegarde choisi , on demande d'entrer un nom pour l'image que l'on va créer
    # on créer la sauvegarde  ( clone ) quand c'est fini affiche le log
    NOM=$(zenity --entry --title "SD tools" --width=400 --text "donne un nom à cette image :" 2>/dev/null) 
    exitstatus=$?
    if [ $exitstatus = 0 ]; then    
        touch ${CHEM}${NOM}.img
        ./killdd.sh &      
        dd bs=4M if=/dev/${SD} of=${CHEM}${NOM}.img > >(zenity --title "SD tools" --progress --pulsate --text "Sauvegarde en cours patienter environ 10 à 20 minutes ..." --auto-close 2>/dev/null )
        killeur
    else        
        zenity --info --title "SD tools" --width=400 --text "<span color=\"red\"><b><big>Vous avez annulé</big></b></span>" 2>/dev/null                    
    fi      
    zenity --text-info --width=400 --height=300 --timeout=4 --title='SD tools' --filename=instal-sauv.log   
    rm instal-sauv.log
    zenity --info --width=400 --title='SD tools' --text="Voilà c'est terminé" 2>/dev/null 
fi
exit 

