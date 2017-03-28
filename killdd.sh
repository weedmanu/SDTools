#!/bin/bash

# boucle infinie
while true
do
    sleep 2
    zen=`pidof zenity`  
    DD=`pidof dd`   
    if  [ -z "$zen" ]           # si zenity est fermé  alors :
    then
        if  [ "$DD" == "" ]  #  si la copie n'est pas en cours on sort de la boucle et le programme se ferme ( c'est que SDTools est fini )
        then
            break					 
        else                        # si la  copie est en cours ( c'est que vous avez annulé pendant la copie ), on tue le processus de copie et informe d'attendre le prochain pop up pour l'enlever 
            kill  -s 9 ${DD}
            zenity --info --timeout=8 --title "SD tools" --width=600 --text "

    <span color=\"red\"><b><big>Vous avez annulé !!!  </big></b></span>

<span color=\"black\"><b><big>Veuillez patientez avant d'enlever la clé ....</big></b></span>

<span color=\"red\"><b><big>Vous serez averti par un autre pop-up quand vous pourrez le faire ....</big></b></span>

                    " 2>/dev/null
            rm format.log instal-sauv.log sd.log     # on supprime les logs
            break														# on sort de la boucle et le programme se ferme
        fi          
    fi
done
exit
