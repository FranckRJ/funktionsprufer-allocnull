#!/bin/bash

#Desactivation du globbing etc etc
set -f

internalProjectDir='project'
externalProjectDir=''
tmpfileName='tmpfile.txt'
baseAllocFile='base_alloc_null.c'
realAllocFile='alloc_null.c'

function print_help
{
read -r -d '' HELP_TEXT << EOM
DESCRIPTION :
./init_alloc.sh <chemin_vers_projet>

Copie l'integralite du projet dans le dossier « $internalProjectDir » en remplacant tous les malloc
par une version custom qui peut retourner NULL. Tous les Makefiles seront modifies pour ajouter
les fichiers necessaires, si une erreur se produit durant la compilation veuillez corriger
les Makefiles en ajoutant manuellement le fichier « $realAllocFile » dans les dependances.

Lors de l'execution du programme le seed utilise sera affiche sur la sortie d'erreur lors du
premier malloc.

Pour configurer le malloc_null modifiez les defines du fichier alloc_null.h, une recompilation
complete du projet est necessaire pour toutes modifications du fichier.

LISTE DES DEFINES CONFIGURABLES :
PERCENT_CHANCE_FAIL     Le pourcentage de chance qu'un malloc a de rater.
CUSTOM_SEED             Le seed a utiliser pour la generation de nombre aleatoire, si 0 il vaudra
                        le retour de la fonction « time(NULL) ».
EOM

echo "$HELP_TEXT"
}

function add_include_c_files
{
	find "$internalProjectDir" -name "*.c" -print0 |
	while IFS= read -r -d $'\0' thisFile; do
		echo \
"#include \"$PWD/alloc_null.h\"
#define malloc(n) malloc_null(n)" | cat - "$thisFile" > "$tmpfileName" && mv "$tmpfileName" "$thisFile"
	done
	echo "#include \"$PWD/alloc_null.h\"" | cat - "$baseAllocFile" > "$tmpfileName" && mv "$tmpfileName" "$realAllocFile"
}

function cp_alloc_null_c_everywhere
{
	find "$internalProjectDir" -type d -print0 |
	while IFS= read -r -d $'\0' thisDir; do
		cp "$realAllocFile" "$thisDir/"
	done
}

function add_alloc_null_to_makefile
{
	find "$internalProjectDir" -name "Makefile" -print0 |
	while IFS= read -r -d $'\0' thisFile; do
		cat "$thisFile" | sed '1,/\.c/ s/\.c/.c alloc_null.c/' > "$tmpfileName"
		mv "$tmpfileName" "$thisFile"
	done
}

for param in "$@"; do
	if [[ "$param" =~ ^-.* ]]; then
		print_help
		exit 0
	elif [[ -z "$externalProjectDir" ]]; then
		externalProjectDir="$param"
	else
		echo "Trop d'arguments, le chemin du projet ne peut etre initialise qu'une fois."
		exit 1
	fi
done

if [[ -z "$externalProjectDir" ]]; then
	echo "Le chemin du projet doit etre initialise."
	exit 1
else
	rm -rf "$internalProjectDir"
	cp -R "$externalProjectDir" "$internalProjectDir"
	add_include_c_files
	cp_alloc_null_c_everywhere
	add_alloc_null_to_makefile
	echo "Vous pouvez compiler le projet (dossier ${internalProjectDir}) et le lancer, il utilisera le malloc custom."
	exit 0
fi
