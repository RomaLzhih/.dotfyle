#!/bin/bash
#POSIX

while getopts u:s:i:p: flag; do
	case "${flag}" in
	u) update=${OPTARG} ;;
	s) server=${OPTARG} ;;
	i) install=${OPTARG} ;;
	p) python_update=${OPTARG}:: ;;
	esac
done

# TODO: rewrite it as a function
git diff --quiet
changes=$?
if [[ ${changes} == "1" ]]; then
	echo "Changes detected, please commit first."
	exit 1
fi

if [[ ${update} == "1" ]]; then
	cp -r .config ${HOME}/
	cp .tmux.conf ${HOME}/
	cp .vimrc ${HOME}/
	cp .wezterm.lua ${HOME}/
	cp .zshrc ${HOME}/
	# TODO: check whether are changes
	cd .config/nvim && git reset --hard && git pull

	if [[ ${python_update} == "1" ]]; then
		cd ${HOME}
		python3 -m venv .venv
		source .venv/bin/activate
		pip --disable-pip-version-check list --outdated --format=json | python -c "import json, sys; print('\n'.join([x['name'] for x in json.load(sys.stdin)]))" | xargs -n1 pip install -U
	fi

	source ${HOME}/.zshrc
	tmux source ${HOME}/.tmux.conf
fi

if [[ ${install} == "1" ]]; then

	if ! [ -x "$(command -v nvim)" ]; then
		mkdir -p ${HOME}/bin/repo
		cd ${HOME}/bin/repo
		git clone https://github.com/neovim/neovim
		cd neovim
		make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/neovim"
		make install
		export PATH="$HOME/neovim/bin:$PATH"

		if ! [ -x "$(command -v nvim)" ]; then
			echo "neovim is not installed"
			exit 1
		fi
	fi

	rm -rf ~/.config/nvim
	rm -rf ~/.local/share/nvim
	git clone git@github.com:RomaLzhih/NvChad_x.git ~/.config/nvim --depth 1

	cd ${HOME}
	python3 -m venv .venv
	source .venv/bin/activate

	python3 -m pip --version
	python3 -m pip install --upgrade pip setuptools wheel

	python3 -m pip install clang-tidy
	python3 -m pip install cpplint
	python3 -m pip install black

	mkdir -p ${HOME}/bin/repo
	cd ~/bin/repo
	git clone git@github.com:danmar/cppcheck.git
	cd cppcheck
	mkdir build
	cd build
	cmake ..
	cmake --build .
	cd ${HOME}/bin/
	ln -s "$PWD/cppcheck" ~/bin/cppcheck

	curl -sS https://webi.sh/shfmt | sh
fi
