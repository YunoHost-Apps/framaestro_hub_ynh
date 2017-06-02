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
	nodejs_path=$(ynh_app_setting_get $app nodejs_path)
	nodejs_version=$(ynh_app_setting_get $app nodejs_version)

	# And store the command to use a specific version of node. Equal to `nvm use version`
	nodejs_use_version="source $nvm_install_dir/nvm.sh; nvm use \"$nodejs_version\""

	# Desactive set -u for this script.
	set +u
	eval $nodejs_use_version
	set -u
}

ynh_install_nodejs () {
	local nodejs_version="$1"
	local nvm_install_script="https://raw.githubusercontent.com/creationix/nvm/v0.33.1/install.sh"

	local nvm_exec="source $nvm_install_dir/nvm.sh; nvm"

	sudo mkdir -p "$nvm_install_dir"

	# If nvm is not previously setup, install it
	"$nvm_exec --version" > /dev/null 2>&1 || \
	( cd "$nvm_install_dir"
	echo "Installation of NVM"
	sudo wget --no-verbose "$nvm_install_script" -O- | sudo NVM_DIR="$nvm_install_dir" bash > /dev/null)

	# Install the requested version of nodejs
	sudo su -c "$nvm_exec install \"$nodejs_version\" > /dev/null"

	# Store the ID of this app and the version of node requested for it
	echo "$YNH_APP_ID:$nodejs_version" | sudo tee --append "$nvm_install_dir/ynh_app_version"

	# Get the absolute path of this version of node
	nodejs_path="$(dirname "$(sudo su -c "$nvm_exec which \"$nodejs_version\"")")"

	# Store nodejs_path and nodejs_version into the config of this app
	ynh_app_setting_set $app nodejs_path $nodejs_path
	ynh_app_setting_set $app nodejs_version $nodejs_version

	ynh_use_nodejs
}

ynh_remove_nodejs () {
	nodejs_version=$(ynh_app_setting_get $app nodejs_version)

	# Remove the line for this app
	sudo sed --in-place "/$YNH_APP_ID:$nodejs_version/d" "$nvm_install_dir/ynh_app_version"

	# If none another app uses this version of nodejs, remove it.
	if ! grep --quiet "$nodejs_version" "$nvm_install_dir/ynh_app_version"
	then
		sudo su -c "source $nvm_install_dir/nvm.sh; nvm deactivate; nvm uninstall \"$nodejs_version\" > /dev/null"
	fi

	# If none another app uses nvm, remove nvm and clean the root's bashrc file
	if [ ! -s "$nvm_install_dir/ynh_app_version" ]
	then
		ynh_secure_remove "$nvm_install_dir"
		sudo sed --in-place "/NVM_DIR/d" /root/.bashrc
	fi
}

ynh_use_nodejs stable
node __FINALPATH__/hub/server.js --log /var/log/framaestro_hub/togetherjs.log --log-level=2 --port __PORT__
