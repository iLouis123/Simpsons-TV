import serial
import subprocess

# Port série pour la communication avec l'Arduino
ser = serial.Serial('/dev/ttyACM0', 9600, timeout=1)

def send_command_to_vlc(command):
    try:
        print(f"Sending command: {command}")
        result = subprocess.run(f"echo {command} | nc -q 0 localhost 4212", shell=True, check=True, capture_output=True)
        print(f"Command output: {result.stdout.decode()}")
    except subprocess.CalledProcessError as e:
        print(f"Error while sending command: {e}")

# Variable pour stocker le dernier volume
last_volume = 128  # Valeur de départ (échelle 0-500)

while True:
    data = ser.readline().decode('utf-8').strip()
    
    if data:
        print(f"Received raw data: {data}")
        
        if data.startswith("VOLUME:"):
            # Extraction du volume (de 0 à 100 envoyé par l'Arduino)
            volume = int(data.split(":")[1])
            # Conversion du volume de 0-100 à 0-500
            #volume = int(volume * 5)  # 100 -> 500
            #volume = int(volume * 5)  # 0 -> 0 et 100 -> 500
            #volume = int((100 - volume) * 5)  # Inverser l'échelle : 100 -> 0 et 0 -> 500
            #volume = int(800 - (volume * 7))  # 100 -> 100 et 0 -> 800
            #volume = int(1000 - (volume * 9))  # 100 -> 200 et 0 -> 1000
            volume = int(500 - (volume * 4))  # 100 -> 100 et 0 -> 500
            print(f"Setting VLC volume to {volume}")
            send_command_to_vlc(f"volume {volume}")
        
        elif data == 'PAUSE':
            print(f"Received button command: {data}")
            send_command_to_vlc("pause")
        
        elif data == 'NEXT':
            print(f"Received button command: {data}")
            send_command_to_vlc("next")
