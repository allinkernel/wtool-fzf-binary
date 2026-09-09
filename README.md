# terminal/fzf

从 `~/source/mytool/fzf`（原 `wsw-fzf-static`）迁移过来的 fzf 二进制 + 补全脚本。

**本项目演示"多 shell"**：`wtool.xml` 里声明了两个 `<env>`，框架会分别往
`~/.zshrc` 和 `~/.bashrc` 注入对应的受管块。

## 安装

```sh
./install.sh      # zsh 和 bash 各写一个块
./uninstall.sh    # 两个块一起撤销
```

> 首次（尚未 `git init`）需 `--force`；提交后不需要。

## 做了什么

| 动作 | 结果 |
|---|---|
| 建中转链接 | `~/.wtool/links/terminal/fzf` → 本仓库 |
| 注入 `~/.zshrc` | 块 source `env.zsh`：把 `bin/` 加入 PATH，source `fzf.zsh` |
| 注入 `~/.bashrc` | 块 source `env.bash`：把 `bin/` 加入 PATH，source `fzf.bash` |

## 与 mytool 版本的差异

| 原 mytool | 现在 | 原因 |
|---|---|---|
| 一个 `wsw_env.sh` 里用 `${(%):-%x}` / `BASH_SOURCE` 判断当前 shell | 拆成 `env.zsh` + `env.bash` | 由清单声明归属，不再靠运行时猜 |
| `fzf`（软链）+ `fzf-0.67/fzf`（真实文件）两层 | 只保留 `bin/fzf` | 去掉冗余软链 |
| `THIS_DIR` 由脚本自己算 | `$WTOOL_PROJECT_DIR/bin` | 加载器已导出稳定地址 |

## 待改进（未做，保持行为不变）

- **4.4MB 二进制入库**。更干净的做法是改为从 GitHub Release 下载 + 校验和，
  但那属于 `provision`（不可逆操作），等引擎实现后再迁移。现在保持原样。
- 版本停留在 fzf 0.67，升级需替换 `bin/fzf` 并重新提交。

## 文件

| 文件 | 作用 |
|---|---|
| `wtool.xml` | 清单：2 个 env（zsh + bash），无 link |
| `env.zsh` / `env.bash` | 各自的 PATH + 补全脚本 source |
| `bin/fzf` | 二进制 |
| `fzf.zsh` / `fzf.bash` | 官方补全/快捷键脚本 |
| `install.sh` / `uninstall.sh` | bootstrap 存根 |
