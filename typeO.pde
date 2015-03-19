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

boolean editMode = false;
String symbolsFileName = "first_font.json"; 
JSONObject symbols;

ControlP5 cp5;

DropdownList serialDL;
String[] serialDevices;

Serial device;

void setup() {
  symbols = loadJSONObject(symbolsFileName);
  
  size(640, 360);

  textFont(createFont("Georgia", 36));
  textSize(14);

  cp5 = new ControlP5(this);

  Button serialRefresh = cp5.addButton("serialRefresh");
  serialRefresh.setPosition(20, 20);
  serialRefresh.setWidth(100);
  serialRefresh.captionLabel().set("Refresh serial list");

  serialDL = cp5.addDropdownList("serialSelect");
  serialDL.setPosition(130, 40);
  serialDL.setSize(250, 250);
  serialDL.setBackgroundColor(color(190));
  serialDL.setItemHeight(20);
  serialDL.setBarHeight(15);
  serialDL.captionLabel().set("Select serial");
  serialDL.captionLabel().style().marginTop = 3;
  serialDL.captionLabel().style().marginLeft = 3;
  serialDL.valueLabel().style().marginTop = 3;
  serialDL.setColorBackground(color(60));
  serialDL.setColorActive(color(255, 128));
  populateSerialSelect();
  
  Toggle edit = cp5.addToggle("toggleEdit");
  edit.setPosition(580, 100);
  edit.setSize(50, 20);
  edit.captionLabel().set("Toggle edit");
  edit.setValue(editMode);
  edit.setMode(ControlP5.SWITCH);

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

  text("Click on the program, and start typing.", 20, 70);
  text("wasd controls the pens position. Press 'r' to print the gcode collected.", 20, 90);
}

void populateSerialSelect() {
  serialDL.clear();
  serialDevices = Serial.list();
  for (int i = 0; i < serialDevices.length; i++) {
    serialDL.addItem(serialDevices[i], i);
  }
}

void setSerial(int serialIndex) {
  device = new Serial(this, serialDevices[serialIndex], 9600);

  println("Initializing grbl...");
  device.write("\r\n\r\n");
  delay(2000);
  device.clear();
}

void controlEvent(ControlEvent event) {
  // DropdownList is of type ControlGroup.
  // A controlEvent will be triggered from inside the ControlGroup class.
  // therefore you need to check the originator of the Event with
  // if (event.isGroup())
  // to avoid an error message thrown by controlP5.

  if (event.isGroup()) {
    // check if the Event was triggered from a ControlGroup
    println("event from group : "+event.getGroup().getValue()+" from "+event.getGroup());

    if (event.getGroup().getName().equals("serialSelect")) {
      // Serial selected
      int serialIndex = int(event.getGroup().getValue());
      println("Serial selected: " + serialIndex);
      setSerial(serialIndex);
    }
  }
  else if (event.isController()) {
    println("event from controller : "+event.getController().getValue()+" from "+event.getController());

    if (event.getController().getName().equals("serialRefresh")) {
      populateSerialSelect();
    }
    
    if (event.getController().getName().equals("toggleEdit")) {
      float value = event.getController().getValue();
      if (value == 0.0) {
        editMode = false;
      } else {
        editMode = true;
      }
    }
  }
}

void keyPressed() {
  // The variable "key" always contains the value
  // of the most recent key pressed.
  float distance = 1.0;
  
  if (editMode) {
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
  } else {
    JSONArray symbolGcode = symbols.getJSONArray(key);
    for (int i = 0; i < symbolGcode.size(); i++) {
      sendCommand(symbolGcode.getString(i));
    }
  }

}

public void input(String keyCommand) {
  //TODOO OVERRIDES DATA EVERYTIME
  // Set commands to specific key
  JSONArray commands = new JSONArray();

  for (int i = 0; i < gCodeSequence.size(); i++) {
    commands.append(gCodeSequence.get(i));
  }

  symbols.setJSONArray(keyCommand, commands);
  saveJSONObject(symbols, symbolsFileName);
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
