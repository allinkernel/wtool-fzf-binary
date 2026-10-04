# AGENTS.md（terminal/fzf）

> 给后续的 AI 助手看。用户级规则在 `~/.dsh/AGENTS.md`，工作区规则在根目录 `AGENTS.md`；
> 本文件只讲**动这个仓库**必须知道的事。

## 1. README.md 是这个项目给用户的完整功能说明书

- **代码/配置一有变化，必须同步更新本仓库的 `README.md`** —— 别让 README 和代码说两种话。
  改了 `env.zsh` / `env.bash` 的 PATH 或 source 逻辑、换了 `bin/fzf` 的版本、
  重导了 `fzf.zsh` / `fzf.bash`（快捷键或 `FZF_*` 变量变了），都要回到 README 对应那一行改。
- **README 里不写"怎么装"** —— 安装统一由 wtool 管，README 的「安装」一节只有一句话
  加一个链接，指向 GitHub 上的 wtool README（`allinkernel/wtool` 仓库的 `README.md`）。
  项目自己的 `install.sh` / `uninstall.sh` 已经退休，**别把它们写进文档**，
  也别在文档里叫用户直接跑。
- **README 的章节结构**（改动时保持这个骨架，别自创一套）：

  | 章节 | 写什么 |
  |---|---|
  | 功能说明 | 这个项目**到底提供什么**：PATH 里多了什么、source 了哪个脚本、快捷键和补全怎么工作、tmux 模式怎么触发 |
  | 安装（由 wtool 统一管） | 一句话 + wtool README 链接；本仓库只是源码/配置 |
  | 配置项 | 读哪些 `FZF_*` 变量、默认值、哪些只有 bash 版认 |
  | 快捷键 | 每个键绑在哪、什么条件下才绑、怎么单独关掉 |
  | 排错 | 现象 → 原因 → 怎么办（报错原文要抄对） |
  | 测试 | 本仓库没有测试，给人工冒烟命令 |
  | 文件 | 每个文件一句话 |
  | 待改进 | 已知的、故意没做的事（二进制入库、`fzf-tmux` 缺失……） |

- **只写从代码里读出来的东西。** 快捷键、widget 名、变量名、默认值、报错文字都要对着
  `env.zsh` / `env.bash` / `fzf.zsh` / `fzf.bash` / `wtool.xml` 核过再写；
  核不实的宁可不写。

## 2. 这个仓库的硬规矩

- **`env.zsh` 和 `env.bash` 必须同改。** 两个 shell 的 PATH 处理、source 的目标文件、
  兜底的 `WTOOL_PROJECT_DIR` 默认值要一一对应。
- `fzf.zsh` / `fzf.bash` 是**上游 fzf 的生成物**（`key-bindings.*` + `completion.*` 拼在一起，
  里面还留着 "Do not directly edit this section" 的注释）。要改就**整份换成同一个 fzf
  版本的上游文件**，别手改中间那几段。
- **`bin/fzf` 是入库的二进制**（历史遗留，约 4.4 MB），换它必须同时换同一版本的
  `fzf.zsh` / `fzf.bash`，并在 README 里写清版本号（版本号用 `./bin/fzf --version` 读出来，
  别按文件名猜）。
- `wtool.xml` 里**没有 `id=` 属性**：项目身份就是它在工作区里的路径 `terminal/fzf`
  （ADR-0037，写了 `id=` 引擎会硬报错）—— 中转链接路径
  `~/.wtool/wtool-work-dir/links/terminal/fzf`、rc 块名（`# >>> wtool:terminal/fzf`）
  都用这个路径；`priority=60` 要排在 `tools/git-repo-sh-tools`(40) / `terminal/tmux`(50) 之后。
- **装 / 测只在容器里做**：本机（WSL）是临时的手工环境，wtool 调通之前不在本地落地；
  真机上 `wtool install terminal/fzf` **必须由用户明确同意**（用户级 `~/.dsh/AGENTS.md` 的硬规矩）。
- 别在 env 文件里**替用户设 `FZF_*` 默认值** —— 现在的约定是"env 只加 PATH + source 脚本，
  可调项留给用户"。

## 3. 验证（改完必须做）

本仓库**没有测试**（没有 `tests/`），只能人工冒烟；README「测试」一节里那几条命令
要照着跑一遍，确认 `bin/fzf` 解析到本仓库、widget 定义存在、三个键在 bash 里能查到。
最低限度：

```sh
zsh  -n env.zsh && zsh  -n fzf.zsh            # 语法
bash -n env.bash && bash -n fzf.bash
./bin/fzf --version
file bin/fzf                                  # 确认还是 x86-64 静态二进制
zsh -ic 'WTOOL_PROJECT_DIR=$PWD; source env.zsh; whence -p fzf'
bash -ic 'WTOOL_PROJECT_DIR=$PWD; . env.bash; bind -X | grep -i fzf'
```

- 冒烟命令里**要钉住 `WTOOL_PROJECT_DIR`**：机器上可能残留别的项目的值，
  不钉住测的就不是本仓库。
- 没有 tty 时 `zsh -ic` 会打印 `can't change option: zle`，那是环境现象，不是配置错。
- 提交只提交到 `ds_dev`，`git add` 之前先 `git diff` 看一遍；不 push、不动 `main`。
