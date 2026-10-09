#!/usr/bin/env bash
# terminal/fzf 的 env 测试。
#
#   bash tests/env_test.sh
#
# 测三件事：
#   ① 两个 env 文件都把本仓库的 bin/ 放进 PATH，fzf 解析到本仓库的 bin/fzf；
#   ② 真 tty 下键绑定 / widget / 补全还在（补全和快捷键都靠 fzf.zsh / fzf.bash）；
#   ③ **无 tty 的交互式 zsh** 里 source env.zsh 不许打印
#      `can't change option: zle` —— 这是 2026-10-09 修的那条回归
#      （fzf.zsh 恢复选项快照时碰了 `zle`，而 zsh 在没有终端时不允许改它；
#      只删报错不改行为的那一半由"选项快照仍逐项还原"那条钉住）。
#
# "无 tty"怎么构造：`setsid` 开一个新会话 —— 新会话没有控制终端（ctty），
# zsh 的 $TTY 因此为空，`setopt zle` 会被拒绝（zsh 5.9 实测）。只有把
# stdin/stdout 重定向到文件是不够的：在终端里跑时进程仍有 ctty，不会复现。
# 探针会自己打印 MARK_TTY=[...]：**只有它是空的**，那两条断言才算数
# （构造不出来时打印跳过，而不是假装通过）。
#
# 没装 zsh 就只测 bash（bash 版存在的意义就是"没有 zsh 的机器"）。
# 缺 `script`（util-linux）时真 tty 那两条跳过。
set -u

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
proj=$(cd -- "$here/.." && pwd)

pass=0; fail=0
ok ()   { pass=$((pass + 1)); printf '  ok   %s\n' "$*"; }
bad ()  { fail=$((fail + 1)); printf '  FAIL %s\n' "$*"; }
skip () { printf '  --   %s（跳过：%s）\n' "$1" "$2"; }

tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

# ── 0. 文件都在 ───────────────────────────────────────────────────────
if [ -r "$proj/fzf.zsh" ] && [ -r "$proj/fzf.bash" ] && [ -x "$proj/bin/fzf" ]; then
    ok "fzf.zsh / fzf.bash / bin/fzf 都在"
else
    bad "缺文件：fzf.zsh / fzf.bash / bin/fzf 有一个不在"
fi

have_zsh=0;  command -v zsh  >/dev/null 2>&1 && have_zsh=1
have_sh=0;   command -v bash >/dev/null 2>&1 && have_sh=1
have_tty=0;  command -v script >/dev/null 2>&1 && have_tty=1
have_setsid=0; command -v setsid >/dev/null 2>&1 && have_setsid=1

# ── 探针：写进临时目录，别在测试里跟引号打架 ──────────────────────────
cat > "$tmp/where.zsh" <<'EOS'
source "$WTOOL_PROJECT_DIR/env.zsh"
print -r -- "fzf=$(whence -p fzf)"
EOS
cat > "$tmp/where.bash" <<'EOS'
. "$WTOOL_PROJECT_DIR/env.bash"
printf 'fzf=%s\n' "$(command -v fzf)"
EOS
cat > "$tmp/keys.zsh" <<'EOS'
source "$WTOOL_PROJECT_DIR/env.zsh"
print -r -- "R=$(bindkey '^R')"
print -r -- "I=$(bindkey '^I')"
print -r -- "T=$(bindkey '^T')"
print -r -- "widgets=$(print -rl -- ${(k)functions} | grep -c '^fzf-')"
EOS
cat > "$tmp/keys.bash" <<'EOS'
. "$WTOOL_PROJECT_DIR/env.bash"
printf 'types=%s %s\n' "$(type -t fzf-file-widget)" "$(type -t __fzf_history__)"
printf 'xbindings=%s\n' "$(bind -X 2>/dev/null | grep -c fzf)"
printf 'completions=%s\n' "$(complete -p 2>/dev/null | grep -c _fzf)"
EOS
# 无 tty 探针：先报自己的 $TTY（证明真的没终端），再 source，再比选项快照。
cat > "$tmp/notty.zsh" <<'EOS'
print -r -- "MARK_TTY=[$TTY]"
before=$(set -o)
source "$WTOOL_PROJECT_DIR/env.zsh"
after=$(set -o)
if [[ $before == $after ]]; then
    print -r -- "OPTIONS=same"
else
    print -r -- "OPTIONS=different"
    diff <(print -r -- "$before") <(print -r -- "$after")
fi
EOS

# ── ① / ②：两个 shell 各两条（同一张用例表）────────────────────────────
if [ "$have_zsh" = 1 ]; then
    echo "== zsh =="
    got=$(WTOOL_PROJECT_DIR="$proj" zsh -f "$tmp/where.zsh" 2>&1 | sed -n 's/^fzf=//p')
    if [ "$got" = "$proj/bin/fzf" ]; then ok "zsh：fzf 解析到本仓库的 bin/fzf"
    else bad "zsh：fzf 没解析到本仓库（[$got]）"; fi

    if [ "$have_tty" = 1 ]; then
        out=$(WTOOL_PROJECT_DIR="$proj" script -qec "zsh -fi $tmp/keys.zsh" /dev/null 2>&1 | tr -d '\r')
        r=$(printf '%s\n' "$out" | sed -n 's/^R=//p'); i=$(printf '%s\n' "$out" | sed -n 's/^I=//p')
        t=$(printf '%s\n' "$out" | sed -n 's/^T=//p'); w=$(printf '%s\n' "$out" | sed -n 's/^widgets=//p' | tr -cd '0-9')
        if printf '%s' "$r" | grep -q fzf-history-widget \
           && printf '%s' "$i" | grep -q fzf-completion \
           && printf '%s' "$t" | grep -q fzf-file-widget \
           && [ "${w:-0}" -ge 4 ]; then
            ok "zsh 真 tty：^R/^I/^T 绑上了、fzf-* widget 在（$w 个）"
        else
            bad "zsh 真 tty：键绑定或 widget 不对 [R=$r I=$i T=$t widgets=$w]"
        fi
    else
        skip "zsh 真 tty：键绑定 / widget" "没有 script 命令"
    fi
else
    echo "== zsh：跳过（没装 zsh）=="
    skip "zsh：fzf 解析到本仓库" "没装 zsh"
    skip "zsh 真 tty：键绑定 / widget" "没装 zsh"
fi

if [ "$have_sh" = 1 ]; then
    echo "== bash =="
    got=$(WTOOL_PROJECT_DIR="$proj" bash --noprofile --norc "$tmp/where.bash" 2>&1 | sed -n 's/^fzf=//p')
    if [ "$got" = "$proj/bin/fzf" ]; then ok "bash：fzf 解析到本仓库的 bin/fzf"
    else bad "bash：fzf 没解析到本仓库（[$got]）"; fi

    if [ "$have_tty" = 1 ]; then
        out=$(WTOOL_PROJECT_DIR="$proj" script -qec "bash --noprofile --norc -i $tmp/keys.bash" /dev/null 2>&1 | tr -d '\r')
        types=$(printf '%s\n' "$out" | sed -n 's/^types=//p')
        xb=$(printf '%s\n' "$out" | sed -n 's/^xbindings=//p' | tr -cd '0-9')
        cp=$(printf '%s\n' "$out" | sed -n 's/^completions=//p' | tr -cd '0-9')
        case $types in
            "function function") t_ok=1 ;;
            *) t_ok=0 ;;
        esac
        # bash 侧：^T → fzf-file-widget、^R → __fzf_history__（都是 bind -x），
        # 补全靠 `complete -F ... _fzf*` 重挂（不是像 zsh 那样接管 Tab）。
        if [ "$t_ok" = 1 ] && [ "${xb:-0}" -ge 2 ] && [ "${cp:-0}" -ge 1 ]; then
            ok "bash 真 tty：^R/^T 的 -x 绑定在（$xb 个）、$cp 条补全挂着"
        else
            bad "bash 真 tty：widget / -x 绑定 / 补全不对 [types=$types xbindings=$xb completions=$cp]"
        fi
    else
        skip "bash 真 tty：widget / -x 绑定" "没有 script 命令"
    fi
else
    echo "== bash：跳过（没装 bash）=="
    skip "bash：fzf 解析到本仓库" "没装 bash"
    skip "bash 真 tty：widget / -x 绑定" "没装 bash"
fi

# ── ③：无 tty 的两条回归（zsh 专属；bash 没有选项快照这回事）──────────
# fzf.bash 里没有 `options=(...)` / `setopt` 那套快照恢复（`grep -c setopt fzf.bash`
# = 0），所以这两条只对 zsh 有意义。
echo "== 无 tty（zsh 专属回归）=="
if [ "$have_zsh" = 1 ]; then
    if [ "$have_setsid" = 1 ]; then
        notty_out=$(WTOOL_PROJECT_DIR="$proj" setsid zsh -fi "$tmp/notty.zsh" 2>&1)
    else
        notty_out=$(WTOOL_PROJECT_DIR="$proj" zsh -fi "$tmp/notty.zsh" </dev/null 2>&1)
    fi
    case $notty_out in
        *'MARK_TTY=[]'*) ttyless=1 ;;
        *)               ttyless=0 ;;
    esac
    if [ "$ttyless" = 1 ]; then
        case $notty_out in
            *"can't change option"*)
                bad "无 tty 时打印了 can't change option（fzf.zsh 的选项快照又碰 zle 了）：$(printf '%s' "$notty_out" | tr '\n' '|')" ;;
            *)
                ok "无 tty 时 source env.zsh 不打印 can't change option: zle" ;;
        esac
        case $notty_out in
            *"OPTIONS=same"*) ok "无 tty 时选项快照仍逐项还原（source 前后 set -o 相同）" ;;
            *) bad "无 tty 时选项没还原干净：$(printf '%s' "$notty_out" | tr '\n' '|')" ;;
        esac
    else
        skip "无 tty 的两条回归" "构造不出无 tty（缺 setsid，且当前环境有 tty；探针报 $(printf '%s' "$notty_out" | sed -n '1p')）"
    fi
else
    skip "无 tty 的两条回归" "没装 zsh"
fi

printf '\n%d 通过, %d 失败\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
