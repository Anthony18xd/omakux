# omakux — fish config (semilla; edítalo a gusto, no se sobreescribe)

# --- entorno ---
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx OMAKUX_PATH "$HOME/.local/share/omakux"
set -gx XDG_CONFIG_HOME "$HOME/.config"

# --- PATH ---
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.local/share/mise/shims"
fish_add_path "$HOME/.cargo/bin"

# --- init de herramientas ---
if type -q starship
    starship init fish | source
end
if type -q zoxide
    zoxide init fish | source
end
if type -q fzf
    fzf --fish | source
end
if test -x "$HOME/.local/bin/mise"
    "$HOME/.local/bin/mise" activate fish | source
end

# --- atajos ---
if type -q eza
    alias ll 'eza -l --group-directories-first --git'
    alias la 'eza -la --group-directories-first --git'
    alias lt 'eza -T --group-directories-first'
    alias ls 'eza --group-directories-first'
else
    alias ll 'ls -lh'
    alias la 'ls -lah'
end
if type -q batcat
    alias bat 'batcat'
end
if type -q fdfind
    alias fd 'fdfind'
end
alias cat 'bat --paging=never'
alias grep 'rg'
alias .. 'cd ..'
alias ... 'cd ../..'
alias g 'git'
alias gs 'git status -sb'
alias gd 'git diff'
alias gl 'git log --oneline -15'
alias d 'docker'
alias dc 'docker compose'
alias v 'nvim'
alias vi 'nvim'
alias vim 'nvim'
alias reload 'source ~/.config/fish/config.fish'

# z (zoxide) + y (yazi)
function y
    set tmp (mktemp -t yazi-cwd.XXXXXX)
    yazi $argv --cwd-file="$tmp"
    if test -f "$tmp"
        set cwd (cat -- "$tmp")
        if test -n "$cwd" -a "$cwd" != "$PWD"
            cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end
end

# omakux: menú interactivo
function omakux-menu
    omakux menu
end

# saludo discreto en terminales interactivas
if status is-interactive
    # bienvenida solo en la primera terminal de la sesión
    if not set -q OMATHON_WELCOMED
        set -gx OMATHON_WELCOMED 1
        # (sin output: el prompt de starship ya informa)
    end
end
