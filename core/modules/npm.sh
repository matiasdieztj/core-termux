#!/data/data/com.termux/files/usr/bin/bash
import "@/utils/log"
import "@/utils/colors"
import "@/utils/optimizer"
LOG_FILE="$CORE_CACHE/install_npm.log"

install_npm() {
    check_or_prompt_preference
    separator
    box "Instalando Módulos Node.js"
    separator
    echo
    local pref=$(get_preference)

    if [ "$pref" == "space" ]; then
        log_info "Prioridad de optimización: ESPACIO. Usando PNPM..."
        loading "Habilitando PNPM vía Corepack" _enable_pnpm_corepack
        _install_npm_packages_pnpm
    else
        log_info "Prioridad de optimización: RENDIMIENTO. Usando Bun..."
        import "@/tools/lang/bun/install"
        _ensure_bun
        _install_npm_packages_bun
    fi

    log_success "Node.js global modules installed"
    echo
    list_item "TypeScript"
    list_item "NestJS CLI"
    list_item "Prettier"
    list_item "Live Server"
    list_item "Localtunnel"
    list_item "Vercel CLI"
    list_item "Markserv"
    list_item "PSQL Format"
    list_item "NPM Check Updates"
    list_item "Ngrok"
    echo
    separator
    log_success "Node.js modules installation completed"
    separator
    echo
}

_enable_pnpm_corepack() {
    pkg install nodejs-lts -y &>>"$LOG_FILE"
    corepack enable &>>"$LOG_FILE"
    corepack prepare pnpm@latest --activate &>>"$LOG_FILE"
}

_install_npm_packages_pnpm() {
    local pkgs=("typescript" "nestjs" "prettier" "live-server" "localtunnel" "vercel" "markserv" "psqlformat" "ncu" "ngrok" "turbopack")
    for pkg in "${pkgs[@]}"; do
        loading "Instalando $pkg globalmente con PNPM" pnpm add -g "$pkg" &>>"$LOG_FILE"
    done
    log_success "Ecosistema global de Node configurado con PNPM"
}

_install_npm_packages_bun() {
    local pkgs=("typescript" "nestjs" "prettier" "live-server" "localtunnel" "vercel" "markserv" "psqlformat" "ncu" "ngrok" "turbopack")
    for pkg in "${pkgs[@]}"; do
        loading "Instalando $pkg globalmente con Bun" bun install -g "$pkg" &>>"$LOG_FILE"
    done
    log_success "Ecosistema global de Node configurado con Bun"
}

_install_npm_wrapper() {
    import "@/tools/npm/all"
    install_all_npm_packages
}

uninstall_npm() {
    if ! command -v tsc &>/dev/null; then
        log_info "Node.js Modules are not installed"
        return 0
    fi
    separator
    box "Uninstalling Node.js Modules"
    separator
    echo
    log_info "Uninstalling Node.js global modules..."
    _uninstall_npm_wrapper
    log_success "Node.js global modules uninstalled"
    echo
    separator
    log_success "Node.js modules uninstallation completed"
    separator
    echo
}

_uninstall_npm_wrapper() {
    local pref=$(get_preference)
    if [ "$pref" == "space" ]; then
        local pkgs=("typescript" "nestjs" "prettier" "live-server" "localtunnel" "vercel" "markserv" "psqlformat" "ncu" "ngrok" "turbopack")
        for pkg in "${pkgs[@]}"; do
            pnpm remove -g "$pkg" &>>"$LOG_FILE" 2>/dev/null
        done
    else
        local pkgs=("typescript" "nestjs" "prettier" "live-server" "localtunnel" "vercel" "markserv" "psqlformat" "ncu" "ngrok" "turbopack")
        for pkg in "${pkgs[@]}"; do
            bun uninstall -g "$pkg" &>>"$LOG_FILE" 2>/dev/null
        done
    fi
    import "@/tools/npm/all"
    uninstall_all_npm_packages
}

update_npm() {
	separator
	box "Updating Node.js Modules"
	separator
	echo

	log_info "Updating Node.js global modules..."

	_update_npm_wrapper
	log_success "Node.js global modules updated"
	echo
	separator
	log_success "Node.js modules update completed"
	separator
	echo
}

_update_npm_wrapper() {
  import "@/tools/npm/all"
  update_all_npm_packages
}

reinstall_npm() {
  separator
  box "Reinstalling Node.js Modules"
  separator
  echo

  log_info "Reinstalling Node.js global modules..."

  _reinstall_npm_wrapper
  log_success "Node.js global modules reinstalled"
  echo
  list_item "TypeScript"
  list_item "NestJS CLI"
  list_item "Prettier"
  list_item "Live Server"
  list_item "Localtunnel"
  list_item "Vercel CLI"
  list_item "Markserv"
  list_item "PSQL Format"
  list_item "NPM Check Updates"
  list_item "Ngrok"
  echo
  separator
  log_success "Node.js modules reinstallation completed"
  separator
  echo
}

_reinstall_npm_wrapper() {
  import "@/tools/npm/all"
  reinstall_all_npm_packages
}
