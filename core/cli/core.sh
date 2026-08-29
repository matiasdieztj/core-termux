<<<<<<< SEARCH
#!/data/data/com.termux/files/usr/bin/bash
# Importar funciones de log y colores para el help
import "@/utils/log"
import "@/utils/colors"

core_main() {
    local cmd="$1"
    shift || true

    # si no se pasa comando
    if [[ -z "$cmd" ]]; then
        core_help
        return
    fi

    local command_file="$CORE_PATH/cli/commands/$cmd.sh"

    # check if the command exists
    if [[ -f "$command_file" ]]; then
        import "@/cli/commands/$cmd"
        "${cmd}_main" "$@"
    else
        log_error "Command not found: $cmd"
        echo
        core_help
        exit 1
    fi
}
=======
#!/data/data/com.termux/files/usr/bin/bash
# Importar funciones de log y colores para el help
import "@/utils/log"
import "@/utils/colors"
import "@/utils/optimizer"

core_main() {
    # Inicializar configuraciones de optimización de forma segura e interactiva
    check_or_prompt_preference
    setup_python_env
    setup_cargo_env

    local cmd="$1"
    shift || true

    # si no se pasa comando
    if [[ -z "$cmd" ]]; then
        core_help
        return
    fi

    local command_file="$CORE_PATH/cli/commands/$cmd.sh"

    # check if the command exists
    if [[ -f "$command_file" ]]; then
        import "@/cli/commands/$cmd"
        "${cmd}_main" "$@"
    else
        log_error "Command not found: $cmd"
        echo
        core_help
        exit 1
    fi
}
>>>>>>> REPLACE
