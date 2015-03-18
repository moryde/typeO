import processing.serial.*;

/**
 * Characters Strings. 
 *  
 * The character datatype, abbreviated as char, stores letters and 
 * symbols in the Unicode format, a coding system developed to support 
 * a variety of world languages. Characters are distinguished from other
 * symbols by putting them between single quotes ('P').<br />
 * <br />
 * A string is a sequence of characters. A string is noted by surrounding 
 * a group of letters with double quotes ("Processing"). 
 * Chars and strings are most often used with the keyboard methods, 
 * to display text to the screen, and to load images or files.<br />
 * <br />
 * The String datatype must be capitalized because it is a complex datatype.
 * A String is actually a class with its own methods, some of which are
 * featured below. 
 */

// The next line is needed if running in JavaScript Mode with Processing.js
/* @pjs font="Georgia.ttf"; */

String gcode = "";

char letter;
String val;

Serial device;

void setup() {
  size(640, 360);
  // Create the font
  textFont(createFont("Georgia", 36));
  println(Serial.list());
  String portName = Serial.list()[0];
  device = new Serial(this, portName, 9600); 
}

void draw() {
  background(0); // Set background to black
  // Draw the letter to the center of the screen
  textSize(14);
  text("Click on the program, and start typing.", 20, 40);
  text("wasd controls the pens position. Press 'r' to print the gcode collected.", 20, 70);
  
  readOk();
}

void keyPressed() {
  // The variable "key" always contains the value 
  // of the most recent key pressed.
  switch(key) {
    case 'w':
      sendCommand("G01 Y10");
      break;
    case 'a':
      sendCommand("G01 X-10");
      break;
    case 's':
      sendCommand("G01 Y-10");
      break;
    case 'd':
      sendCommand("G01 X10");
      break;
    case 'r':
      println(gcode);
      gcode = "";
      break;
  }
}

void sendCommand(String cmd) {
  String withNl = cmd + '\n';
  gcode += withNl;
  device.write(withNl);
  
  readOk();
}

void readOk() {
  String readData = device.readStringUntil('\n'); 
  if (readData != null && readData.equals("ok")) {
    
  }
}
