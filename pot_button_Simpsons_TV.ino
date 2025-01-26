int potPin = A0;  // Broche du potentiomètre
int potValue = 0; // Valeur lue

int buttonPausePin = 2;  // Broche du bouton pause
int buttonNextPin = 3;   // Broche du bouton next

bool ledState = 0;

// Broche de la LED
const int ledPin = 4;

bool buttonPauseState = HIGH; // État actuel du bouton pause
bool buttonNextState = HIGH;  // État actuel du bouton next

void setup() {
  Serial.begin(9600); // Démarrage de la communication série

  pinMode(buttonPausePin, INPUT_PULLUP); // Configurer le bouton pause avec résistance pull-up
  pinMode(buttonNextPin, INPUT_PULLUP);  // Configurer le bouton next avec résistance pull-up

  // Initialisation de la LED en sortie
  pinMode(ledPin, OUTPUT);
}

void loop() {
  // Lecture du potentiomètre et envoi de la valeur du volume
  potValue = analogRead(potPin); // Lecture de la valeur du potentiomètre
  int volume = map(potValue, 0, 1023, 0, 100); // Conversion de la valeur en pourcentage
  Serial.println("VOLUME:" + String(volume)); // Envoi de la valeur du volume via la liaison série
  delay(100); // Petite pause pour éviter la surcharge

  // Lecture des boutons
  bool newButtonPauseState = digitalRead(buttonPausePin);
  bool newButtonNextState = digitalRead(buttonNextPin);



  // Si le bouton pause est pressé (état bas)
  if (newButtonPauseState == LOW && buttonPauseState == HIGH) {

        if (ledState == 0) {
          digitalWrite(ledPin, HIGH);  // Allumer la LED
          ledState = 1;
          Serial.println("LED ON");
        } else {
          digitalWrite(ledPin, LOW);  // Éteindre la LED
          ledState = 0;
          Serial.println("LED OFF");
        } 
    

    Serial.println("PAUSE");  // Envoi de la commande pause
    delay(200); // Anti-rebond



  }
  buttonPauseState = newButtonPauseState;  // Mise à jour de l'état précédent

  // Si le bouton next est pressé (état bas)
  if (newButtonNextState == LOW && buttonNextState == HIGH) {
    Serial.println("NEXT");  // Envoi de la commande next
    delay(200); // Anti-rebond
  }
  buttonNextState = newButtonNextState;  // Mise à jour de l'état précédent
}
