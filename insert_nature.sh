#!/usr/bin/env bash

greenbold="\033[1;32m"
green="\033[0;32m"
bold="\033[1m"
#bold_under="\033[1;4m"
underline="\033[4m"
reset="\033[0m"

database="nature.db"
ScriptDir="$(cd "$(dirname "$0")" && pwd)"
SRC="$ScriptDir/Nature"

if [ ! -d "$SRC" ]; then
	echo -e "\033[1;31mNature/ directory not found: $SRC\033[0m"
	exit 1
fi

if [ ! -f "$ScriptDir/$database" ]; then
	cmd0="CREATE TABLE liste (Francais string, Fra string, Autres string, Aut string, Male string, Femelle string, Jeune string, Others string, Latin string, Anglais string, Male_en string, Femelle_en string, Jeune_en string, Ordre string, Famille string, Liens string, Divers string, UNIQUE(Francais));"

	echo "$cmd0" | sqlite3 "$ScriptDir/$database"

	if [ $? -ne 0 ]; then exit 0; fi
fi


#files=()

j=0

for FILE in "$SRC"/*.csv
do
	x=$(basename "${FILE}")
	echo -e "\nInserting data from file ${underline}$x${reset} into database ${bold}$database${reset}...\n"
	#files+=("${FILE}")

	if [[ "$FILE" == *Insectes* ]]; then
		typ="Insecte,Insect"
	elif [[ "$FILE" == *Mammiferes* ]]; then
		typ="Mammifère,Mammal"
	elif [[ "$FILE" == *Oiseaux* ]]; then
		typ="Oiseau,Bird"
	elif [[ "$FILE" == *Plantes* ]]; then
		typ="Plante,Plant"
	else
		echo -e "\033[1;31mUnknown type for file $x, skipping.\033[0m"
		continue
	fi

	i=0
	skip_headers=1

	# the .csv separator must be a ;
	# only LibreOffice or Apple Number allow this (Excel forces the , as separator)

	while IFS=';' read -ra array;
	do
	   if ((skip_headers)); then   # Skip the header row
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
            #echo "$fr"
            fr_wa=$(echo "$fr_wa" | sed "s/'/''/g")
            aut=$(echo "$aut" | sed "s/'/''/g")
            aut_wa=$(echo "$aut_wa" | sed "s/'/''/g")

            male=$(echo "$male" | sed "s/'/''/g")
            femelle=$(echo "$femelle" | sed "s/'/''/g")
            jeune=$(echo "$jeune" | sed "s/'/''/g")

            others=$(echo "$others" | sed "s/'/''/g")
            #echo "$others"
            english=$(echo "$english" | sed "s/'/''/g")

            ordre=$(echo "$ordre" | sed "s/'/''/g")
            famille=$(echo "$famille" | sed "s/'/''/g")
            latin=$(echo "$latin" | sed "s/'/''/g")
            lien=$(echo "$lien" | sed "s/'/''/g")
            male_en=$(echo "$male_en" | sed "s/'/''/g")
            femelle_en=$(echo "$femelle_en" | sed "s/'/''/g")
            jeune_en=$(echo "$jeune_en" | sed "s/'/''/g")

            #echo "$lien"
            #echo "$typ"

            cmd1="INSERT OR REPLACE INTO liste (Francais, Fra, Autres, Aut, Male, Femelle, Jeune, Others, Latin, Anglais, Male_en, Femelle_en, Jeune_en, Ordre, Famille, Liens, Divers) VALUES ('$fr','$fr_wa','$aut','$aut_wa','$male','$femelle','$jeune','$others','$latin','$english','$male_en','$femelle_en','$jeune_en','$ordre','$famille','$lien','$typ');"

            #echo "$cmd1"
            echo "$cmd1" | sqlite3 "$ScriptDir/$database"
            if [ ! $? -eq 0 ]; then
  				echo "$cmd1" >> "$ScriptDir/errors.txt"
  				echo "" >> "$ScriptDir/errors.txt"
  			else
				((i++))
  			fi

			#echo "-------"
		fi


	done < <(grep "" "${FILE}")    # reads the last line even when it has no trailing newline

	echo -e "${green}Insert $i lines from ${FILE}${reset}\n"
	j=$((j+i))

done

echo -e "\n${greenbold}$j lines inserted in database $database ${reset}\n"
