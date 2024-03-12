#!/bin/bash
#POSIX
# set -o xtrace

CheckDiffStatus() {
	cur_path=${PWD}
	check_path=$1
	debug_mode=$2
	cd "${check_path}" || exit
	git diff --quiet
	changes=$?
	if [[ ${changes} == "1" ]]; then
		echo "Changes detected in ${check_path}, please commit first."
		if [[ ${debug_mode} == 1 ]]; then
			exit 1
		fi
	fi
	cd "${cur_path}" || exit
}

# NOTE: get os name
os=""
if [ -r /etc/os-release ]; then
	os="$(. /etc/os-release && echo "$ID")"
fi
echo "OS Release: ${os}"

kUpdate=1
kInstall=0
kForceUpdate=0
debug=0
while getopts u:i:p:f:d: flag; do
	case "${flag}" in
	u) "${kUpdate}=1" ;;
	i) "${kInstall}=1" ;;
	f) "${kForceUpdate}=1" ;;
	d) "${debug}=1" ;;
	*) echo "Running default settings: only update, without discard changes in git" ;;
	esac
done

if [[ ${kForceUpdate} == 0 ]]; then
	CheckDiffStatus "${PWD}" "${debug}"
else
	git reset --hard
fi

# NOTE: update
if [[ ${kUpdate} == 1 ]]; then
	# NOTE: COPY file
	cp -r .config "${HOME}/"
	cp .tmux.conf "${HOME}/"
	cp .vimrc "${HOME}/"
	cp .wezterm.lua "${HOME}/"
	cp .zshrc "${HOME}/"

	# source "${HOME}/.zshrc" || zsh
	tmux source "${HOME}/.tmux.conf"

	# NOTE: neovim
	if [[ ${kForceUpdate} == 0 ]]; then
		CheckDiffStatus "${HOME}/.config/nvim" "${debug}"
	else
		cd "${HOME}/.config/nvim" || exit
		git reset --hard && git pull
	fi

	# NOTE: neovim dependencies
	if [[ ${os} == "centos" ]]; then
		cd "${HOME}" || exit
		python3 -m venv .venv
		source .venv/bin/activate
		pip --disable-pip-version-check list --outdated --format=json | python -c "import json, sys; print('\n'.join([x['name'] for x in json.load(sys.stdin)]))" | xargs -n1 pip install -U
	elif [[ ${os} == "ubuntu" ]]; then
		echo "here"
		sudo apt update && sudo apt upgrade -y
	fi
fi

# NOTE: install
if [[ ${kInstall} == 1 ]]; then

	# NOTE: check if neovim is installed
	if ! [ -x "$(command -v nvim)" ]; then
		cur_path=${PWD}

		mkdir -p "${HOME}/bin/repo"
		cd "${HOME}/bin/repo" || exit
		git clone https://github.com/neovim/neovim
		cd "neovim" || exit
		make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/neovim"
		make install
		export PATH="$HOME/neovim/bin:$PATH"

		if ! [ -x "$(command -v nvim)" ]; then
			echo "neovim is not installed"
			exit 1
		fi

		cd "${cur_path}" || exit
	fi

	# NOTE: install the neovim config
	rm -rf ~/.config/nvim
	rm -rf ~/.local/share/nvim
	git clone git@github.com:RomaLzhih/NvChad_x.git ~/.config/nvim --depth 1

	# NOTE: install the dependencies for neovim
	if [[ ${os} == "centos" ]]; then
		cd "${HOME}" || exit
		python3 -m venv .venv
		source .venv/bin/activate

		python3 -m pip --version
		python3 -m pip install --upgrade pip setuptools wheel

		python3 -m pip install clang-tidy
		python3 -m pip install cpplint
		python3 -m pip install black

		mkdir -p "${HOME}/bin/repo"
		cd "${HOME}/bin/repo" || exit
		git clone git@github.com:danmar/cppcheck.git
		cd "cppcheck" || exit
		mkdir build
		cd "build" || exit
		cmake ..
		cmake --build .
		cd "${HOME}/bin/" || exit
		ln -s "$PWD/cppcheck" ~/bin/cppcheck

		curl -sS https://webi.sh/shfmt | sh
	elif [[ ${os} == "ubuntu" ]]; then
		sudo apt install clang-tidy cpplint black cppcheck shfmt shellcheck
	fi
fi

echo ">>>>>> Done! Have a good day!"
