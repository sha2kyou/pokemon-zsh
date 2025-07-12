#!/bin/zsh

# This file is meant to be sourced by zsh.
# It defines functions for displaying Pokémon.

# Source the translations file
source "pokemon-translations.zsh"

# Global variables
SHINY_RATE=128
CD_TRIGGER_RATE=6

# Function to check for dependencies and set _HASH_CMD
_pokemon_check_dependencies() {
  # Check for pokemon-colorscripts
  if ! command -v pokemon-colorscripts &> /dev/null; then
      echo "Error: 'pokemon-colorscripts' not found. Please install it. (https://gitlab.com/phoneybadger/pokemon-colorscripts)" >&2
      return 1
  fi

  # Check and set hash command
  if command -v sha256sum &> /dev/null; then
      _HASH_CMD="sha256sum"
  elif command -v shasum &> /dev/null; then
      _HASH_CMD="shasum -a 256"
  else
      echo "Error: 'sha256sum' or 'shasum' not found. show_pokemon_by_dir will be disabled." >&2
      _HASH_CMD=""
  fi
  return 0
}

# Overwrite ls command
function ls() {
  if _pokemon_check_dependencies; then
    pokemon 15 1
    echo "----------------------------------------"
  fi
  command ls "$@"
}

# Overwrite cd command
function cd() {
  builtin cd "$@" || return 1

  if _pokemon_check_dependencies; then
    if ((RANDOM % CD_TRIGGER_RATE == 0)); then
      pokemon 1 1
    fi
  fi
}

# Get specified Pokémon and display
function _display_pokemon() {
  local pokemon_name=$1
  local is_shiny=$2

  local cn_pokemon_name
  if [[ -z "$pokemon_name" ]]; then
    echo "Error: Pokémon name is empty. Using default '宝可梦'." >&2
    cn_pokemon_name="宝可梦"
  else
    # Add debug log here
    echo "[DEBUG] _display_pokemon: Before calling get_cn_name_by_en_name. pokemon_translations keys: ${(k)pokemon_translations}" >&2
    echo "[DEBUG] _display_pokemon: Before calling get_cn_name_by_en_name. pokemon_translations values: ${(v)pokemon_translations}" >&2

    cn_pokemon_name=$(get_cn_name_by_en_name "$pokemon_name")
    if [[ -z "$cn_pokemon_name" ]]; then
      cn_pokemon_name="宝可梦"
    fi
  fi

  local shiny_flag=""
  local message_prefix="野生的"
  local message_suffix="出现了。"

  if [[ $is_shiny == true ]]; then
    shiny_flag="-s"
    message_prefix="✨野生的闪光"
    message_suffix="出现了！✨"
  fi
  
echo "${message_prefix}${cn_pokemon_name}${message_suffix}"
pokemon-colorscripts -n "$pokemon_name" --no-title -r ${shiny_flag}
}

# Get Pokémon list
function _get_pokemon_list() {
  local pokemon_list

  # Use cache to avoid repeated calls
  if [[ -z $POKEMON_LIST_CACHE ]]; then
    POKEMON_LIST_CACHE=$(pokemon-colorscripts -l)
  fi

  IFS=$'\n' pokemon_list=("${(f)POKEMON_LIST_CACHE}")
  echo "${pokemon_list[@]}"
}

# Display Pokémon by directory hash
function show_pokemon_by_dir() {
  # If hash command is not available, return directly
  [[ -z "$_HASH_CMD" ]] && return 1

  local pokemon_list current_dir num_list selected_index is_shiny

  pokemon_list=($(_get_pokemon_list))
  [[ ${#pokemon_list[@]} -eq 0 ]] && echo "Error: Could not get Pokémon list" && return 1

  current_dir=$(pwd)
  num_list=($(map_string_to_numbers "$current_dir"))
  [[ ${#num_list[@]} -eq 0 ]] && echo "Error: Number mapping failed" && return 1

  selected_index=$(( RANDOM % ${#num_list[@]} ))
  selected_number=${num_list[$selected_index]}
  pokemon_index=$(( selected_number % ${#pokemon_list[@]} + 1 ))
  is_shiny=$((RANDOM % SHINY_RATE == 0))

  _display_pokemon "${pokemon_list[$((pokemon_index - 1))]}" $is_shiny
}

# Display random Pokémon
function show_pokemon_random() {
  local pokemon_list selected_index pokemon_name is_shiny

  pokemon_list=($(_get_pokemon_list))
  [[ ${#pokemon_list[@]} -eq 0 ]] && echo "Error: Could not get Pokémon list" && return 1

  pokemon_index=$((RANDOM % ${#pokemon_list[@]} + 1))
  is_shiny=$((RANDOM % SHINY_RATE == 0))

  _display_pokemon "${pokemon_list[$((pokemon_index-1))]}" $is_shiny
}

# Main pokemon function
function pokemon(){
  local dir_weight=${1:-0}
  local random_weight=${2:-1}

  # If hash command is not available, force random mode
  if [[ -z "$_HASH_CMD" ]]; then
      dir_weight=0
  fi

  local total=$((dir_weight + random_weight))
  # Avoid division by zero error
  [[ $total -eq 0 ]] && return 0;

  local random=$((RANDOM % total))

  if ((random < dir_weight)); then
    show_pokemon_by_dir
  else
    show_pokemon_random
  fi
}

# Get Chinese Pokémon name by English name
get_cn_name_by_en_name() {
  local key="$1"
  echo "${pokemon_translations[$key]}"
}

# Map string to number array
function map_string_to_numbers() {
  local input="$1"
  # Use the determined hash command
  local hash=$(echo -n "$input" | $_HASH_CMD | awk '{print $1}')
  local count=$((3 + (16#${hash:0:2} & 3)))  # 3~5 numbers
  local -a numbers

  for ((i = 0; i < count; i++)); do
    local offset=$((2 + i * 8))
    [[ $((offset + 8)) -le 64 ]] || break
    local hex_chunk=${hash:$offset:8}
    numbers+=($((16#$hex_chunk)))
  done

  echo "${numbers[@]}"
}