## 替换ls命令
function ls() {
  pokemon 15 1
  echo "----------------------------------------"
  command ls "$@"
}
## 替换cd命令
function cd() {
  builtin cd "$@"
  
  # 宝可梦跳出概率
  local TRIGGER_RATE=8
  if ((RANDOM % TRIGGER_RATE == 0)); then
    pokemon 5 5
  fi
}

## 跳出目录名映射显示宝可梦
function show_pokemon_by_dir() {
  local text lines num current_dir hash hash_int range mapped_value selected_pokemon

  text=$(pokemon-colorscripts -l)

  IFS=$'\n' lines=("${(f)text}")

  num=${#lines[@]}

  current_dir=$(pwd)

  hash=$(printf "%s" "$current_dir" | md5sum | awk '{print $1}')
  hash_int=$((0x${hash:0:8}))
  range=$((num))
  mapped_value=$((hash_int % range + 1))

  selected_pokemon=${lines[$((mapped_value-1))]}

  # echo "----------------------------------------"
  local SHINY_RATE=32
  if ((RANDOM % SHINY_RATE == 0)); then
    echo "✨野生的闪光宝可梦出现了！✨"
    pokemon-colorscripts -n "$selected_pokemon" --no-title -r -s
  else
    echo "野生的宝可梦出现了。"
    pokemon-colorscripts -n "$selected_pokemon" --no-title -r
  fi
}

## 跳出随机宝可梦
function show_pokemon_random() {
  # echo "----------------------------------------"
  local SHINY_RATE=64
  if ((RANDOM % SHINY_RATE == 0)); then
    echo "✨野生的闪光宝可梦出现了！✨"
    pokemon-colorscripts -r -s --no-title
  else
    echo "野生的宝可梦出现了。"
    pokemon-colorscripts -r --no-title
  fi
}

## 宝可梦函数，$1为目录名映射宝可梦跳出概率，$2为随机宝可梦跳出概率
function pokemon(){
  local a=${1:-0}
  local b=${2:-1}

  local total=$((a + b))

  local random=$((RANDOM % total))

  if ((random < a)); then
    show_pokemon_by_dir
  else
    show_pokemon_random
  fi
}