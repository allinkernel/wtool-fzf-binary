# terminal/fzf —— fzf 二进制 + 官方的按键/补全脚本

从 `~/source/mytool/fzf`（原 `wsw-fzf-static`）迁移过来的 **fzf 二进制 + 补全脚本**：
`env.zsh` / `env.bash` 把本项目的 `bin/` 加进 `PATH`，再 source 官方的
`fzf.zsh` / `fzf.bash`，于是 **Ctrl-T / Ctrl-R / Alt-C 三个快捷键**和 **`**` 补全**就位。

**本项目是"多 shell"的例子**：`wtool.xml` 里一个 `<zshrc>` + 一个 `<bashrc>`，
框架分别往 `~/.zshrc` 和 `~/.bashrc` 注入对应的受管块。

- 项目 id：`terminal/fzf`，`priority=60`（在 `tools/git-repo-sh-tools`(40) / `terminal/tmux`(50) 之后加载）
- 本仓库没有 `scripts/`（不需要构建/安装脚本），也没有测试

---

## 功能说明

### 1. 两个 env 文件做了什么

| 文件 | 给谁 | 做两件事 |
|---|---|---|
| `env.zsh` | zsh | ① `export PATH="$WTOOL_PROJECT_DIR/bin:$PATH"`；② 文件可读就 `source "$WTOOL_PROJECT_DIR/fzf.zsh"` |
| `env.bash` | bash | 同样两件事，source 的是 `fzf.bash` |

- 两个文件里都有一行兜底：`WTOOL_PROJECT_DIR` 没设时用
  `$HOME/.wtool/wtool-work-dir/links/terminal/fzf`。
- **env 文件自己不设任何 `FZF_*` 变量**，也不做别的 PATH 操作 —— 所有可调项都在下面的
  「配置项」里，由你自己设。
- `bin/fzf` 是**静态链接的 x86-64 Linux 可执行文件**（`file` 说的），版本
  **0.67.0 (2ab923f3)**（`./bin/fzf --version` 说的）。

### 2. 三个快捷键（两个 shell 都有）

| 键 | widget（zsh） / 函数（bash） | 做什么 |
|---|---|---|
| `Ctrl-T` | `fzf-file-widget` | 在当前目录树里选文件/目录，把选中项的路径**贴到命令行**（可多选） |
| `Ctrl-R` | `fzf-history-widget`（zsh）/ `__fzf_history__`（bash） | 在命令历史里搜索，选中项贴到命令行 |
| `Alt-C` | `fzf-cd-widget`（zsh）/ `__fzf_cd__`（bash） | 选一个目录并 `cd` 过去 |

三个键的选单都用 `--reverse --walker=... --scheme=path` 之类的默认参数打开
（`Ctrl-T` / `Alt-C` 走文件树 walker；`Ctrl-R` 走 `--scheme=history`，
多行历史用 `--read0` 传，按 `Ctrl-R` 可在"排序/原始"之间切换）。

**可以单独关掉某一个键**：脚本对每个键都判断
`${FZF_CTRL_T_COMMAND-x} != ""`（`Ctrl-R`、`Alt-C` 同理）——
把这个变量**显式设成空字符串**，对应的键就不绑定了。

### 3. 补全（`**` 触发）

- **触发串**：`**`（`FZF_COMPLETION_TRIGGER` 可改；设成空串则"任何 Tab 都走 fzf"）。
  例：`vim **<Tab>`、`cd **<Tab>`、`kill **<Tab>`、`ssh **<Tab>`。
- **zsh**：`fzf-completion` 接管 Tab（`bindkey '^I' fzf-completion`），
  认得出命令名时走专用补全：
  `ssh` / `telnet`（主机名，来自 `~/.ssh/config`、`~/.ssh/config.d/*`、`~/.ssh/known_hosts`、`/etc/hosts`）、
  `export` / `unset` / `unalias`、`kill`（进程表，表头可点）；
  其余走路径补全，目录类命令（默认 `cd pushd rmdir`，见 `FZF_COMPLETION_DIR_COMMANDS`）走目录补全。
- **bash**：装了 bash-completion 时，上面这些命令**不打 `**`** 也能直接进 fzf；
  `**` 触发串同样支持。它还预置了一批命令的路径补全
  （`FZF_COMPLETION_PATH_COMMANDS` / `FZF_COMPLETION_VAR_COMMANDS`，
  例如 `ls` / `cat` / `vim` / `git` / `grep` / `ssh` …；变量类 `export` / `unset` / `printenv`），
  并给 `fzf` / `fzf-tmux` 自己做了选项补全（`complete -o default -F _fzf_opts_completion fzf`）。
  > 这两个 `*_COMMANDS` 变量**只在 bash 版里有**，zsh 版没有。
- 原有的 bash 补全不会被顶掉：脚本会先记下旧补全，再在它外面套一层 fzf。

### 4. 在 tmux 里

装了 tmux 并设了 `FZF_TMUX=1`（或给了 `FZF_TMUX_OPTS`）时，三个快捷键和补全改用
`fzf-tmux`（弹在 tmux 弹窗里），参数由 `FZF_TMUX_OPTS` 决定，默认 `-d<FZF_TMUX_HEIGHT>`。

> ⚠️ **`fzf-tmux` 这个命令不在本仓库里** —— 本仓库只有 `bin/fzf`。
> 要这段能力得自己保证 `fzf-tmux` 在 `PATH` 上（见「排错」）。

---

## 安装（由 wtool 统一管）

安装由 wtool 统一管：见 [wtool 的 README（GitHub：allinkernel/wtool）](https://github.com/allinkernel/wtool/blob/main/README.md) ——
本仓库只是源码/配置（一个二进制 + 两个官方脚本 + 两个 env），
装的时候是 `wtool install terminal/fzf`（项目 id 就是它在清单里的 path）。

## 配置项

本仓库**自己不设任何变量**；下面这些是 `fzf.zsh` / `fzf.bash` 会读的（默认值取自脚本里的写法）。
两个 shell 都生效的：

| 变量 | 默认 | 作用 |
|---|---|---|
| `FZF_DEFAULT_OPTS` | 空 | 追加给**每次** fzf 调用的选项 |
| `FZF_DEFAULT_OPTS_FILE` | 空 | 选项文件（脚本会 `cat` 进选项里） |
| `FZF_DEFAULT_COMMAND` | 空 | 没有输入时的候选来源；三个快捷键会临时用各自的 `FZF_*_COMMAND` 覆盖它 |
| `FZF_TMUX` | `0` | 非 0 且在 tmux 里 → 用 `fzf-tmux` |
| `FZF_TMUX_OPTS` | 空 | 传给 `fzf-tmux` 的参数（给了它就相当于打开 tmux 模式） |
| `FZF_TMUX_HEIGHT` | `40%` | `--height` 的默认值 / `fzf-tmux -d` 的默认值 |
| `FZF_CTRL_T_COMMAND` | 空 | `Ctrl-T` 的候选来源（**显式设空串 = 关掉这个键**） |
| `FZF_CTRL_T_OPTS` | 空 | `Ctrl-T` 的额外选项（默认已带 `-m` 多选） |
| `FZF_CTRL_R_COMMAND` | 空 | `Ctrl-R` 的候选来源（设成非空会打印一行"暂不支持自定义命令"的警告） |
| `FZF_CTRL_R_OPTS` | 空 | `Ctrl-R` 的额外选项 |
| `FZF_ALT_C_COMMAND` | 空 | `Alt-C` 的候选来源（显式设空串 = 关掉这个键） |
| `FZF_ALT_C_OPTS` | 空 | `Alt-C` 的额外选项 |
| `FZF_COMPLETION_TRIGGER` | `**` | 补全触发串 |
| `FZF_COMPLETION_OPTS` | 空 | 补全时追加的选项 |
| `FZF_COMPLETION_PATH_OPTS` | 空 | 路径补全追加的选项 |
| `FZF_COMPLETION_DIR_OPTS` | 空 | 目录补全追加的选项 |
| `FZF_COMPLETION_DIR_COMMANDS` | `cd pushd rmdir` | 哪些命令按"目录"补全 |

只有 bash 版读的：`FZF_COMPLETION_PATH_COMMANDS`、`FZF_COMPLETION_VAR_COMMANDS`
（默认是一长串命令名，见 `fzf.bash` 里的 `a_cmds` / `v_cmds`）。

脚本内部还有两个名字（别去设）：`__fzf_awk`（挑 awk：Solaris 用 `/usr/xpg4/bin/awk`、
mawk 够新就用 mawk）、`fzf_default_completion`（记下接管前的 Tab 绑定，用来回退）。

## 快捷键

| 键 | 什么时候有 | 作用 |
|---|---|---|
| `Ctrl-T` | 交互式 shell，且 `FZF_CTRL_T_COMMAND` 不是"显式空串" | 选文件/目录路径贴到命令行 |
| `Ctrl-R` | 交互式 shell，且 `FZF_CTRL_R_COMMAND` 不是"显式空串" | 搜历史命令 |
| `Alt-C` | 交互式 shell，且 `FZF_ALT_C_COMMAND` 不是"显式空串" | 选目录并 `cd` |
| `Tab` | zsh：`fzf-completion` 接管；bash：叠加在原有补全上 | `**` 触发补全 |
| `Ctrl-Z`（bash 版额外） | 交互式 bash | 在 vi / emacs 编辑模式之间切换（`fzf.bash` 自己绑的） |
| `Alt-R`（bash 版额外） | 交互式 bash | `redraw-current-line` |

> zsh 的 `Ctrl-T` / `Ctrl-R` / `Alt-C` 三个键在 `emacs` / `viins` / `vicmd` 三种 keymap
> 里都绑了；bash 同样在 `emacs-standard` / `vi-command` / `vi-insert` 里绑。
> **非交互式 shell 里什么都不绑**（zsh 判 `[[ -o interactive ]]`，bash 判 `$-` 里有没有 `i`）。

## 排错

| 现象 | 原因 / 怎么办 |
|---|---|
| `Ctrl-T` / `Ctrl-R` / `Alt-C` 没反应 | ① 这个键的 `FZF_*_COMMAND` 被显式设成了空串（`echo "[${FZF_CTRL_T_COMMAND-x}]"` 看是 `[]` 还是 `[x]`）；② 不在交互式 shell 里；③ 项目的 env 没被 source（`echo $WTOOL_PROJECT_DIR`、`type fzf`） |
| `Tab` 不再是原来的补全 | zsh 版会接管 Tab（`bindkey '^I'`）；它把原绑定记在 `fzf_default_completion` 里，`echo ${fzf_default_completion}` 就是原来的 widget |
| 提示 `fzf-tmux: command not found` | 在 tmux 里设了 `FZF_TMUX` / `FZF_TMUX_OPTS`，但 `fzf-tmux` 不在 `PATH` 上 —— **本仓库只有 `bin/fzf`，没有 `fzf-tmux`**；要么装上它，要么把 `FZF_TMUX` 设回 0 |
| 提示 `warning: FZF_CTRL_R_COMMAND is set to a custom command, but custom commands are not yet supported for CTRL-R` | 这个版本不支持给 `Ctrl-R` 换候选来源；把变量去掉即可 |
| `fzf: cannot execute binary file` / 段错误 | `bin/fzf` 是 **x86-64 Linux 静态二进制**；ARM 机器 / macOS 上跑不了，得换对应架构的 |
| `fzf --version` 不是 0.67.0 | `PATH` 里排在前面的是别处装的 fzf；本项目的 `bin/` 是**插在最前面**的，`type -a fzf` 看谁在前面 |
| 补全候选里没有隐藏文件 / 范围不对 | 补全默认带 `--walker=file,dir,follow,hidden`；想换候选就覆盖 `_fzf_compgen_path` / `_fzf_compgen_dir`（zsh）或用 `FZF_COMPLETION_PATH_OPTS` / `FZF_COMPLETION_DIR_OPTS` |

## 测试

**本仓库没有测试** —— `git ls-files` 里没有 `tests/`（工作区其它项目多数有，
这个项目从 mytool 迁过来时就没带）。所以改完只能人工核对，最低限度：

```sh
./bin/fzf --version            # 期望：0.67.0 (2ab923f3)
file bin/fzf                   # 期望：ELF 64-bit LSB executable, x86-64, statically linked

# zsh：PATH 指到本仓库的 bin、widget 定义好了、Tab 被接管
zsh -ic 'WTOOL_PROJECT_DIR=$PWD; source env.zsh; whence -p fzf;
         (( $+functions[fzf-file-widget] )) && echo widget-ok; bindkey "^I" | head -1'

# bash：同样，外加三个键真的绑上了（-x 绑定的用 bind -X 看，宏用 bind -s 看）
bash -ic 'WTOOL_PROJECT_DIR=$PWD; . env.bash; type -p fzf; type -t fzf-file-widget;
          bind -X | grep -i fzf; bind -m emacs-standard -s | grep "\\\\ec"'
```

> `WTOOL_PROJECT_DIR=$PWD` 是**故意**写上的：这台机器上 shell 启动时可能已经带着
> 别的项目的 `WTOOL_PROJECT_DIR`（旧安装留下的），不钉住的话 `type fzf` 测的就不是本仓库。
> 这些命令**这次都跑过**：`bin/fzf` 两个 shell 里都解析到本仓库的 `bin/fzf`，
> `fzf-file-widget` 在，bash 侧 `"\C-r"` / `"\C-t"` / `"\ec"` 三个键都能查到。
> 但这不等于"按键真的能用" —— 那要人在交互式终端里按一次才算。
> 另外，没有 tty 的环境里跑 `zsh -ic` 会看到几行 `can't change option: zle`：
> 那是 `zle -N` 在无 tty 时失败了（本机验证环境的现象），不是配置错。

## 与 mytool 版本的差异

| 原 mytool | 现在 | 原因 |
|---|---|---|
| 一个 `wsw_env.sh` 里用 `${(%):-%x}` / `BASH_SOURCE` 判断当前 shell | 拆成 `env.zsh` + `env.bash` | 由清单声明归属，不再靠运行时猜 |
| `fzf`（软链）+ `fzf-0.67/fzf`（真实文件）两层 | 只保留 `bin/fzf` | 去掉冗余软链 |
| `THIS_DIR` 由脚本自己算 | `$WTOOL_PROJECT_DIR/bin` | 加载器已导出稳定地址 |

## 文件

| 文件 | 作用 |
|---|---|
| `wtool.xml` | 清单：1 个 `<zshrc>` + 1 个 `<bashrc>`（无 link） |
| `env.zsh` / `env.bash` | 各自的 PATH + 补全脚本 source |
| `bin/fzf` | fzf 0.67.0 的静态 x86-64 二进制（4.4 MB） |
| `fzf.zsh` | 官方 `key-bindings.zsh` + `completion.zsh` 拼在一起，由 `env.zsh` source |
| `fzf.bash` | 官方 `key-bindings.bash` + `completion.bash` 拼在一起，由 `env.bash` source |

## 待改进（未做，保持行为不变）

- **4.4MB 二进制入库**。更干净的做法是改为从 GitHub Release 下载 + 校验和，
  但那条路属于"不可逆的系统层操作"，等引擎走通再迁移。现在保持原样。
- 版本停留在 0.67.0，升级需替换 `bin/fzf`（以及同版本的 `fzf.zsh` / `fzf.bash`）并重新提交。
- `fzf-tmux` 没进仓库，tmux 弹窗模式实际用不了（见「排错」）。
