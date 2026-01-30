/*
 * FluxGarage RoboEyes for OLED Displays V 1.1.1
 * Draws smoothly animated robot eyes on OLED displays, based on the Adafruit GFX 
 * library's graphics primitives, such as rounded rectangles and triangles.
 */

#ifndef _FLUXGARAGE_ROBOEYES_H
#define _FLUXGARAGE_ROBOEYES_H

// Display colors
uint8_t BGCOLOR = 0; // background and overlays
uint8_t MAINCOLOR = 1; // drawings

// For mood type switch
#define DEFAULT 0
#define TIRED 1
#define ANGRY 2
#define HAPPY 3

// For turning things on or off
#define ON 1
#define OFF 0

// For switch "predefined positions"
#define N 1 
#define NE 2
#define E 3 
#define SE 4
#define S 5 
#define SW 6
#define W 7 
#define NW 8 

template<typename AdafruitDisplay>
class RoboEyes
{
public:
AdafruitDisplay *display;

int screenWidth = 128;
int screenHeight = 64;
int frameInterval = 20;
unsigned long fpsTimer = 0;

bool tired = 0;
bool angry = 0;
bool happy = 0;
bool curious = 0;
bool cyclops = 0;
bool eyeL_open = 0;
bool eyeR_open = 0;

int eyeLwidthDefault = 36;
int eyeLheightDefault = 36;
int eyeLwidthCurrent = eyeLwidthDefault;
int eyeLheightCurrent = 1; 
int eyeLwidthNext = eyeLwidthDefault;
int eyeLheightNext = eyeLheightDefault;
int eyeLheightOffset = 0;
byte eyeLborderRadiusCurrent = 8;
byte eyeLborderRadiusNext = 8;

int eyeRwidthDefault = 36;
int eyeRheightDefault = 36;
int eyeRwidthCurrent = 36;
int eyeRheightCurrent = 1; 
int eyeRwidthNext = 36;
int eyeRheightNext = 36;
int eyeRheightOffset = 0;
byte eyeRborderRadiusCurrent = 8;
byte eyeRborderRadiusNext = 8;

int eyeLxDefault = 10;
int eyeLyDefault = 10;
int eyeLx = 10;
int eyeLy = 10;
int eyeLxNext = 10;
int eyeLyNext = 10;

int eyeRxDefault = 60;
int eyeRyDefault = 10;
int eyeRx = 60;
int eyeRy = 10;
int eyeRxNext = 60;
int eyeRyNext = 10;

int spaceBetweenCurrent = 10;
int spaceBetweenNext = 10;

bool hFlicker = 0;
bool hFlickerAlternate = 0;
byte hFlickerAmplitude = 2;
bool vFlicker = 0;
bool vFlickerAlternate = 0;
byte vFlickerAmplitude = 10;

bool autoblinker = 0;
int blinkInterval = 1;
int blinkIntervalVariation = 4;
unsigned long blinktimer = 0;

bool idle = 0;
int idleInterval = 1;
int idleIntervalVariation = 3;
unsigned long idleAnimationTimer = 0;

bool confused = 0;
unsigned long confusedAnimationTimer = 0;
int confusedAnimationDuration = 500;
bool confusedToggle = 1;

bool laugh = 0;
unsigned long laughAnimationTimer = 0;
int laughAnimationDuration = 500;
bool laughToggle = 1;

byte eyelidsTiredHeight = 0;
byte eyelidsTiredHeightNext = 0;
byte eyelidsAngryHeight = 0;
byte eyelidsAngryHeightNext = 0;
byte eyelidsHappyBottomOffset = 0;
byte eyelidsHappyBottomOffsetNext = 0;

RoboEyes(AdafruitDisplay &disp) : display(&disp) {};

void begin(int width, int height, byte frameRate) {
	screenWidth = width;
	screenHeight = height;
  display->clearDisplay();
  display->display();
  eyeLheightCurrent = 1;
  eyeRheightCurrent = 1;
  frameInterval = 1000/frameRate;
}

void update(){
  if(millis()-fpsTimer >= frameInterval){
    drawEyes();
    fpsTimer = millis();
  }
}

void setAutoblinker(bool active, int interval, int variation){
  autoblinker = active;
  blinkInterval = interval;
  blinkIntervalVariation = variation;
}

void setIdleMode(bool active, int interval, int variation){
  idle = active;
  idleInterval = interval;
  idleIntervalVariation = variation;
}

void setMood(unsigned char mood) {
    tired = (mood == TIRED);
    angry = (mood == ANGRY);
    happy = (mood == HAPPY);
}

void drawEyes(){
  if(autoblinker && millis() >= blinktimer){
    eyeLheightNext = 1; eyeRheightNext = 1;
    eyeL_open = 1; eyeR_open = 1;
    blinktimer = millis()+(blinkInterval*1000)+(random(blinkIntervalVariation)*1000);
  }

  if(idle && millis() >= idleAnimationTimer){
    eyeLxNext = random(screenWidth-82);
    eyeLyNext = random(screenHeight-36);
    idleAnimationTimer = millis()+(idleInterval*1000)+(random(idleIntervalVariation)*1000);
  }

  eyeLheightCurrent = (eyeLheightCurrent + eyeLheightNext)/2;
  eyeRheightCurrent = (eyeRheightCurrent + eyeRheightNext)/2;
  
  if(eyeL_open && eyeLheightCurrent <= 1){eyeLheightNext = 36;}
  if(eyeR_open && eyeRheightCurrent <= 1){eyeRheightNext = 36;}

  eyeLx = (eyeLx + eyeLxNext)/2;
  eyeLy = (eyeLy + eyeLyNext)/2;
  eyeRxNext = eyeLxNext + 46;
  eyeRyNext = eyeLyNext;
  eyeRx = (eyeRx + eyeRxNext)/2;
  eyeRy = (eyeRy + eyeRyNext)/2;

  display->clearDisplay();
  display->fillRoundRect(eyeLx, eyeLy, 36, eyeLheightCurrent, 8, 1);
  display->fillRoundRect(eyeRx, eyeRy, 36, eyeRheightCurrent, 8, 1);

  if (tired){eyelidsTiredHeightNext = eyeLheightCurrent/2;} else {eyelidsTiredHeightNext = 0;}
  if (angry){eyelidsAngryHeightNext = eyeLheightCurrent/2;} else {eyelidsAngryHeightNext = 0;}
  if (happy){eyelidsHappyBottomOffsetNext = eyeLheightCurrent/2;} else {eyelidsHappyBottomOffsetNext = 0;}

  eyelidsTiredHeight = (eyelidsTiredHeight + eyelidsTiredHeightNext)/2;
  if(eyelidsTiredHeight > 0){
    display->fillTriangle(eyeLx, eyeLy-1, eyeLx+36, eyeLy-1, eyeLx, eyeLy+eyelidsTiredHeight-1, 0);
    display->fillTriangle(eyeRx, eyeRy-1, eyeRx+36, eyeRy-1, eyeRx+36, eyeRy+eyelidsTiredHeight-1, 0);
  }

  eyelidsAngryHeight = (eyelidsAngryHeight + eyelidsAngryHeightNext)/2;
  if(eyelidsAngryHeight > 0){
    display->fillTriangle(eyeLx, eyeLy-1, eyeLx+36, eyeLy-1, eyeLx+36, eyeLy+eyelidsAngryHeight-1, 0);
    display->fillTriangle(eyeRx, eyeRy-1, eyeRx+36, eyeRy-1, eyeRx, eyeRy+eyelidsAngryHeight-1, 0);
  }

  eyelidsHappyBottomOffset = (eyelidsHappyBottomOffset + eyelidsHappyBottomOffsetNext)/2;
  if(eyelidsHappyBottomOffset > 0){
      display->fillRoundRect(eyeLx-1, (eyeLy+eyeLheightCurrent)-eyelidsHappyBottomOffset+1, 38, 36, 8, 0);
      display->fillRoundRect(eyeRx-1, (eyeRy+eyeRheightCurrent)-eyelidsHappyBottomOffset+1, 38, 36, 8, 0);
  }

  display->display();
}

};
#endif
