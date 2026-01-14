#!/bin/zsh

# This file is meant to be sourced by zsh.
# It defines functions for displaying Pokémon.

# Source the translations file
source "${0:a:h}/pokemon-translations.zsh"

# Global variables
SHINY_RATE=4096  # Shiny rate is 1/4096 (same as in the games)
CD_TRIGGER_RATE=6

# Check dependencies and set hash command
# Dependencies:
# 1. pokemon-colorscripts - for displaying Pokemon ASCII art
# 2. sha256sum or shasum - for directory hash functionality
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
  fi

  if command -v eza >/dev/null 2>&1; then
    command eza --icons "$@"
  else
    command ls "$@"
  fi
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

  # Validate parameters
  if [[ -z "$pokemon_name" || "$pokemon_name" == "null" ]]; then
    echo "[ERROR] Invalid pokemon name: '$pokemon_name'" >&2
    return 1
  fi

  local cn_pokemon_name
  cn_pokemon_name=$(get_cn_name_by_en_name "$pokemon_name")
  if [[ -z "$cn_pokemon_name" ]]; then
    cn_pokemon_name="宝可梦"
  fi

  local shiny_flag=""
  local message=""
  local shiny_colors=(31 32 33 34 35 36)  # Red, Green, Yellow, Blue, Purple, Cyan
  local random_color=${shiny_colors[$((RANDOM % ${#shiny_colors[@]} + 1))]}

  # Shiny
  if (( is_shiny == 1 )); then
    shiny_flag="-s"
    echo -e "✨ 野生的\033[${random_color}m\033[1m闪光${cn_pokemon_name}\033[0m出现了！✨"
  else
    message="野生的\033[1m${cn_pokemon_name}\033[0m出现了！"
    echo -e "${message}"
  fi

  # Display Pokemon ASCII art
  pokemon-colorscripts -n "$pokemon_name" --no-title -r ${shiny_flag}
  
  # Generate separator line based on terminal width
  local term_width=$(tput cols)
  local separator=$(printf '%*s' "$term_width" '' | tr ' ' '-')
  echo "$separator"
}

# Get Pokemon list
# Returns: Array of all available Pokemon names
# Uses caching to avoid repeated calls to pokemon-colorscripts command
function _get_pokemon_list() {
  # If cache is empty, fetch and cache the list
  if [[ -z $POKEMON_LIST_CACHE ]]; then
    POKEMON_LIST_CACHE=$(pokemon-colorscripts -l)
  fi

  local pokemon_list
  IFS=$'\n' pokemon_list=("${(f)POKEMON_LIST_CACHE}")

  # Check if list is empty
  if [[ ${#pokemon_list[@]} -eq 0 ]]; then
    echo "[ERROR] Failed to get pokemon list" >&2
    return 1
  fi
  
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
  # Fix index calculation
  pokemon_index=$(( (selected_number % ${#pokemon_list[@]}) + 1 ))
  # Add boundary check
  if (( pokemon_index < 1 || pokemon_index > ${#pokemon_list[@]} )); then
    echo "[ERROR] Invalid pokemon index: $pokemon_index" >&2
    return 1
  fi
  is_shiny=$(( (RANDOM % SHINY_RATE) == 0 ? 1 : 0 ))

  _display_pokemon "${pokemon_list[$pokemon_index]}" $is_shiny
}

# Display random Pokemon
# Randomly selects and displays a Pokemon from all available Pokemon
# Has a 1/SHINY_RATE chance of encountering a shiny Pokemon
function show_pokemon_random() {
  local pokemon_list pokemon_index is_shiny

  pokemon_list=($(_get_pokemon_list))
  [[ ${#pokemon_list[@]} -eq 0 ]] && echo "Error: Could not get Pokémon list" && return 1

  # Randomly select an index (1-based)
  pokemon_index=$((1 + RANDOM % ${#pokemon_list[@]}))

  # Check if the index is valid
  if (( pokemon_index < 1 || pokemon_index > ${#pokemon_list[@]} )); then
    echo "[ERROR] Invalid pokemon index: $pokemon_index" >&2
    return 1
  fi

  is_shiny=$(( (RANDOM % SHINY_RATE) == 0 ? 1 : 0 ))

  _display_pokemon "${pokemon_list[$pokemon_index]}" $is_shiny
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
  local count=$((3 + (16#${hash:0:2} & 3)))  # Generate 3-5 numbers
  local -a numbers

  for ((i = 0; i < count; i++)); do
    local offset=$((2 + i * 8))
    [[ $((offset + 8)) -le 64 ]] || break
    local hex_chunk=${hash:$offset:8}
    numbers+=($((16#$hex_chunk)))
  done

  echo "${numbers[@]}"
}