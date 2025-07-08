#!/usr/bin/env bash

red="\033[1;31m"
greenbold="\033[1;32m"
green="\033[0;32m"
yellow="\033[0;33m"
bold="\033[1m"
#bold_under="\033[1;4m"
underline="\033[4m"
reset="\033[0m"

database="nature.db"
SRC="$(pwd)/Nature"

if [ ! -f "./$database" ]; then
	cmd0="CREATE TABLE liste (Francais string, Fra string, Autres string, Aut string, Male string, Femelle string, Jeune string, Others string, Latin string, Anglais string, Male_en string, Femelle_en string, Jeune_en string, Ordre string, Famille string, Liens string, Divers string, UNIQUE(Francais));"

	echo "$cmd0" | sqlite3 "./$database"
	
	if [ $? -ne 0 ]; then exit 0; fi
fi


#files=()

for FILE in "$SRC"/*.csv
do
	x=$(basename "${FILE}")
	echo -e "\nInsertion des données du fichier ${underline}$x${reset} dans la base ${bold}$database${reset}...\n"
	#files+=("${FILE}")
	
	if [[ "$FILE" == *Insectes* ]]; then
		typ="Insecte,Insect"
	elif [[ "$FILE" == *Mammiferes* ]]; then
		typ="Mammifère,Mammal"
	elif [[ "$FILE" == *Oiseaux* ]]; then
		typ="Oiseau,Bird"
	elif [[ "$FILE" == *Plantes* ]]; then
		typ="Plante,Plant"
	fi
	
	skip_headers=1
	while IFS=';' read -ra array;
	do
	   if ((skip_headers)); then   # Ne pas lire le header
		((skip_headers--))
        else
        	
            fr="${array[0]}"
            fr_wa="${array[1]}"
            aut="${array[2]}"
            aut_wa="${array[3]}"
            male="${array[4]}"
            femelle="${array[5]}"
            jeune="${array[6]}"
            others="${array[7]}"
            latin="${array[8]}"
            english="${array[9]}"
            male_en="${array[10]}"
            femelle_en="${array[11]}"
            jeune_en="${array[12]}"
            ordre="${array[13]}"
            famille="${array[14]}"
            lien="${array[15]}"

            fr=$(echo "$fr" | sed "s/'/''/g")
            fr_wa=$(echo "$fr_wa" | sed "s/'/''/g")
            aut=$(echo "$aut" | sed "s/'/''/g")
            aut_wa=$(echo "$aut_wa" | sed "s/'/''/g")
            
            male=$(echo "$male" | sed "s/'/''/g")
            femelle=$(echo "$femelle" | sed "s/'/''/g")
            jeune=$(echo "$jeune" | sed "s/'/''/g")
            
            others=$(echo "$others" | sed "s/'/''/g")
            
            english=$(echo "$english" | sed "s/'/''/g")
            
            ordre=$(echo "$ordre" | sed "s/'/''/g")
            famille=$(echo "$famille" | sed "s/'/''/g")
            
            
            cmd1="INSERT OR REPLACE INTO liste (Francais, Fra, Autres, Aut, Male, Femelle, Jeune, Others, Latin, Anglais, Male_en, Femelle_en, Jeune_en, Ordre, Famille, Liens, Divers) VALUES ('$fr','$fr_wa','$aut','$aut_wa','$male','$femelle','$jeune','$others','$latin','$english','$male_en','$femelle_en','$jeune_en','$ordre','$famille','$lien','$typ');"
           
            #echo "$cmd1"
            echo "$cmd1" | sqlite3 "./$database"
		fi

	done < <(grep "" "${FILE}")    # lit la dernière ligne même si elle n'est pas vide

done


