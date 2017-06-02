#!/bin/bash
# INFOS
# nvm utilise la variable PATH pour stocker le path de la version de node à utiliser.
# C'est ainsi qu'il change de version
# En attendant une généralisation de root, il est possible d'utiliser sudo aevc le helper temporaire sudo_path
# Il permet d'utiliser sudo en gardant le $PATH modifié
# ynh_install_nodejs installe la version de nodejs demandée en argument, avec nvm
# ynh_use_nodejs active une version de nodejs dans le script courant
# 3 variables sont mises à disposition, et 2 sont stockées dans la config de l'app
# - nodejs_path: Le chemin absolu de cette version de node
# Utilisé pour des appels directs à npm ou node.
# - nodejs_version: Simplement le numéro de version de nodejs pour cette application
# - nodejs_use_version: Un alias pour charger une version de node dans le shell courant.
# Utilisé pour démarrer un service ou un script qui utilise node ou npm
# Dans ce cas, c'est $PATH qui contient le chemin de la version de node. Il doit être propagé sur les autres shell si nécessaire.

nvm_install_dir="/opt/nvm"
ynh_use_nodejs () {
	nodejs_path=__NODEJS_PATH__
	nodejs_version=6.10.3

	# And store the command to use a specific version of node. Equal to `nvm use version`
	nodejs_use_version="source $nvm_install_dir/nvm.sh; nvm use \"$nodejs_version\""

	# Desactive set -u for this script.
	set +u
	eval $nodejs_use_version
	set -u
}

ynh_use_nodejs
node __FINALPATH__/hub/server.js --log /var/log/framaestro_hub/togetherjs.log --log-level=2 --port __PORT__
