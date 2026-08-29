#!/data/data/com.termux/files/usr/bin/bash
# core/tools/ai/hermes-agent/install.sh
import "@/utils/log"
import "@/utils/version"
import "@/utils/uninstall"
import "@/utils/walkie"
import "@/utils/optimizer"

LOG_FILE="$CORE_CACHE/install_ai.log"
HERMES_DIR="$HOME/.hermes/hermes-agent"
VENV_DIR="$HERMES_DIR/venv"

_hermes_install_deps() {
    loading "Installing dependencies" _hermes_install_deps_impl
}

_hermes_install_deps_impl() {
    declare -A DEPS=(
        ["python"]="python"
        ["nodejs-lts"]="node"
        ["ripgrep"]="rg"
        ["protobuf"]="protoc"
        ["clang"]="clang"
        ["rust"]="rustc"
        ["make"]="make"
        ["pkg-config"]="pkg-config"
        ["libffi"]="ffi"
        ["openssl"]="openssl"
    )

    # Asegurar repositorio TUR para poder instalar Python 3.11 nativo
    if ! pkg list-installed tur-repo &>/dev/null; then
        yes | pkg install tur-repo &>>"$LOG_FILE"
    fi

    local pkg_name bin_name
    for pkg_name in "${!DEPS[@]}"; do
        bin_name="${DEPS[$pkg_name]}"
        if ! command -v "$bin_name" &>/dev/null; then
            if ! yes | pkg install "$pkg_name" &>>"$LOG_FILE"; then
                log_error "Failed to install $pkg_name"
                return 1
            fi
        fi
    done
    return 0
}

_hermes_apply_patches() {
    loading "Applying Termux compatibility patches" _hermes_apply_patches_impl
}

_hermes_apply_patches_impl() {
    local PATCH_DIR="$HOME/.cargo/patches/protoc-bin-vendored"
    mkdir -p "$PATCH_DIR/src"

    cat << 'EOF_CARGO_TOML' > "$PATCH_DIR/Cargo.toml"
[package]
name = "protoc-bin-vendored"
version = "3.2.0"
edition = "2021"

[dependencies]
EOF_CARGO_TOML

    local PROTOC_PATH="$PREFIX/bin/protoc"
    local INCLUDE_PATH="$PREFIX/include"

    cat << EOF_LIB_RS > "$PATCH_DIR/src/lib.rs"
use std::path::PathBuf;

#[derive(Debug)]
pub struct Error;

impl std::fmt::Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Local Termux patch error")
    }
}

impl std::error::Error for Error {}

pub fn protoc_bin_path() -> Result<PathBuf, Error> {
    Ok(PathBuf::from("$PROTOC_PATH"))
}

pub fn include_path() -> Result<PathBuf, Error> {
    Ok(PathBuf::from("$INCLUDE_PATH"))
}
EOF_LIB_RS

    local CARGO_CONFIG="$HOME/.cargo/config.toml"
    mkdir -p "$HOME/.cargo"

    if [ -f "$CARGO_CONFIG" ]; then
        sed -i '/patch.crates-io/d' "$CARGO_CONFIG" 2>/dev/null || true
        sed -i '/protoc-bin-vendored/d' "$CARGO_CONFIG" 2>/dev/null || true
    fi

    cat << EOF_CARGO_CONFIG >> "$CARGO_CONFIG"

[patch.crates-io]
protoc-bin-vendored = { path = "$PATCH_DIR" }
EOF_CARGO_CONFIG

    return 0
}

_hermes_create_venv() {
    if [ ! -d "$HERMES_DIR" ]; then
        mkdir -p "$(dirname "$HERMES_DIR")"
        loading "Cloning Hermes Agent repo" git clone https://github.com/NousResearch/hermes-agent "$HERMES_DIR" &>>"$LOG_FILE"
    fi

    # Usar Python 3.11 nativo ya que las versiones superiores dan incompatibilidades en las dependencias de Hermes
    local PYTHON_BIN="python"
    if command -v python3.11 &>/dev/null; then
        PYTHON_BIN="python3.11"
    fi

    loading "Configuring Virtual Environment" "$PYTHON_BIN" -m venv "$VENV_DIR" &>>"$LOG_FILE"
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip &>>"$LOG_FILE"
}

_hermes_compile_phases() {
    local CARGO_CONFIG="$HOME/.cargo/config.toml"

    # FASE 1: Compilar librerías estándar con el parche desactivado temporalmente
    sed -i 's/^\[patch.crates-io\]/# [patch.crates-io]/g' "$CARGO_CONFIG" 2>/dev/null || true
    sed -i 's/^protoc-bin-vendored =/# protoc-bin-vendored =/g' "$CARGO_CONFIG" 2>/dev/null || true

    loading "Installing core standard Rust packages (Phase 1)" pip install cryptography==50.0.0 pydantic-core==2.46.4 jiter==0.16.0 watchfiles==1.2.0 rpds-py==0.25.0 &>>"$LOG_FILE"

    # FASE 2: Activar parche y compilar nemo-relay
    sed -i 's/^# \[patch.crates-io\]/[patch.crates-io]/g' "$CARGO_CONFIG" 2>/dev/null || true
    sed -i 's/^# protoc-bin-vendored =/protoc-bin-vendored =/g' "$CARGO_CONFIG" 2>/dev/null || true

    cd "$HERMES_DIR"
    loading "Compiling and installing Hermes-Agent (Phase 2)" env ANDROID_API_LEVEL=31 PROTOC=$PREFIX/bin/protoc pip install -e '.[termux-all]' -c constraints-termux.txt "fastapi==0.133.1" "uvicorn==0.41.0" &>>"$LOG_FILE"

    # Desactivar parche finalizada la compilación para no interferir con otros proyectos Rust
    sed -i 's/^\[patch.crates-io\]/# [patch.crates-io]/g' "$CARGO_CONFIG" 2>/dev/null || true
    sed -i 's/^protoc-bin-vendored =/# protoc-bin-vendored =/g' "$CARGO_CONFIG" 2>/dev/null || true
}

_create_hermes_launcher() {
    cat << 'EOF_HERMES_LAUNCHER' > "$PREFIX/bin/hermes"
#!/data/data/com.termux/files/usr/bin/bash
source $HOME/.hermes/hermes-agent/venv/bin/activate
exec hermes "$@"
EOF_HERMES_LAUNCHER
    chmod +x "$PREFIX/bin/hermes"
}

install_hermes_agent() {
    if command -v hermes &>/dev/null; then
        log_info "Hermes Agent is already installed"
        return 2
    fi

    log_info "Installing Hermes Agent..."
    check_or_prompt_preference
    setup_python_env
    setup_cargo_env

    _hermes_install_deps || return 1
    _hermes_create_venv || return 1
    _hermes_apply_patches || return 1
    _hermes_compile_phases || return 1
    _create_hermes_launcher || return 1

    # Estrategia de limpieza en modo espacio
    clean_build_residuos

    log_success "Hermes-Agent instalado y optimizado correctamente."
    return 0
}

uninstall_hermes_agent() {
    rm -f "$PREFIX/bin/hermes"
    confirm_remove_configs "Hermes Agent" "$HERMES_DIR" "$HOME/.hermes"
}

update_hermes_agent() {
    log_info "Updating Hermes Agent..."
    cd "$HERMES_DIR"
    git pull &>>"$LOG_FILE"
    source "$VENV_DIR/bin/activate"
    _hermes_apply_patches || return 1
    env ANDROID_API_LEVEL=31 PROTOC=$PREFIX/bin/protoc pip install -e '.[termux-all]' -c constraints-termux.txt "fastapi==0.133.1" "uvicorn==0.41.0" &>>"$LOG_FILE"
    clean_build_residuos
}

reinstall_hermes_agent() {
    uninstall_hermes_agent
    install_hermes_agent
}
