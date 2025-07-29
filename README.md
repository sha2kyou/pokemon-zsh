# Pokémon Zsh - Oh My Zsh Plugin

这是一个为你的 Zsh 终端带来宝可梦惊喜的 Oh My Zsh 插件。它会让你在执行 `ls` 和 `cd` 命令时，有机会遇到随机的宝可梦！

<img width="283" height="229" alt="image" src="https://github.com/user-attachments/assets/c9d29bc9-806c-419b-9231-85c4de1e5210" />


## 功能

*   **`ls` 命令**: 每次执行 `ls` 时，都会在列出文件前显示一只与当前目录路径相关联的宝可梦。
*   **`cd` 命令**: 每次切换目录时，都有一定几率遇到一只随机的宝可梦。
*   **闪光宝可梦**: 有小概率会遇到稀有的闪光宝可梦！

## 前置依赖

在安装此插件之前，你必须先安装 [pokemon-colorscripts](https://gitlab.com/phoneybadger/pokemon-colorscripts)，这是本插件的核心依赖。

请按照其官方文档完成安装。

## 安装

1.  **克隆仓库**: 将此仓库克隆到你的 Oh My Zsh 自定义插件目录中。
    ```bash
    git clone https://github.com/sha2kyou/pokemon-zsh-script.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/pokemon-zsh
    ```

2.  **激活插件**: 打开你的 `.zshrc` 文件，找到 `plugins` 列表，然后添加 `pokemon-zsh`。
    ```zsh
    # 示例:
    plugins=(
      git
      zsh-syntax-highlighting
      # ... 其他插件
      pokemon-zsh
    )
    ```

3.  **重启终端**: 保存文件后，完全关闭并重新打开你的终端，或者在当前会话中运行 `source ~/.zshrc` 来使更改生效。

现在，享受在命令行中捕捉宝可梦的乐趣吧！
