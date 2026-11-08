# bashnature

Génère des mots-clés Adobe Lightroom à partir d'une base SQLite locale de noms
d'espèces.

Une recherche affiche les noms et la classification de l'espèce, puis copie
dans le presse-papiers une chaîne de mots-clés prête à coller. La même base
peut être exportée en page HTML consultable ou en document Markdown.

English version: [README.md](README.md)

## Prérequis

- **bash 4.2 ou plus récent.** Les scripts utilisent `${var,,}` et les
  longueurs de sous-chaîne négatives, que le bash 3.2 livré avec macOS refuse.
  Installez un bash récent et placez-le en tête du `PATH`, le shebang étant
  `#!/usr/bin/env bash`.
- **sqlite3.** Les deux scripts en vérifient la présence et s'arrêtent avec un
  message explicite s'il manque.
- **Un outil de presse-papiers** : `pbcopy` sur macOS (fourni) ou `xsel` sous
  Linux.
- **curl ou wget, et git**, uniquement pour la mise à jour automatique décrite
  plus bas.

## Import de la base

```bash
./insert_nature.sh
```

Chaque fichier `Nature/*.csv` est lu à son tour. `nature.db` est créée au
premier lancement. Les lignes sont écrites avec `INSERT OR REPLACE` sur la clé
du nom français : relancer l'import est donc sans danger et rafraîchit les
fiches existantes au lieu de les dupliquer.

Deux contraintes pèsent sur les fichiers CSV :

- **Le séparateur est le point-virgule.** Excel impose la virgule ; LibreOffice
  et Apple Numbers laissent le choix.
- **Le nom du fichier doit contenir `Insectes`, `Mammiferes`, `Oiseaux` ou
  `Plantes`.** Ce mot détermine les mots-clés de type stockés dans la colonne
  `Divers`, par exemple `Oiseau,Bird`. Un fichier ne correspondant à aucun est
  ignoré avec un avertissement.

Toute ligne dont l'insertion échoue est ajoutée à `errors.txt`, accompagnée du
SQL qui l'a produite.

## Recherche

```bash
./bashnature.sh -s renard
./bashnature.sh -s "Belette d'Europe"
./bashnature.sh -s all
```

Entourez de guillemets tout terme contenant une espace. Sans guillemets,
`getopts` ne retient que le premier mot et le script signale les arguments
écartés.

La recherche porte sur le nom français sans accent, le nom alternatif sans
accent et le nom scientifique. Les accents du terme recherché sont normalisés,
donc `ecureuil` trouve `Écureuil`.

Les résultats sont numérotés. Saisissez un numéro pour copier les mots-clés de
la fiche dans le presse-papiers, ou `q` pour quitter.

## Contenu des mots-clés

La chaîne de mots-clés contient toujours le nom français, les noms
alternatifs, les autres noms, le nom scientifique, le nom anglais, l'ordre, la
famille et le couple de type. Trois options ajoutent les noms genrés, en
français et en anglais :

| Option | Ajoute |
| --- | --- |
| `-m` | les noms de mâle |
| `-f` | les noms de femelle |
| `-j` | les noms de jeune |

Seules 14 fiches de la base actuelle portent des noms genrés : ces options ne
changent donc rien pour la plupart des espèces.

## Exports

| Option | Fichier produit |
| --- | --- |
| `-w` | `bashnature.html` |
| `-e` | `bashnature.md` |

La page HTML contient un tableau unique avec un champ de filtrage instantané,
des ancres par lettre et la barre d'index alphabétique répétée toutes les 25
fiches. Le document Markdown s'ouvre sur un index des lettres renvoyant vers
une section par lettre.

Les deux exports trient sur le nom sans accent, ce qui classe `Échasse
blanche` dans la section E plutôt qu'après le Z.

## Schéma de la base

Une seule table, `liste`, avec `UNIQUE(Francais)`. Les colonnes du CSV lui
correspondent dans l'ordre :

| Colonne CSV | Colonne en base | Sert à |
| --- | --- | --- |
| Français | `Francais` | affichage, clé unique |
| Français (sans accent) | `Fra` | recherche, tri |
| Autre nom | `Autres` | affichage, mots-clés |
| Autre nom (sans accent) | `Aut` | recherche |
| Male (Fr) | `Male` | `-m` |
| Femellle (Fr) | `Femelle` | `-f` |
| Jeune (Fr) | `Jeune` | `-j` |
| Autres | `Others` | mots-clés |
| Vernaculaire | `Latin` | recherche, affichage |
| Anglais | `Anglais` | affichage, mots-clés |
| Male (En) | `Male_en` | `-m` |
| Femelle (En) | `Femelle_en` | `-f` |
| Jeune (En) | `Jeune_en` | `-j` |
| Ordre | `Ordre` | affichage, mots-clés |
| Famille | `Famille` | affichage, mots-clés |
| Liens (fr) | `Liens` | liens des exports |
| Liens (en) | non importée | — |
| déduit du nom de fichier | `Divers` | mots-clés de type |

Le libellé des liens des exports suit le site visé : `Oiseaux.net`,
`Wikipedia`, ou `Web` pour tout autre. Une fiche sans lien n'en reçoit aucun,
plutôt qu'un lien vide.

La base contient actuellement 1164 fiches : 1039 oiseaux, 72 insectes, 36
mammifères et 17 plantes.

## Mise à jour automatique

```bash
./bashnature.sh -u
```

Compare le `VERSION` local à celui du dépôt GitHub et propose de remplacer le
script sur place. Dans un clone git il fait un `git pull` ; sinon il télécharge
le fichier après avoir conservé une copie `.bak`. Le dépôt étant privé,
`GITHUB_TOKEN` doit être présent dans l'environnement ; le script l'attend du
porte-clés via fnox.

Les versions sont comparées champ par champ comme des nombres : `v1.10` passe
donc après `v1.9`, et un champ absent compte pour zéro, ce qui rend `v1.0` et
`v1.0.0` équivalents. Une mise à jour n'est proposée que si le dépôt est
réellement en avance. Une version locale en avance sur le dépôt est signalée
comme telle, et une réponse illisible comme version interrompt la vérification
au lieu de proposer quoi que ce soit.

## Fichiers du dépôt

| Chemin | Rôle |
| --- | --- |
| `bashnature.sh` | recherche, mots-clés, exports, mise à jour |
| `insert_nature.sh` | construit `nature.db` depuis les CSV |
| `Nature/*.csv` | données source, un fichier par groupe |
| `nature.db` | base SQLite générée |
| `bashnature.html` | export HTML généré |
| `bashnature.md` | export Markdown généré |
| `errors.txt` | généré, insertions en échec uniquement |
