#!/usr/bin/env zsh
# vim: ft=zsh fdm=marker foldlevel=0 sw=2 ts=2 sts=2 et

function prompt_spaceship_help {
  cat <<'EOF'
🚀⭐️ A Zsh prompt for Astronauts

  prompt spaceship

Spaceship is a minimalistic, powerful and extremely customizable Zsh prompt.
It combines everything you may need for convenient work, without unnecessary
complications, like a real spaceship.
EOF
}

# ------------------------------------------------------------------------------
# SETUP
# Setup requirements for prompt
# ------------------------------------------------------------------------------

# Runs once when user opens a terminal
# All preparation before drawing prompt should be done here
function prompt_spaceship_setup {
  # reset prompt according to prompt_default_setup
  PS1='%m%# '
  PS2='%_> '
  PS3='?# '
  PS4='+%N:%i> '
  unset RPS1 RPS2 RPROMPT RPROMPT2

  local item

  # This variable is a magic variable used when loading themes with zsh's prompt
  # function. It will ensure the proper prompt options are set.
  prompt_opts=(cr percent sp subst)

  # Borrowed from promptinit, sets the prompt options in case the prompt was not
  # initialized via promptinit.
  setopt noprompt{bang,cr,percent,subst} "prompt${^prompt_opts[@]}"

  # initialize timing functions
  zmodload zsh/datetime

  # Initialize math functions
  zmodload zsh/mathfunc

  typeset -gAH _SS_DATA=()
  # store result from ss::section
  _SS_DATA[section_result]=""

  typeset -gAh _ss_async_sections=()
  typeset -gAh _ss_custom_sections=()

  # Global section cache
  typeset -gAh _ss_section_cache=()

  # _ss_unsafe must be a global variable, because we set
  # PROMPT='$_ss_unsafe[left]', so without letting ZSH
  # expand this value (single quotes). This is a workaround
  # to avoid double expansion of the contents of the PROMPT.
  typeset -gAh _ss_unsafe=()

  # Load a preset by name
  # presets must be loaded before lib/default.zsh
  if [[ -n "$1" ]]; then
    if [[ -r "${SPACESHIP_ROOT}/presets/${1}.zsh" ]]; then
      source "${SPACESHIP_ROOT}/presets/${1}.zsh"
    else
      echo "Spaceship: No such preset found in ${SPACESHIP_ROOT}/presets/${1}"
    fi
  fi

  builtin autoload -Uz +X -- add-zsh-hook track-ss-autoload
  track-ss-autoload add-ss-hook run-ss-hook

  # setup functions
  for item in "${SPACESHIP_ROOT}"/lib/setups/ss::*[^.zwc](-.N:t); do
    track-ss-autoload "$item"
  done

  # Always load default conf
  source "$SPACESHIP_ROOT/lib/default.zsh"
  # LIBS
  source "$SPACESHIP_ROOT/lib/utils.zsh"
  # sections.zsh is deprecated, cause it's linked as prompt_spaceship_setup
  # source "$SPACESHIP_ROOT/lib/section.zsh"
  ss::load_sections
  ss::deprecated_check

  # Hooks
  track-ss-autoload prompt_spaceship_precmd prompt_spaceship_preexec \
    prompt_spaceship_chpwd

  add-zsh-hook precmd prompt_spaceship_precmd
  add-zsh-hook preexec prompt_spaceship_preexec
  # hook into chpwd for bindkey support
  add-zsh-hook chpwd prompt_spaceship_chpwd

  # Utilities
  for item in "${SPACESHIP_ROOT}"/lib/utils/ss::*[^.zwc](-.N:t); do
    track-ss-autoload "$item"
  done

  # The value below was set to better support 32-bit CPUs.
  # It's the maximum _signed_ integer value on 32-bit CPUs.
  # Please don't change it until 19 January of 2038. ;)

  # Disable false display of command execution time
  SPACESHIP_EXEC_TIME_start=0x7FFFFFFF

  # Disable python virtualenv environment prompt prefix
  VIRTUAL_ENV_DISABLE_PROMPT=true

  # Expose Spaceship to environment variables
  PS2='$(ss::ps2)'

  # prepend custom cleanup hook
  local -a cleanup_hooks
  zstyle -g cleanup_hooks :prompt-theme cleanup
  zstyle -e :prompt-theme cleanup "prompt_spaceship_cleanup;" "${cleanup_hooks[@]}"
  # append cleanup hook with builtin func
  # prompt_cleanup "prompt_spaceship_cleanup"
}

# TODO: compile helper

# This function removes spaceship hooks and resets the prompts.
function prompt_spaceship_cleanup {
  local item

  async_stop_worker "spaceship_section_worker" 2>/dev/null

  # prmopt specific cleanup
  ss::vi_mode_disable 2>/dev/null
  # TODO: cleanup preset conf

  # prompt hooks
  add-zsh-hook -D chpwd   prompt_spaceship_\*
  add-zsh-hook -D precmd  prompt_spaceship_\*
  add-zsh-hook -D preexec prompt_spaceship_\*

  # setopt localoptions NULL_GLOB
  for item in ${_SS_AUTOLOADED[@]}; do
    builtin unfunction -- "$item"
  done

  unset _ss_async_sections _ss_custom_sections _ss_section_cache _ss_unsafe \
    ss_{chpwd,precmd,preexec}_functions \
    _SS_DATA _SS_AUTOLOADED 2>/dev/null

  # reset prompt according to prompt_default_setup
  PS1='%m%# '
  PS2='%_> '
  PS3='?# '
  PS4='+%N:%i> '
  unset RPS1 RPS2 RPROMPT RPROMPT2
  prompt_opts=( cr percent sp )
}

prompt_spaceship_setup "$@"
