#!/usr/bin/env bash
# phoren2 - Renomme et oriente (rotation) des fichiers images en fonction de leurs métadonnées

set -euo pipefail

#########################
#   C O N S T A N T E S #
#########################
readonly VERSION="2025.06.06"
readonly DESCR="Renomme et oriente (rotation) les fichiers images selon leurs métadonnées."
readonly DEPENDANCES=(exiftran jhead)
readonly LOGDIR=".logs"

# Couleurs
rouge='\e[31m'
orange='\e[33m'
greengras='\e[1;32m'
reset='\e[0m'
gras='\e[1m'
redgras='\e[1;31m'
orangegras='\e[1;33m'

#########################
#   F O N C T I O N S   #
#########################

affiche_usage() {
	cat <<EOF
${gras}USAGE${reset}
  \$ ${greengras}$0 /chemin/vers/dossier extension${reset}

${gras}EXEMPLES${reset}
  \$ $0 . jpg
  \$ $0 /mnt/photos JPG

${gras}DEPENDANCES${reset}
  - exiftran
  - jhead
EOF
}

verifie_dependances() {
	local manquants=()
	for dep in "${DEPENDANCES[@]}"; do
		if ! command -v "$dep" &>/dev/null; then
			manquants+=("$dep")
		fi
	done
	if (( ${#manquants[@]} > 0 )); then
		echo -e "${redgras}Erreur : les dépendances suivantes sont manquantes : ${manquants[*]}${reset}"
		echo "Vous pouvez les installer avec : sudo apt install ${manquants[*]}"
		exit 5
	fi
}

prepare_logs() {
	mkdir -p "$1/$LOGDIR"
	NOW=$(date +"%F_%H%M%S")
	LOG_HISTO="$1/$LOGDIR/phoren_historique_$NOW.log"
	LOG_ERR="$1/$LOGDIR/phoren_erreurs_$NOW.log"
}

renomme_et_oriente() {
	local dir="$1"
	local ext="$2"
	local fichiers=("$dir"/*.$ext)

	if [[ ! -e "${fichiers[0]}" ]]; then
		echo -e "${redgras}Aucun fichier .$ext trouvé dans $dir${reset}"
		exit 8
	fi

	echo "Traitement de ${#fichiers[@]} fichiers..."
	echo "RUN $(date)" >> "$LOG_ERR"
	echo "---" >> "$LOG_ERR"

	for f in "${fichiers[@]}"; do
		exiftran -ai "$f"

		local camera_model resolution date_time
		camera_model=$(jhead -exonly "$f" 2>>"$LOG_ERR" | awk -F": " '/Camera model/{print $2}')
		resolution=$(jhead -exonly "$f" 2>>"$LOG_ERR" | awk -F": " '/Resolution/{print $2}' | sed 's/ x /x/g')
		date_time=$(jhead -exonly "$f" 2>>"$LOG_ERR" | awk -F": " '/Date\/Time/{print $2}' | tr ' :' '_')

		camera_model=${camera_model:-model}
		resolution=${resolution:-resolution}
		date_time=${date_time:-datetime}

		jhead -exonly -n"%Y-%m-%d_%H%M%S_${resolution}_${camera_model}" "$f" >> "$LOG_HISTO" 2>> "$LOG_ERR"
	done

	echo -e "${greengras}Traitement terminé. Logs dans $dir/$LOGDIR${reset}"
}

main() {
	if [[ $# -ne 2 ]]; then
		echo -e "${redgras}Erreur : 2 arguments attendus.${reset}"
		affiche_usage
		exit 1
	fi

	local dossier="$1"
	local ext="$2"

	if [[ ! -d "$dossier" ]]; then
		echo -e "${redgras}Erreur : '$dossier' n'est pas un répertoire.${reset}"
		exit 6
	fi

	verifie_dependances
	prepare_logs "$dossier"
	renomme_et_oriente "$dossier" "$ext"
}

main "$@"
