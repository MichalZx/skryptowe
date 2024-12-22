#!/bin/bash

board=("1" "2" "3" "4" "5" "6" "7" "8" "9")
player1_symbol="X"
player2_symbol="O"
current_player="player1"
save_file="tictactoe_save.txt"
game_mode="1" 

print_board() {
    echo "
 ${board[0]} | ${board[1]} | ${board[2]} 
---|---|---
 ${board[3]} | ${board[4]} | ${board[5]} 
---|---|---
 ${board[6]} | ${board[7]} | ${board[8]} 
"
}

check_winner() {
    for line in "0 1 2" "3 4 5" "6 7 8" "0 3 6" "1 4 7" "2 5 8" "0 4 8" "2 4 6"; do
        set -- $line
        if [[ "${board[$1]}" == "${board[$2]}" && "${board[$2]}" == "${board[$3]}" ]]; then
            echo "${board[$1]}"
            return
        fi
    done
    echo ""
}

check_draw() {
    for cell in "${board[@]}"; do
        if [[ "$cell" != "$player1_symbol" && "$cell" != "$player2_symbol" ]]; then
            return 1
        fi
    done
    return 0
}

player_move() {
    local move
    local player_symbol
    if [[ "$current_player" == "player1" ]]; then
        player_symbol="$player1_symbol"
    else
        player_symbol="$player2_symbol"
    fi
    
    while true; do
        echo "Zapisz i wyjdź (0) lub"
        read -p "$player_symbol: Wybierz pole (1-9): " move
        if [[ "$move" == "0" ]]; then
            save_game
        fi
        if [[ "$move" =~ ^[1-9]$ && "${board[$((move-1))]}" != "$player1_symbol" && "${board[$((move-1))]}" != "$player2_symbol" ]]; then
            board[$((move-1))]="$player_symbol"
            break
        else
            echo "Nieprawidłowy ruch. Spróbuj ponownie."
        fi
    done
}

computer_move() {
    echo "Komputer wykonuje ruch..."
    for line in "0 1 2" "3 4 5" "6 7 8" "0 3 6" "1 4 7" "2 5 8" "0 4 8" "2 4 6"; do
        set -- $line
        if [[ "${board[$1]}" == "$player2_symbol" && "${board[$2]}" == "$player2_symbol" && "${board[$3]}" != "$player1_symbol" && "${board[$3]}" != "$player2_symbol" ]]; then
            board[$3]="$player2_symbol"
            return
        elif [[ "${board[$1]}" == "$player2_symbol" && "${board[$3]}" == "$player2_symbol" && "${board[$2]}" != "$player1_symbol" && "${board[$2]}" != "$player2_symbol" ]]; then
            board[$2]="$player2_symbol"
            return
        elif [[ "${board[$2]}" == "$player2_symbol" && "${board[$3]}" == "$player2_symbol" && "${board[$1]}" != "$player1_symbol" && "${board[$1]}" != "$player2_symbol" ]]; then
            board[$1]="$player2_symbol"
            return
        elif [[ "${board[$1]}" == "$player1_symbol" && "${board[$2]}" == "$player1_symbol" && "${board[$3]}" != "$player1_symbol" && "${board[$3]}" != "$player2_symbol" ]]; then
            board[$3]="$player2_symbol"
            return
        elif [[ "${board[$1]}" == "$player1_symbol" && "${board[$3]}" == "$player1_symbol" && "${board[$2]}" != "$player1_symbol" && "${board[$2]}" != "$player2_symbol" ]]; then
            board[$2]="$player2_symbol"
            return
        elif [[ "${board[$2]}" == "$player1_symbol" && "${board[$3]}" == "$player1_symbol" && "${board[$1]}" != "$player1_symbol" && "${board[$1]}" != "$player2_symbol" ]]; then
            board[$1]="$player2_symbol"
            return
        fi
    done
    
    empty_cells=()
    for i in {0..8}; do
        if [[ "${board[$i]}" != "$player1_symbol" && "${board[$i]}" != "$player2_symbol" ]]; then
            empty_cells+=($i)
        fi
    done
    random_index=$((RANDOM % ${#empty_cells[@]}))
    board[${empty_cells[$random_index]}]="$player2_symbol"
}

save_game() {
    echo "${board[@]}" > "$save_file"
    echo "$current_player" >> "$save_file"
    echo "$game_mode" >> "$save_file"
    echo "Gra została zapisana."
    menu
}

load_game() {
    if [[ -f "$save_file" ]]; then
        IFS=' ' read -r -a board < "$save_file"
        read -r current_player < <(tail -n 2 "$save_file" | head -n 1)
        read -r game_mode < <(tail -n 1 "$save_file")
        echo "Gra została wczytana."
    else
        echo "Brak zapisanej gry."
    fi
}

main_loop() {
    while true; do
        print_board

        if [[ "$game_mode" == "1" && "$current_player" == "player1" ]]; then
            player_move
            current_player="computer"
        elif [[ "$game_mode" == "1" && "$current_player" == "computer" ]]; then
            computer_move
            current_player="player1"
        else
            player_move
            if [[ "$current_player" == "player1" ]]; then
                current_player="player2"
            else
                current_player="player1"
            fi
        fi

        winner=$(check_winner)
        if [[ -n "$winner" ]]; then
            print_board
            echo "${winner} wygrywa!"
            break
        fi

        if check_draw; then
            print_board
            echo "Remis!"
            break
        fi
    done
}

menu() {
    while true; do
        echo "1. Nowa gra (1 gracz vs komputer)"
        echo "2. Nowa gra (2 gracze)"
        echo "3. Wczytaj grę"
        echo "4. Wyjście"
        read -p "Wybierz opcję: " option

        case $option in
            1)
                board=("1" "2" "3" "4" "5" "6" "7" "8" "9")
                current_player="player1"
                game_mode="1"
                main_loop
                ;;
            2)
                board=("1" "2" "3" "4" "5" "6" "7" "8" "9")
                current_player="player1"
                game_mode="2"
                main_loop
                ;;
            3)
                load_game
                main_loop
                ;;
            4)
                echo "Do widzenia!"
                exit 0
                ;;
            *)
                echo "Nieprawidłowa opcja. Spróbuj ponownie."
                ;;
        esac
    done
}

menu