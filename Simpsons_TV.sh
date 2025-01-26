#!/bin/bash

#Lancer vlc
#vlc --intf rc --rc-host localhost:4212 --playlist-enqueue /home/ilouis/Simpsons/simpsons.m3u --playlist-autostart

#echo "next" | nc localhost 4212
#echo "pause" | nc localhost 4212
#echo "seek 60" | nc localhost 4212

#Récupérer l'index de la video en cours 
#echo "playlist" | nc -q 1 localhost 4212 | grep '\*' | sed -n 's/[^*]*\*\([0-9]\+\).*/\1/p'
#

#creer une playlist ordonnée
#find /home/ilouis/Simpsons -type f ! -name '.*' -name '*.mp4' |   sort -t '.' -k2,2n -k3,3n > Simpsons/simpsons.m3u

# Chemins vers la playlist et le fichier de sauvegarde de l'état                
PLAYLIST_PATH="/home/ilouis/Simpsons/simpsons.m3u"
SAVE_STATE_FILE="/home/ilouis/Simpsons/state.txt"
VLC_HOST="localhost"
VLC_PORT=4212
OUTPUT_VIDEO="intro_resume.mp4"

# Vérifier si le fichier de playlist existe                                     
if [ ! -f "$PLAYLIST_PATH" ]; then
    echo "Erreur : Le fichier de la playlist n'existe pas à $PLAYLIST_PATH"
    exit 1
fi

# Vérifier si le fichier de save state existe
if [ ! -f "$SAVE_STATE_FILE" ]; then
    echo "Erreur : Le fichier de la playlist n'existe pas à $PLAYLIST_PATH"
    exit 1
fi

backlight_control() {
    if [ "$1" == "on" ]; then
        sudo sh -c 'echo "0" > /sys/class/backlight/soc:backlight/bl_power'
    elif [ "$1" == "off" ]; then
        sudo sh -c 'echo "1" > /sys/class/backlight/soc:backlight/bl_power'
    else
        echo "Usage: backlight_control on|off"
    fi
}

load_state(){
    VIDEO_INDEX=$(sed -n '1p' "$SAVE_STATE_FILE")
    LAST_POSITION=$(sed -n '2p' "$SAVE_STATE_FILE")
    echo "Dernier index : $VIDEO_INDEX - Dernier etat : $LAST_POSITION"
}

intro_resume(){
    # Exécuter la commande FFmpeg pour créer la vidéo avec trois lignes de texte et écraser l'ancien fichier
    local total_seconds=$LAST_POSITION
    local minutes=$((total_seconds/ 60))
    local seconds=$((total_seconds % 60))
    ACTUAL_SEASON_EPISODE=$(echo "info 4" | nc -q 0 localhost 4212 | grep 'filename:' | sed 's/.*filename: //')
    ACTUAL_SEASON_EPISODE_FULL=$(echo "info $VIDEO_INDEX" | nc -q 0 localhost 4212 | grep 'filename:' | sed 's/.*filename: //' | sed -r 's/.*S([0-9]{2})E([0-9]{2}).*/Saison \1 - Episode \2/')

    ffmpeg -y -f lavfi -i color=c=black:s=480x320:d=5 -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf: text='Simpsons_TV resume':fontcolor=white:fontsize=30:x=(w-text_w)/2:y=(h-text_h)/2-40, drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf: text='$ACTUAL_SEASON_EPISODE_FULL':fontcolor=white:fontsize=30:x=(w-text_w)/2:y=(h-text_h)/2, drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf: text='Timer \: "$minutes" min "$seconds" sec':fontcolor=white:fontsize=30:x=(w-text_w)/2:y=(h-text_h)/2+40" -c:v libx264 -t 5 -pix_fmt yuv420p "$OUTPUT_VIDEO"

#    backligh_control on
    vlc --play-and-exit $OUTPUT_VIDEO
#    backligh_control off

}

save_state(){
    ACTUAL_INDEX=$(echo "playlist" | nc -q 0 localhost 4212 | grep '\*' | sed -n 's/[^*]*\*\([0-9]\+\).*/\1/p') 
    ACTUAL_POSITION=$(echo "get_time" | nc -q 0 localhost 4212 | grep -oP '(?<=^> )\d+')
    echo "Save state - Index : $ACTUAL_INDEX - Position : $ACTUAL_POSITION"
    echo "$ACTUAL_INDEX" > "$SAVE_STATE_FILE"
    echo "$ACTUAL_POSITION" >> "$SAVE_STATE_FILE"
}

exit_simpsons_TV(){
    #save_state
    killall vlc 2>/dev/null
}

start_vlc(){
 #   backligh_control off
    load_state
    echo "start vlc"
    vlc  --sub-track=0 --intf rc --rc-host $VLC_HOST:$VLC_PORT --playlist-enqueue /home/ilouis/Simpsons/simpsons.m3u --no-playlist-autostart &
    #GET les boutons du VCR et le VOLUME
    python3 /home/ilouis/read_arduino.py &
    #GET les touches sur l'écran
    python3 /home/ilouis/piTFT_touch_sceen.py &

    sleep 5
    echo "pause" | nc -q 0 $VLC_HOST $VLC_PORT
    intro_resume
#    echo "play" | nc -q 0 $VLC_HOST $VLC_PORT
    echo "goto $VIDEO_INDEX" | nc -q 0 $VLC_HOST $VLC_PORT
    echo "seek $LAST_POSITION" | nc -q 0 $VLC_HOST $VLC_PORT
    #backligh_control on
    echo "play" | nc -q 0 $VLC_HOST $VLC_PORT
#    backligh_control on
    while true; do
	#on se calme un peu
      	sleep 5
	#on sauvegarde l'avancée du visionnage
	save_state
	done
}

# Gérer la sauvegarde avant la fermeture du script                              
trap exit_simpsons_TV EXIT

# Lancer la fonction principale                                                 
start_vlc

