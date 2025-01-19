# ------------------------------------ Python ---------------------------------- 

pydbw() {
    echo "python -Xfrozen_modules=off -m debugpy --listen 5678 --wait-for-client $@"
    echo "Use 'pydb -m' for modules"
    echo "May need to activate venv\n"
    echo "Waiting for debugger to attach..."
    exec python -Xfrozen_modules=off -m debugpy --listen 5678 --wait-for-client "$@"
}

pydb() {
    echo "python -Xfrozen_modules=off -m debugpy --listen 5678 $@"
    echo "Use 'pydb -m' for modules"
    echo "May need to activate venv"
    exec python -Xfrozen_modules=off -m debugpy --listen 5678 "$@"
}
