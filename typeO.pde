import controlP5.*;

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

ArrayList<String> gCodeSequence = new ArrayList<String>();

ControlP5 cp5;

JSONObject json;
JSONObject letters = new JSONObject();

char letter;
String val;

Serial device;

void setup() {
  size(640, 360);
  // Create the font
  textFont(createFont("Georgia", 36));
  println(Serial.list());
  String portName = Serial.list()[7];
  device = new Serial(this, portName, 9600); 

  noStroke();
  cp5 = new ControlP5(this);
  
  // create a new button with name 'buttonA'
  cp5.addButton("SELECT")
     .setValue(0)
     .setPosition(100,100)
     .setSize(200,19)
     ;

   cp5.addTextfield("input")
     .setPosition(20,100)
     .setSize(200,40)
     .setFocus(true)
     .setColor(color(255,0,0))
     ;

}

void draw() {
  background(0); // Set background to black
  // Draw the letter to the center of the screen
  textSize(14);
  text("Click on the program, and start typing.", 20, 40);
  text("wasd controls the pens position. Press 'r' to print the gcode collected.", 20, 70);
  
}

void keyPressed() {
  // The variable "key" always contains the value 
  // of the most recent key pressed.
  float distance = 1.0;
  switch(key) {
    case 'w':
      sendCommand("G01 Y" + distance);
      break;
    case 'a':
      sendCommand("G01 X-" + distance);
      break;
    case 's':
      sendCommand("G01 Y-" + distance);
      break;
    case 'd':
      sendCommand("G01 X" + distance);
      break;
    case 'r':
      println(gCodeSequence);
      gCodeSequence = null;
      break;
    case 'h':
      sendCommand("G91");
      break;
  }
}

public void colorA(int theValue) {
  
}

public void input(String keyCommand) {
  //TODOO OVERRIDES DATA EVERYTIME
  // Set commands to specific key
  JSONArray commands = new JSONArray();
  
  for (int i = 0; i < gCodeSequence.size(); i++) {
    JSONObject command = new JSONObject();
    commands.setString(i, gCodeSequence.get(i));
  }
  letters.setString("command", keyCommand);
  letters.setJSONArray("gcode", commands);
  saveJSONObject(letters, "data/first_font.json");
}

void sendCommand(String cmd) {
  String withNl = cmd + '\n';
  device.write(withNl);
  gCodeSequence.add(withNl);
}

void readOk() {
  String readData = device.readStringUntil('\n'); 
  if (readData != null && readData.equals("ok")) {
    
  }
}
