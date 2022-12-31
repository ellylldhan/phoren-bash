# phoren-bash

Version BASH du script PHOREN

Renomme et réoriente un fichier jpg selon ses métadata.

Voir `./phoren_bash.sh --usage` pour plus d'infos.

[TOC]

## Pré-requis

Nécessite les paquets `jhead` et `exiftran`.

- `jhead`    : *manipulate the non-image part of Exif compliant JPEG files*. 
- `exiftran` : *digital camera JPEG image transformer*.

```sh
sudo apt install jhead exiftran
```

## Utilisation

### Syntaxe

```bash
phoren2 /chemin/vers/dossier $extension_sans_point
```

### Exemples

```bash
$ phoren . jpg 
$ phoren /mnt/243-433/DCIM JPG
$ phoren '/c/Users/Moi/Mes Photos/Vacances 2023' jpg
```
