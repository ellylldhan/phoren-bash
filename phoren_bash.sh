#! /usr/bin/env bash
# Renomme et rotate image selon leur métadata
#
# DEPENDANCES: jhead exiftran 
#
# CHANGELOG
# ---------
# todo: revoir logging des etapes
# 2022-31-12 Nouveau repo juste pour version BASH
# 2022-11-25 Réécriture "propre" en vue publication gitlab
# 2022-06-23 Passage en bash
# 2022-03-28 Fix historique
# 2021-03-13 Rafraîchissement
# 2019-02-12 Nouveau départ
#
# -----------------------------
# CODES EXIT
#    0 : OK
#    1 : Pas assez d'argument
#    2 : Trop d'arguments
#    3 : Mauvais argument(s)
#    4 : Extension non supportée
#    5 : Dépendances manquantes
#    6 : Argument 1 n'est pas un dossier
#    7 : Action annulée
#    8 : Aucun fichier trouvé avec extension(s) donnée(s)
# -----------------------------


#########################
#   V A R I A B L E S   #
#########################

# Déclaration de constantes
declare -r rouge='\e[31m'
declare -r orange='\e[33m'
declare -r greengras='\e[1;32m'
declare -r reset='\e[0m'
declare -r gras='\e[1m'
declare -r redgras='\e[1;31m'
declare -r orangegras='\e[1;33m'

# Variables locales
DESCR="Renomme et oriente (rotation) des fichiers images en fonction de leur métadata."
VERSION="2022.12.31"
USAGE="""
${gras}NOM${reset}
	${gras}phoren2${reset} version ${gras}${VERSION}${reset} (phoren3)

${gras}DESCRIPTION${reset}
	${DESCR}

${gras}USAGE${reset}
	\$ ${greengras}$0 /chemin/vers/dossier/origine \$EXTENSION${reset}

${gras}OPTIONS${reset}
	-u, --usage    Affiche ce message
	-h, --help     Affiche l'aide
	-d, --descr    Affiche la description de ce script
	-v, --version  Affiche le nom et la version du script

${gras}EXEMPLES${reset}
	\$ phoren . jpg 
	\$ phoren /mnt/sdcard-420/DCIM JPG
	\$ phoren '/c/Users/Moi/Mes Photos/Vacances 2023' jpg

${redgras}DEPENDANCES${reset}
	${gras}exiftran${reset}   Transformation d'image JPEG d'Appareil Photo Numérique (APN)
	${gras}jhead${reset}      Manipulation de la partie non image des fichiers JPEG conformes à EXIF

${gras}REMARQUES${reset}
	- nom d'extension sans point en préfixe (ex. ${gras}JPG${reset} et non pas ${gras}.JPG${reset})
	- nom d'extension est sensible à la casse (ex. ${gras}JPG${reset} != ${gras}jpg${reset})
"""

# Usage version courte
HELP="""
${gras}USAGE${reset}
	Renomme et réoriente un fichier jpg selon ses métadata. 
	Voir '$0 --usage' pour plus d'infos.

	\$ phoren2 '/chemin/vers/dossier' \$extension_sans_point

${gras}EXEMPLES${reset}
	\$ phoren . jpg 
	\$ phoren /mnt/243-433/DCIM JPG
	\$ phoren '/c/Users/Moi/Mes Photos/Vacances 2023' jpg

${gras}PREREQUIS ${reset}
	${gras}jhead exiftran${reset}
"""


#########################
#   F O N C T I O N S   #
#########################

showOptions () {
	# Permet de gérer les options d'aide
	case "$1" in 
		"--usage" | "-u" )
			echo -e "$USAGE"
			exit 0
			;;
		"--help"|"-h")
			echo "$HELP"
			exit 0
			;;
		"--descr" | "-d" )
			echo "$0\n$DESCR"
			exit 0
			;;
		"--version" | "-v" )
			echo "$0 version $VERSION"
			exit 0
			;;
		*)
			echo -e "${gras}${red}ERREUR Pas assez d'arguments. 2 arguments attendus, $# donné(s).${reset}"
			echo -e "$HELP"
			exit 1
			;; 
	esac
}


# Pour tester
setupTest() {
	for ((i=0;i<6;i++)); do
		touch pic${i}.jpg 
	done
}

process() { 
	sourceDir="$1"
	extension="$2"
	now=$(date +"%F_%H%M%S")
	logfile_historique="${sourceDir}/phoren_log_historique_${now}.log"
	logfile_antidote="${sourceDir}/phoren_log_antidote_${now}.log"
	logfile_errors="${sourceDir}/phoren_log_erreurs.log"

	# backup 
	ls -li "${sourceDir}"/*.${extension} >> $logfile_historique 2>/dev/null 

	# Check présence fichier 
	count=$(cat $logfile_historique | wc -l)

	if [[ $count -lt 1 ]]; then
		echo -e "${redgras}Aucun fichier n'a été trouvé portant l'extension donnée (${extension})${reset}"
		rm $logfile_historique
		exit 8
	fi 

	echo "RUN DU $now " > ${logfile_errors}
	echo "------------------------" >> ${logfile_errors}
	
	for f in "${sourceDir}"/*.${extension}; do
		exiftran -ai "$f"

		camera_model=$(jhead -exonly "$f" 2>>$logfile_errors | grep -i "camera model" | cut -c16-)
		resolution=$(jhead -exonly "$f" 2>>$logfile_errors | grep -i "resolution" | cut -c16- | sed 's/\ x\ /x/g')
		date_time=$(jhead -exonly "$f" 2>>$logfile_errors |grep -i "date/time" | cut -c16- | sed 's/\ x\ /x/g')

		[[ -z $camera_model ]] && camera_model='model'
		[[ -z $resolution ]] && resolution="resolution"
		[[ -z $date_time ]] && date_time="datetime"

		jhead -exonly -n"%Y-%m-%d_%H%M%S_${resolution}_${camera_model}" "$f" 2>>$logfile_errors 1>>"$logfile_historique" ;
	done

	# Antidote 
	sort -r < $logfile_historique >> $logfile_antidote
}

check_dependances() {
	# Check présence des dépendances
	count_exiftran=$(dpkg-query -l exiftran | grep -c ^ii)   # si > 0 alors installé
	count_jhead=$(dpkg-query -l jhead | grep -c ^ii)         # si > 0 alors installé

	#DEBUG
	# echo "exiftran : " $count_exiftran
	# echo "jhead    : " $count_jhead

	msg='sudo apt install'
	if [[ $count_exiftran -lt 1 ]]; then
		echo "Merci d'installer le package exiftran"
		msg="$msg exiftran "
	fi
	if [[ $count_jhead -lt 1 ]]; then
		echo "Merci d'installer le package jhead"
		msg="$msg jhead "
	fi
	if [[ $count_jhead -lt 1 ]] || [[ $count_exiftran -lt 1 ]]; then 
		echo "$msg"
		exit 5
	fi
}

check_arguments() {
	# Garde-fou nombre d'arguments
	if [[ $# -lt 1 ]]; then
		echo -e "${redgras}ERREUR Pas assez d'arguments. 2 arguments attendus, $# donné(s).${reset}"
		echo -e "$HELP"
		exit 1
	elif [[ $# -eq 1 ]]; then	
		showOptions "$1"
	elif [[ $# -gt 2 ]]; then 
		echo -e "${redgras}ERREUR Trop d'arguments. 2 arguments attendus, $# donné(s).${reset}"
		echo -e "$HELP"
		exit 2
	fi
}


#########################
#   M A I N             #
#########################

main() {
	# Check dépendances
	check_dependances

	# Check arguments
	check_arguments $*

	# It's a-go !
	sourceDir="$1"
	extension="$2"

	# Check si $1 est un dossier, sinon exit
	# if [[ ! -d "$sourceDir"]]; then
	# 	echo "${redgras}ERREUR: L'argument 1 n'est pas trouvable ou n'est pas un répertoire.${reset}"
	# 	echo -e "$HELP"
	# 	exit 6
	# fi

	# Check si $1 est un dossier, sinon exit
	if [[ ! -d "$sourceDir" ]]; then
		echo -e "${redgras}ERREUR: L'argument 1 n'est pas trouvable ou n'est pas un répertoire.${reset}"
		echo "Choix courants :"
		echo "----------------"
		echo "    1. Utiliser le répertoire courant '.'"
		echo "    2. Afficher l'aide"
		echo "    3. Annuler"
		read -p "Votre choix : " choix 

		case $choix in 
			1) 
				sourceDir='.' 
				;;
			2) 
				echo -e "$HELP" 
				exit 6 
				;;
			3)
				echo -e "${redgras}Action annulée${reset}"
				exit 7
				;;
			*) 
				echo -e "${redgras}Comprend pas ce choix. Action annulée${reset}"
				exit 7
				;;
		esac 
	fi

	# Check si $2 est vide, si oui propose des choix ou exit
	if [[ -z "$2" ]]; then 
		echo -e "${orangegras}WARNING: Merci d'indiquer une extension.${reset}"
		echo "Choix courants :"
		echo "----------------"
		echo "   1. JPG / jpg"
		echo "   2. PNG / png"
		echo "   3. Annuler"
		read -p "Votre choix" choix 

		case $choix in 
			1) 
				extension="{JPG,jpg}"
				;;
			2)
				extension="{PNG,png}"
				;;
			*)
				echo -e "${redgras}Action annulée${reset}"
				exit 7
				;;
		esac
	fi 

	# Process
	echo "... Processing" 
	process "$sourceDir" "$extension"

	echo "... Fin du script ..."
}


#########################
#   B O D Y             #
#########################

main $*