################################################################################
# Global Environment Variables 
################################################################################
export FULL_NAME="Raul Zaldana"
export EMAIL="rzaldana.dev@gmail.com"
export GIT_BASE="${HOME}/git-repos"
export EDITOR='vim'

################################################################################
# Alias definitions
################################################################################
# You may want to put all your additions into a separate file like
# ~/.bash_alases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [[ -f "${HOME}/.bash_aliases" ]]; then
    # shellcheck disable=1090,1091
    source "${HOME}/.bash_aliases"
fi

################################################################################
# Include local bin dirs in path 
################################################################################
# Include top level bin dir (for self-authored scripts and tools)
if [[ -d "${HOME}/bin" ]]; then
  export PATH="${HOME}/bin:${PATH}"
fi

# Include ~/.local/bin for XDG-compliant applications
if [[ -d "${HOME}/.local/bin" ]]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi

################################################################################
# Homebrew 
################################################################################
eval "$(/opt/homebrew/bin/brew shellenv)"

################################################################################
# nvim 
################################################################################
# set nvm dir to store node versions
export NVM_DIR="$HOME/.nvm"
# source nvm
[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
# source nvm bash_completion
[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

################################################################################
# pyenv 
################################################################################
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

################################################################################
# krew 
################################################################################
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

################################################################################
# direnv 
################################################################################
# Load direnv
eval "$(direnv hook bash)"
