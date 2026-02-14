THIS_FILE=$( [ -n "$BASH_SOURCE" ] && echo "${BASH_SOURCE[0]}" || echo "${(%):-%x}" )
THIS_DIR=$(cd "$(dirname "$THIS_FILE")" && pwd)

export PATH=${THIS_DIR}:${PATH}
