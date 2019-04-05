#!/bin/bash

#Desactivation du globbing etc etc
set -f

internalProjectDir='project'
externalProjectDir=''
tmpfileName='tmpfile.txt'
baseAllocFile='base_alloc_null.c'
realAllocFile='alloc_null.c'

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
	if [[ -z "$externalProjectDir" ]]; then
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
	echo "Pour terminer l'initialisation vous devez ajouter $realAllocFile a TOUS les Makefiles."
	exit 0
fi
