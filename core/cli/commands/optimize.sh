#!/data/data/com.termux/files/usr/bin/bash
# core/cli/commands/optimize.sh — Controlador del comando 'core optimize'
import "@/utils/log"
import "@/utils/colors"
import "@/utils/optimizer"

optimize_main() {
    local action="$1"

    case "$action" in
        --status|-s)
            local pref=$(get_preference)
            separator
            box "ESTADO DE OPTIMIZACIÓN"
            if [ "$pref" == "space" ]; then
                log_success "Prioridad actual: EFICIENCIA DE ESPACIO"
                list_item "Python (uv): Enlaces simbólicos (symlink) activos."
                list_item "Rust (Cargo): Estrategia 'Compila y Limpia' activa."
                list_item "Node.js (pnpm): Almacén compartido activo."
            else
                log_info "Prioridad actual: RENDIMIENTO BRUTO"
                list_item "Python (uv): Copias físicas independientes."
                list_item "Rust (Cargo): Compilaciones incrementales persistentes (sccache)."
                list_item "Node.js (bun): Descargas ultra rápidas (copyfile)."
            fi
            separator
            ;;
        --space)
            mkdir -p "$(dirname "$PREF_FILE")"
            echo "space" > "$PREF_FILE"
            setup_python_env
            setup_cargo_env
            log_success "Entorno configurado para: EFICIENCIA DE ESPACIO"
            ;;
        --perf)
            mkdir -p "$(dirname "$PREF_FILE")"
            echo "performance" > "$PREF_FILE"
            setup_python_env
            setup_cargo_env
            log_success "Entorno configurado para: RENDIMIENTO BRUTO"
            ;;
        *)
            box "Core Optimize"
            log_info "Usage: core optimize [option]"
            echo
            echo -e "${D_GREEN}Opciones:${D_NC}"
            printf "    ${D_CYAN}%-16s${D_NC} %s\n" "--status, -s" "Mostrar el estado actual de las optimizaciones"
            printf "    ${D_CYAN}%-16s${D_NC} %s\n" "--space" "Cambiar globalmente al modo de ahorro de espacio"
            printf "    ${D_CYAN}%-16s${D_NC} %s\n" "--perf" "Cambiar globalmente al modo de rendimiento bruto"
            echo
            ;;
    esac
}
