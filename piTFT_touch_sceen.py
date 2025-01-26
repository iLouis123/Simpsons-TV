import evdev
from evdev import InputDevice, ecodes
import subprocess
import time

# Remplace eventX par le bon périphérique trouvé avec evtest
device_path = '/dev/input/event7'

# Configuration de netcat (commande VLC)
vlc_host = "localhost"
vlc_port = 4212

# Temps minimum entre deux clics (en secondes)
click_delay = 1.0
last_click_time = 0

try:
    # Initialisation de l'appareil
    device = InputDevice(device_path)
    print(f"Device trouvé : {device}")
except FileNotFoundError:
    print(f"Erreur : Le périphérique {device_path} est introuvable. Vérifie le bon eventX.")
    exit(1)

# Variables pour stocker les coordonnées X et Y
x, y = None, None
screen_width = 480  # Largeur de l'écran en pixels
screen_height = 320  # Hauteur de l'écran

# Les valeurs min/max des coordonnées X et Y (à ajuster en fonction de ton écran tactile)
min_x = 0
max_x = 4095  # Ajuste cette valeur selon la plage maximale X détectée avec evtest
min_y = 0
max_y = 4095  # Ajuste cette valeur selon la plage maximale Y détectée avec evtest

# Définition des zones basées sur les coordonnées Y normalisées entre 0 et 320 (axe Y = gauche, milieu, droite)
zone_1_max = 106   # Zone 1 : de 0 à 106 pixels (Gauche)
zone_2_max = 213   # Zone 2 : de 107 à 213 pixels (Milieu)
zone_3_max = 320   # Zone 3 : de 214 à 320 pixels (Droite)

# Fonction pour déterminer la zone en fonction de Y (axe Y)
def get_zone(y):
    if y <= zone_1_max:
        return "Zone 1 (Gauche)"
    elif y <= zone_2_max:
        return "Zone 2 (Milieu)"
    else:
        return "Zone 3 (Droite)"

# Fonction pour envoyer une commande à VLC via netcat
def send_vlc_command(command):
    try:
        subprocess.run(f'echo "{command}" | nc -q 0 {vlc_host} {vlc_port}', shell=True, check=True)
        print(f"Commande VLC envoyée : {command}")
    except subprocess.CalledProcessError as e:
        print(f"Erreur lors de l'envoi de la commande VLC : {e}")

# Fonction pour normaliser la coordonnée
def normalize(value, min_val, max_val, target_size):
    return int((value - min_val) / (max_val - min_val) * target_size)

# Lecture des événements
try:
    print("En attente des événements... (Touche l'écran tactile)")
    for event in device.read_loop():
        if event.type == ecodes.EV_ABS:
            if event.code == ecodes.ABS_X:  # Événement pour la coordonnée X
                x_raw = event.value
                x = normalize(x_raw, min_x, max_x, screen_width)  # Normaliser X
            elif event.code == ecodes.ABS_Y:  # Événement pour la coordonnée Y
                y_raw = event.value
                y = normalize(y_raw, min_y, max_y, screen_height)  # Normaliser Y

        # Si les deux coordonnées X et Y sont capturées et qu'un appui est détecté
        if x is not None and y is not None:
            current_time = time.time()  # Récupérer le temps actuel

            if event.type == ecodes.EV_KEY and event.value == 1:  # Appui détecté
                # Vérifier si le délai depuis le dernier clic est suffisant
                if current_time - last_click_time > click_delay:
                    zone = get_zone(y)  # Utilisation de y normalisé pour définir la zone
                    print(f"Message affiché : {zone} (Coordonnées X: {x}, Y: {y})")

                    # Envoie la commande VLC en fonction de la zone
                    if zone == "Zone 1 (Gauche)":
                        send_vlc_command("prev")
                    elif zone == "Zone 2 (Milieu)":
                        send_vlc_command("pause")
                    elif zone == "Zone 3 (Droite)":
                        send_vlc_command("next")

                    last_click_time = current_time  # Mettre à jour l'heure du dernier clic
                else:
                    print(f"Attente d'un délai avant de détecter un autre clic.")

        # Affichage lors du relâchement (event.value == 0)
        elif event.type == ecodes.EV_KEY and event.value == 0:  # Relâchement détecté
            print("Relâchement détecté. Aucune zone affichée.")

except OSError as e:
    print(f"Erreur lors de la lecture du périphérique : {e}")
