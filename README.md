# bashnature

Generate Adobe Lightroom keywords from a local SQLite database of French
wildlife names.

Searching for a species prints its names and classification, then copies a
ready-to-paste keyword string to the clipboard. The same database can also be
exported as a searchable HTML page or as a Markdown document.

Version française : [README.fr.md](README.fr.md)

## Requirements

- **bash 4.2 or newer.** The scripts use `${var,,}` and negative substring
  lengths, which the bash 3.2 that ships with macOS rejects. Install a current
  bash and make sure it comes first in `PATH`, since the shebang is
  `#!/usr/bin/env bash`.
- **sqlite3.** Both scripts check for it and stop with a clear message if it is
  missing.
- **A clipboard tool**: `pbcopy` on macOS (built in) or `xsel` on Linux.
- **curl or wget, and git**, only for the self-update described below.

## Importing the database

```bash
./insert_nature.sh
```

Every `Nature/*.csv` file is read in turn. `nature.db` is created on first run.
Rows are written with `INSERT OR REPLACE` keyed on the French name, so running
the import again is harmless and refreshes existing entries rather than
duplicating them.

Two constraints apply to the CSV files:

- **The field separator is a semicolon.** Excel forces commas; LibreOffice and
  Apple Numbers let you choose.
- **The filename must contain `Insectes`, `Mammiferes`, `Oiseaux` or
  `Plantes`.** That word determines the type keywords stored in the `Divers`
  column, such as `Oiseau,Bird`. A file matching none of them is skipped with a
  warning.

Any row that fails to insert is appended to `errors.txt` along with the SQL
that produced it.

## Searching

```bash
./bashnature.sh -s renard
./bashnature.sh -s "Belette d'Europe"
./bashnature.sh -s all
```

Quote any term containing a space. Without quotes, `getopts` keeps only the
first word and the script warns about the arguments it discarded.

The search covers the accent-free French name, the accent-free alternative
name and the scientific name. Accents in the search term are normalised, so
`ecureuil` finds `Écureuil`.

Results are numbered. Enter a number to copy that entry's keywords to the
clipboard, or `q` to quit.

## Keyword content

The keyword string always contains the French name, alternative names, other
names, scientific name, English name, order, family and the type pair. Three
flags add the gendered names, in French and English:

| Flag | Adds |
| --- | --- |
| `-m` | male names |
| `-f` | female names |
| `-j` | juvenile names |

Only 14 of the current entries carry gendered names, so these flags change
nothing for most species.

## Exports

| Flag | Output file |
| --- | --- |
| `-w` | `bashnature.html` |
| `-e` | `bashnature.md` |

The HTML page holds one table with a live filter field, letter anchors, and the
alphabetical index repeated every 25 entries. The Markdown document opens with
a letter index linking to one section per letter.

Both exports sort on the accent-free name, which files `Échasse blanche` under
E rather than after Z.

## Database schema

One table, `liste`, with `UNIQUE(Francais)`. The CSV columns map to it in order:

| CSV column | Database column | Used for |
| --- | --- | --- |
| Français | `Francais` | display, unique key |
| Français (sans accent) | `Fra` | searched, sort key |
| Autre nom | `Autres` | display, keywords |
| Autre nom (sans accent) | `Aut` | searched |
| Male (Fr) | `Male` | `-m` |
| Femellle (Fr) | `Femelle` | `-f` |
| Jeune (Fr) | `Jeune` | `-j` |
| Autres | `Others` | keywords |
| Vernaculaire | `Latin` | searched, display |
| Anglais | `Anglais` | display, keywords |
| Male (En) | `Male_en` | `-m` |
| Femelle (En) | `Femelle_en` | `-f` |
| Jeune (En) | `Jeune_en` | `-j` |
| Ordre | `Ordre` | display, keywords |
| Famille | `Famille` | display, keywords |
| Liens (fr) | `Liens` | export links |
| Liens (en) | not imported | — |
| derived from filename | `Divers` | type keywords |

Export links are labelled from the target host: `Oiseaux.net`, `Wikipedia`, or
`Web` for anything else. An entry without a link gets no link at all rather
than an empty one.

The database currently holds 1164 entries: 1039 birds, 72 insects, 36 mammals
and 17 plants.

## Self-update

```bash
./bashnature.sh -u
```

This compares the local `VERSION` with the one in the GitHub repository and
offers to replace the script in place. Inside a git clone it pulls; otherwise
it downloads the file and keeps a `.bak` copy first. The repository is private,
so `GITHUB_TOKEN` must be in the environment; the script expects it from the
keychain through fnox.

Versions are compared field by field as numbers, so `v1.10` ranks above `v1.9`
and a missing field counts as zero, making `v1.0` and `v1.0.0` equal. An update
is only offered when the repository is genuinely ahead. A local version ahead of
the repository is reported as such, and a reply that cannot be read as a version
aborts the check instead of offering anything.

Every request appends a timestamped parameter, because the raw file is served
from a cache that holds for a few minutes. Without it a fresh push stays
invisible to `-u`, and the download could fetch an older copy than the one just
announced.

## Repository files

| Path | Role |
| --- | --- |
| `bashnature.sh` | search, keyword output, exports, self-update |
| `insert_nature.sh` | builds `nature.db` from the CSV files |
| `Nature/*.csv` | source data, one file per group |
| `nature.db` | generated SQLite database |
| `bashnature.html` | generated HTML export |
| `bashnature.md` | generated Markdown export |
| `errors.txt` | generated, failed inserts only |
| `README.md` | this document |
| `README.fr.md` | French translation |
| `LICENSE` | full text of the GNU GPL v3 |

## License

This project is released under the GNU General Public License, version 3. See
[LICENSE](LICENSE) for the full text.
