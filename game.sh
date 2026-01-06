#!/bin/bash

N_filas=50
N_col=100

AZUL="\e[34m"
ROJO="\e[31m"
RESET="\e[0m"

jugador_brillante=0

# Coordenadas del objetivo (globales)
objetivo_x=-1
objetivo_y=-1

# Reproducir música en loop
play_musica() {
    while :; do
        paplay tloz-overworld.wav 2>/dev/null || sleep 5
    done
}

trap 'kill $MUSICA_PID 2>/dev/null; clear; exit' SIGINT

play_musica &
MUSICA_PID=$!

generar_nivel() {
    tablero=()
    
    # Generar tablero con obstáculos
    for ((i=0; i<N_filas; i++)); do
        fila=""
        for ((j=0; j<N_col; j++)); do
            if ((RANDOM % 5 == 0)); then
                fila+="#"
            else
                fila+="."
            fi
        done
        tablero+=("$fila")
    done

    # Jugador en zona visible (arriba izquierda)
    jugador_x=$((RANDOM % 10))          # 0..9
    jugador_y=$((RANDOM % 20))          # 0..19
    jugador_brillante=1

    # Evitar que el jugador esté en una pared (muy raro pero por si acaso)
    while [[ "${tablero[jugador_x]:jugador_y:1}" == "#" ]]; do
        jugador_x=$((RANDOM % 10))
        jugador_y=$((RANDOM % 20))
    done

    tablero[jugador_x]="${tablero[jugador_x]:0:jugador_y}@${tablero[jugador_x]:jugador_y+1}"

    # Generar objetivo en cualquier parte del mapa (aleatorio total)
    while true; do
        objetivo_x=$((RANDOM % N_filas))
        objetivo_y=$((RANDOM % N_col))
        
        if [[ "${tablero[objetivo_x]:objetivo_y:1}" == "." ]]; then
            tablero[objetivo_x]="${tablero[objetivo_x]:0:objetivo_y}*${tablero[objetivo_x]:objetivo_y+1}"
            break
        fi
    done
}

dibujar() {
    clear

# Hola!
    for ((i=0; i<30 && i<N_filas; i++)); do
        fila="${tablero[$i]}"
        
        # Resaltar jugador la primera vez que aparece
        if [[ $jugador_brillante -eq 1 && $i -eq $jugador_x ]]; then
            fila="${fila:0:$jugador_y}$AZUL@${RESET}${fila:$((jugador_y+1))}"
        fi
        
        # Todos los * en rojo
        fila="${fila//\*/${ROJO}*${RESET}}"
        
        echo -e "$fila"
    done
    
    echo -e "\e[90m Regenera con SHIFT + R si no aparece ningun * \e[0m"
    
    jugador_brillante=0
}

mover() {
    dx=0
    dy=0
    case $1 in
        w) dx=-1 ;;
        s) dx=1  ;;
        a) dy=-1 ;;
        d) dy=1  ;;
    esac

    nx=$((jugador_x + dx))
    ny=$((jugador_y + dy))

    if (( nx >= 0 && nx < N_filas && ny >= 0 && ny < N_col )); then
        if [[ "${tablero[nx]:ny:1}" != "#" ]]; then
            # Restaurar lo que había debajo
            orig_char="${tablero[jugador_x]:jugador_y:1}"
            if [[ "$orig_char" == "*" ]]; then
                tablero[jugador_x]="${tablero[jugador_x]:0:jugador_y}*${tablero[jugador_x]:jugador_y+1}"
            else
                tablero[jugador_x]="${tablero[jugador_x]:0:jugador_y}.${tablero[jugador_x]:jugador_y+1}"
            fi

            # Mover jugador
            jugador_x=$nx
            jugador_y=$ny
            tablero[jugador_x]="${tablero[jugador_x]:0:jugador_y}@${tablero[jugador_x]:jugador_y+1}"
            jugador_brillante=1
        fi
    fi
}

verificar_objetivo() {
    if [[ $jugador_x -eq $objetivo_x && $jugador_y -eq $objetivo_y ]]; then
        generar_nivel
    fi
}

# Inicio del juego
generar_nivel

while :; do
    dibujar
    read -n1 -s tecla

    # Regenerar nivel con Shift + R
    if [[ "$tecla" == "R" ]]; then
        generar_nivel
        continue
    fi

    mover "$tecla"
    verificar_objetivo
done
