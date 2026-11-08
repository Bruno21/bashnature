#!/usr/bin/env bash

VERSION="v1.0"

### Variables for self updating
ScriptArgs=( "$@" )
ScriptPath="$(readlink -f "$0")"
ScriptWorkDir="$(dirname "$ScriptPath")"

opt_male=false
opt_femelle=false
opt_jeune=false

red="\033[1;31m"
green="\033[0;32m"
yellow="\033[0;33m"
yellowbold="\033[1;33m"
bold="\033[1m"
italic="\033[3m"
reset="\033[0m"

# Get GITHUB_TOKEN from keychain with fnox
[[ -z "${GITHUB_TOKEN}" ]] && echo -e "${red}\nNo Github token found ! Could'nt get update from Github.'.${reset}\n"

dotenv () {
  set -a
  # shellcheck disable=SC1091
  [ -f "$ScriptWorkDir/.env" ] && . "$ScriptWorkDir/.env" || echo -e "${red}\nNo .env file found ! Could'nt get update from Github.'.${reset}\n"
  set +a
}

#dotenv # replaced by fnox

### ChangeNotes: 1.0	Ajout d'un champ recherche dans l'export HTML (Claude)
### ChangeNotes: 0.7	Débugage avec Claude
### ChangeNotes: 0.6.1	Update help
### ChangeNotes: 0.6	Replace .env file by fnox
### ChangeNotes: 0.5	First version.

Github="https://github.com/bruno21/bashnature"
# Public Repo:
#RawUrl="https://raw.githubusercontent.com/Bruno21/bashanimals/main/bashanimals.sh"
# Private Repo:
RawUrl="https://x-access-token:$GITHUB_TOKEN@raw.githubusercontent.com/Bruno21/bashnature/main/bashnature.sh"


echo -e "${yellowbold}Bashnature${reset} $VERSION\n"


### Help Function:
Help() {
  echo "Syntax:     bashnature.sh [OPTION]"
  echo "Example:    bashnature.sh -s renard"
  echo
  echo "Options:"
  echo "-s     -s <subject>, -s all."
  echo "-h     Print this Help."
  echo "-m     Display male name."
  echo "-f     Display female name."
  echo "-j     Display juvenile name."
  echo "-e     Export markdown."
  echo "-u     Prints current version and update (if available)."
  echo "-w     Export html."
}

req2() {
	option=$1

	case $option in
  	e) ext=".md";old_index="_" ;;
  	w) ext=".html";old_index="_" ;;
	esac

	f="bashnature$ext"
	if [ -f "./$f" ]; then
		rm "./$f"
	fi

    query2="SELECT Francais, Autres, Latin, Anglais, Ordre, Famille, Liens, Male, Femelle, Jeune, Fra FROM liste ORDER by Fra;"
    result2=$(sqlite3 "$ScriptWorkDir/nature.db" "$query2")

	index=()
	itemcount=0
    array=()
   	while IFS='|' read -ra array;
	do
	    fr="${array[0]}"
        aut="${array[1]}"

        lat="${array[2]}"
        en="${array[3]}"
        or="${array[4]}"
        fa="${array[5]}"
        ln="${array[6]}"

        ma="${array[7]}"
        fe="${array[8]}"
        je="${array[9]}"
        fra="${array[10]}"

        [[ $aut != "" ]] && z="($aut)" || z=""

        # Link label follows the target site, empty when there is no URL
        case "${ln// /}" in
        	"") linklabel="" ;;
        	*oiseaux.net*) linklabel="Oiseaux.net" ;;
        	*wikipedia*) linklabel="Wikipedia" ;;
        	*) linklabel="Web" ;;
        esac

        # Section letter comes from the accent-free name, so É entries sit under E
        firstletter="${fra:0:1}"
        if [ "$firstletter" != "$old_index" ]; then
        	index+=("$firstletter")
        	letterid="lettre-${#index[@]}"
        	newletter=true
        else
        	newletter=false
        fi

		if [ "$ext" = ".md" ]; then

        	# Letter heading with an explicit anchor, independent of the renderer's slug rules
        	if [ "$newletter" = true ]; then
        		mammiferes+="<a id='$letterid'></a>"'\n''\n'"## $firstletter"'\n''\n'
        	fi

        	mammiferes+="| $fr | $z |"'\n'
        	mammiferes+="|------------------------ | --------------------------|"'\n'
        	mammiferes+="| Vernaculaire | $lat |"'\n'
        	mammiferes+="| Anglais | $en |"'\n'
        	[ -n "$ma" ] && mammiferes+="| Male | $ma |"'\n'
        	[ -n "$fe" ] && mammiferes+="| Femelle | $fe |"'\n'
        	[ -n "$je" ] && mammiferes+="| Jeune | $je |"'\n'
        	mammiferes+="| Ordre | $or |"'\n'
        	mammiferes+="| Famille | $fa |"'\n'
        	[ -n "$linklabel" ] && mammiferes+="| Liens ($linklabel)<br />![](Transparent300px.png) | [$fr]($ln)<br />![](Transparent300px.png) |"'\n'
        	mammiferes+='\n'

        elif [ "$ext" = ".html" ]; then

        	# Link cell left empty when there is no URL
        	if [ -n "$linklabel" ]; then
        		linkcell="<a href='$ln'>$linklabel</a>"
        	else
        		linkcell=""
        	fi

        	# Third row: gendered names, symbols only shown when data exists
        	if [ -n "$ma$fe$je" ]; then
        		row3="<tr class='family'><td>"
        		[ -n "$ma" ] && row3+="♂ $ma"
        		row3+="</td><td>"
        		[ -n "$fe" ] && row3+="♀ $fe"
        		row3+="</td><td>"
        		[ -n "$je" ] && row3+="⚥ $je"
        		row3+="</td><td></td></tr>"
        	else
        		row3="<tr class='family'><td colspan='4'></td></tr>"
        	fi

        	# Anchor on the first item of each letter, targeted by the index links
        	if [ "$newletter" = true ]; then
        		#anchor="<a href='#$firstletter'></a>"
        		anchor="<a id='$firstletter'></a>"
        	else
        		anchor=""
        	fi

        	bird+="<tbody class='item'>"
        	bird+="<tr class='bird'><td class='bold'>$anchor$fr</td><td>$aut</td><td>$lat</td><td>$en</td></tr>"
        	bird+="<tr class='family'><td>$or</td><td>$fa</td><td></td><td>$linkcell</tr>"
        	bird+="$row3"
        	bird+="</tbody>"

        	# Index bar repeated every 25 items
        	itemcount=$((itemcount+1))
        	if [ $((itemcount % 25)) -eq 0 ]; then
        		bird+="<tr class='family textcenter'><td colspan='4'>PLACEHOLDER</td></tr>"
        	fi

        fi

        old_index="$firstletter"

    done <<< "$result2"

    if [ "$ext" = ".html" ]; then
    	newArr=(); while IFS= read -r -d '' x; do newArr+=("$x"); done < <(printf "%s\0" "${index[@]}" | sort -uz)

    	for val in "${!newArr[@]}"  # for val in ${!newArr[@]}
    	do
    		liens_index+="<a href='#${newArr[$val]}'>${newArr[$val]}</a> | "
    	done
		liens_index="${liens_index:0:-3}"
		z=${bird//PLACEHOLDER/$liens_index}
		mammiferes="$z"

    	html
    elif [ "$ext" = ".md" ]; then

    	echo -e "${yellow}Exporting markdown file ${italic}$ScriptWorkDir/bashnature$ext !${reset}"

    	for val in "${!index[@]}"
    	do
    		md_index+="[${index[$val]}](#lettre-$((val+1))) | "
    	done
    	md_index="${md_index:0:-3}"

    	echo -e "# Liste nature"'\n''\n'"$md_index"'\n''\n'"$mammiferes" > "bashnature$ext"
    fi

    exit 0
    }

html() {

echo -e "${yellow}Exporting html file ${italic}$ScriptWorkDir/bashnature.html !${reset}"

cat > bashnature.html << EOF
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta charset="utf-8">
<title>Liste insectes / oiseaux / mammifères...</title>
<meta name="description" content="">
<meta name="author" content="">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body {
    font-family: Helvetica, Calibri, Arial, sans-serif;
    background: #e0e5b6;
    #font-weight: 300;
    #font-size: 15px;
    #color: #333;
}
table {
	width: 100%;
	border-collapse: separate;
	border-spacing: 0;
	border-top: 1px solid black;
	border-left: 1px solid black;
}
th, td {
	border-right: 1px solid black;
	border-bottom: 1px solid black;
	padding: 10px;
}
caption {
	letter-spacing: 3px;
	font-weight: 600;
    font-size: 28px;
    padding: 16px;
}
h2 {
	letter-spacing: 3px;
}
a {
	color: #898121;
}
a:hover {
	color: #914f1e;
}

.bird {
	background-color: #ccd5ae;
}
.link {
	background-color: #e0e5b6;
}
.family {
	background-color: #faedce;
}
.bold {
	font-weight: bold;
}
.textcenter {
	text-align: center;
}
.index {
	width: 550px;
	margin: auto;
}
.td75 {
	width: 75%;
	background-color: #bbb;
}
.td25 {
	width: 25%;
}
#search {
	display: block;
	margin: 0 auto 16px auto;
	padding: 8px 12px;
	width: 300px;
	font-size: 16px;
	border: 1px solid #aaa;
	border-radius: 4px;
}
.item-hidden {
	display: none !important;
}
</style>
<link rel="stylesheet" href="">
<!--[if lt IE 9]>
<script src="//cdnjs.cloudflare.com/ajax/libs/html5shiv/3.7.2/html5shiv.min.js"></script>
<script src="//cdnjs.cloudflare.com/ajax/libs/respond.js/1.4.2/respond.min.js"></script>
<![endif]-->
<link rel="shortcut icon" href="">
</head>
<body>


<br />
<input type="text" id="search" placeholder="Rechercher..." oninput="filterTable()">
<table id="anchor-cask">
<caption>Liste mammifères.</caption>
<div class='index'>$liens_index</div>
$mammiferes
</table>

<script>
function filterTable() {
    var q = document.getElementById('search').value.toLowerCase();
    document.querySelectorAll('tr.textcenter').forEach(function(r) {
        r.classList.toggle('item-hidden', !!q);
    });
    document.querySelectorAll('tbody.item').forEach(function(group) {
        var bird = group.querySelector('tr.bird');
        var match = !q || bird.textContent.toLowerCase().includes(q);
        group.classList.toggle('item-hidden', !match);
    });
}</script>
</body>
</html>
EOF

}

req1() {
	echo -e "${bold}Search: <$1>${reset}"

	request="$1"
	if [[ "${request,,}" == "all" ]]; then
		request="";
	fi

	request=$(echo "$request" | sed 'y/áàâäçéèêëîïìôöóùúüñÂÀÄÇÉÈÊËÎÏÔÖÙÜÑ/aaaaceeeeiiiooouuunAAACEEEEIIOOUUN/')
	request=$(echo "$request" | sed "s/'/''/g")

    query1="SELECT * FROM liste WHERE Fra LIKE \"%$request%\" OR Aut LIKE \"%$request%\" OR Latin LIKE \"%$request%\"";
    result1=$(sqlite3 "$ScriptWorkDir/nature.db" "$query1")

    if [ -n "$result1" ]; then
    	array2=()
    	keywords=()
    	cmpt=1
   		while IFS='|' read -ra array2;
		do
			# (Francais, Fra, Autres, Aut, Male, Femelle, Jeune, Others, Latin, Anglais, Male_en, Femelle_en, Jeune_en, Ordre, Famille, Liens, Divers)

			fr2="${array2[0]}"		# Francais
        	aut2="${array2[2]}"		# Autres
        	ma2="${array2[4]}"		# Male
        	fe2="${array2[5]}"		# Femelle
        	je2="${array2[6]}"		# Jeune
        	oth2="${array2[7]}"		# Others
	        lat2="${array2[8]}"		# Latin
    	    en2="${array2[9]}"		# Anglais
         	ma_en2="${array2[10]}"	# Male_en
        	fe_en2="${array2[11]}"	# Femelle_en
        	je_en2="${array2[12]}"	# Jeune_en
        	or2="${array2[13]}"		# Ordre
	        fa2="${array2[14]}"		# Famille
    	    lnk2="${array2[15]}"	# Liens
    	    div2="${array2[16]}"	# Divers

        	tag2="$fr2"
        	[ -n "$aut2" ] && tag2+=",$aut2";
        	if [ $opt_male = true ]; then
        		[ -n "$ma2" ] && tag2+=",$ma2"
        		[ -n "$ma_en2" ] && tag2+=",$ma_en2"
        	fi
        	if [ $opt_femelle = true ]; then
        		[ -n "$fe2" ] && tag2+=",$fe2"
         		[ -n "$fe_en2" ] && tag2+=",$fe_en2"
       		fi
        	if [ $opt_jeune = true ]; then
        		[ -n "$je2" ] && tag2+=",$je2"
        		[ -n "$je_en2" ] && tag2+=",$je_en2"
        	fi
			[ -n "$oth2" ] && tag2+=",$oth2";
			[ -n "$lat2" ] && tag2+=",$lat2";
			[ -n "$en2" ] && tag2+=",$en2";

			[ -n "$or2" ] && tag2+=",$or2";
        	[ -n "$fa2" ] && tag2+=",$fa2";
        	[ -n "$div2" ] && tag2+=",$div2";

	        echo
    		printf "\e[1m| %-4s | %-25s | %-20s | %-20s | %-18s | %-15s | %-20s \e[0m\n" "$cmpt" "$fr2" "$lat2" "$en2" "$or2" "$fa2" "$aut2"
        	printf "\e[0m| %-4s | %-50s \e[0m\n" "$cmpt" "$lnk2"
	        printf "\e[0;34m| %-4s | %-55s \e[0m\n" "$cmpt" "$tag2"
    	    keywords+=("$tag2")
        	cmpt=$((cmpt+1))
	    done <<< "$result1"

	    choose=$(echo -e "\nChoose a number to get keywords in your clipboard (<q> to quit): ")
    	read -e -p "$choose" choice

	    re='^[0-9]+$'
	    if [[ $choice == "q" ]] || [[ $choice == "Q" ]]; then
	    	exit 0
		elif ! [[ $choice =~ $re ]] ; then
			echo -e "${red}Wrong index !${reset}"
	   	else
    		if [ "$choice" -ge 1 ] && [ "$choice" -le "$((cmpt-1))" ]; then
   				if [[ "$OSTYPE" == "linux-gnu" ]] && [ -x "$(command -v xsel)" ]; then
					xsel -b <<<  "${keywords[$((choice-1))]}"
					echo -e "${green}Copied to clipboard!${reset}"
				elif [[ "$OSTYPE" == "darwin"* ]] && [ -x "$(command -v pbcopy)" ]; then
					pbcopy <<<  "${keywords[$((choice-1))]}"
					echo -e "${green}Copied to clipboard!${reset}"
				fi
			else echo -e "${red}Wrong index !${reset}"
			fi
		fi

	else
		echo -e "\n ${red}No results found!"
	fi
    }


self_update_curl() {
  cp "$ScriptPath" "$ScriptPath".bak
  if [[ $(builtin type -P curl) ]]; then
    curl -L "$RawUrl" > "$ScriptPath" ; chmod +x "$ScriptPath"
    printf "\n%s\n" "--- starting over with the updated version ---"
    exec "$ScriptPath" "${ScriptArgs[@]}"  # run the new script with old arguments
    exit 1 # exit the old instance
  elif [[ $(builtin type -P wget) ]]; then
    wget "$RawUrl" -O "$ScriptPath" ; chmod +x "$ScriptPath"
    printf "\n%s\n" "--- starting over with the updated version ---"
    exec "$ScriptPath" "${ScriptArgs[@]}" # run the new script with old arguments
    exit 1 # exit the old instance
  else
    printf "curl/wget not available - download the update manually: %s \n" "$Github"
  fi
}

self_update() {
  cd "$ScriptWorkDir" || { printf "Path error, skipping update.\n" ; return ; }
  if [[ $(builtin type -P git) ]] && [[ "$(git ls-remote --get-url 2>/dev/null)" =~ .*"bruno21/bashnature".* ]] ; then
    printf "\n%s\n" "Pulling the latest version."
    git pull --force || { printf "Git error, manually pull/clone.\n" ; return ; }
    printf "\n%s\n" "--- starting over with the updated version ---"
    cd - || { printf "Path error.\n" ; return ; }
    exec "$ScriptPath" "${ScriptArgs[@]}" # run the new script with old arguments
    exit 1 # exit the old instance
  else
    cd - || { printf "Path error.\n" ; return ; }
    self_update_curl
  fi
}

check_version() {
	curl -Is https://www.github.com | head -1 | grep 301 1>/dev/null
	if [[ $? -eq 1 ]]; then
		echo -e "\n${red}No GitHub connection !${reset}"
	else

		### Check if there's a new release of the script:
		LatestRelease="$(curl -s -r 0-50 "$RawUrl" | sed -n "/VERSION/s/VERSION=//p" | tr -d '"')"
		#LatestChanges="$(curl -s -r 0-2000 "$RawUrl" | sed -n "/ChangeNotes/s/# ChangeNotes: //p")"
		LatestChanges="$(curl -s -r 0-2000 "$RawUrl" | grep "^### ChangeNotes:" | sed 's/### ChangeNotes://g')"

		### Version check & initiate self update
		if [[ "$VERSION" != "$LatestRelease" ]] ; then
			printf "New version available! %b%s%b ⇒ %b%s%b \nChange Notes:\n%s \n" "${yellow}" "$VERSION" "${reset}" "${green}" "$LatestRelease" "${reset}" "$LatestChanges"
			if [[ -z "$AutoUp" ]] ; then
				read -r -p "Would you like to update? y/[n]: " SelfUpdate
    			[[ "$SelfUpdate" =~ [yY] ]] && self_update
  			fi
		fi
	fi
}

### Database is present or not ?
if [ ! -f "$ScriptWorkDir/nature.db" ]; then
    echo -e "${red}No database found !${reset}"
    exit 1

else
    query="SELECT COUNT(Francais) FROM liste";
    result5=$(sqlite3 "$ScriptWorkDir/nature.db" "$query")

   	if [ -n "$result5" ]; then
   		echo -e "\n${bold}A nature database that return keywords for Lightroom.${reset}"
   		echo -e "$result5 objects founds in database...\n"
   		#Help
   	fi
fi

while getopts "s:hewmfju" options; do
  case "${options}" in
   	# a)  req1 "${OPTARG}" ;;
    s) search="${OPTARG}";;
    e|w)  req2 "${options}" ;;
    m)	opt_male=true;;
    f)	opt_femelle=true;;
    j)	opt_jeune=true;;
    u)  check_version ; exit 0 ;;
    h|*) Help ; exit 2 ;;
  esac
done
shift "$((OPTIND-1))"

if [ -z "$search" ]; then
	Help
	exit 2
fi

req1 "$search"
