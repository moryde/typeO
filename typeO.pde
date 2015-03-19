import controlP5.*;

import processing.serial.*;

/**
 * Characters Strings.
 *
 * The character datatype, abbreviated as char, stores letters and
 * charecters in the Unicode format, a coding system developed to support
 * a variety of world languages. Characters are distinguished from other
 * charecters by putting them between single quotes ('P').<br />
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

File configFile = dataFile("config.json");
JSONObject config;

ArrayList<String> gCodeSequence = new ArrayList<String>();

boolean isRecording = false;
boolean editMode = false;
boolean saveInSprites = false;
String keyCommand;
File fontFile = dataFile("second_font.json");
File spriteFile = dataFile("sprites.json");
JSONObject charecters;
JSONObject sprites;

float distance = 1.0;

ControlP5 cp5;


Button record;
Toggle edit;

DropdownList serialDL;
String[] serialDevices;

Serial gcodeMachine;

void setup() {
  if (configFile.exists()) {
    config = new JSONObject(createReader(configFile));
    println("Got config file");
    if (config.hasKey("serialDevice")) {
      String loadedSerial = config.getString("serialDevice");
      serialDevices = Serial.list();

      boolean foundDevice = false;
      for (int i = 0; i < serialDevices.length; i++) {
        if (loadedSerial.equals(serialDevices[i])) {
          foundDevice = true;
        }
      }

      if (foundDevice) {
        // Device still available, lets connect
        setSerial(loadedSerial);
        println("Reconnected to last used device: " + loadedSerial);
      }
    }
  } else {
    config = new JSONObject();
    println("No existing config file");
  }
  if (fontFile.exists()) {
    charecters = new JSONObject(createReader(fontFile));
  } else {
    charecters = new JSONObject();
  }
  if (spriteFile.exists()) {
    sprites = new JSONObject(createReader(spriteFile));
    println(sprites);
  } else {
    println("!Sprites");

    sprites = new JSONObject();
  }



  size(640, 360);

  textFont(createFont("Georgia", 36));
  textSize(14);

  cp5 = new ControlP5(this);
  int labels = color(0);
  
  Button gridSize1 = cp5.addButton("gridSize1");
    gridSize1.setPosition(200, 200);


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

  edit = cp5.addToggle("toggleEdit");
  edit.setPosition(130, 60);
  edit.setSize(100, 20);
  edit.captionLabel().set("Typewriter mode");
  edit.setValue(editMode);
  edit.setMode(ControlP5.SWITCH);

  record = cp5.addButton("record");
  record.setPosition(20, 60);
  record.setSize(50, 20);
  record.setWidth(100);
  record.captionLabel().set("Record");

  cp5.addTextfield("drawSprite")
    .setPosition(225, 100)
      .setSize(200, 20)
        .setFocus(true)
          .setColor(color(255, 0, 0))
            .setCaptionLabel("Sprite to play");
  ;


  cp5.addTextfield("keyToSave")
    .setPosition(20, 100)
      .setSize(200, 20)
        .setFocus(true)
          .setColor(color(255, 0, 0))
            .setCaptionLabel("Key to record");
  ;

  cp5.addTextfield("lettersToSend")
    .setPosition(430, 100)
      .setSize(200, 20)
        .setColor(color(255, 0, 0))
          .setFont(createFont("arial", 12))
            .setCaptionLabel("Letters to write...");
  ;

  cp5.addSlider("changeGridSize")
    .setPosition(300, 80)
      .setValue(10)
      .setRange(0, 30)
        ;
}

void draw() {
  background(0); // Set background to black
}

void populateSerialSelect() {
  serialDL.clear();
  serialDevices = Serial.list();
  for (int i = 0; i < serialDevices.length; i++) {
    serialDL.addItem(serialDevices[i], i);
  }
}

void setSerial(String devicePath) {
  gcodeMachine = new Serial(this, devicePath, 115200);

  config.setString("serialDevice", devicePath);
  config.save(configFile, "");

  println("Initializing grbl...");
  gcodeMachine.write("\r\n\r\n");
  delay(2000);
  sendCommand("G91");
  gcodeMachine.clear();
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
      //int serialIndex = int(event.getGroup().getValue());
      //setSerial(serialDevices[serialIndex]);
    }
  } else if (event.isController()) {
    println("event from controller : "+event.getController().getValue()+" from "+event.getController());

    if (event.getController().getName().equals("serialRefresh")) {
      populateSerialSelect();
    }

    if (event.getController().getName().equals("toggleEdit")) {
      float value = event.getController().getValue();
      if (value == 0.0) {
        editMode = false;
        edit.captionLabel().set("Typewriter mode");
      } else {
        editMode = true;
        edit.captionLabel().set("Editor mode");
      }
    }

    if (event.getController().getName().equals("record")) {
      if (isRecording) {
        endRecording();
      } else {
        startRecording();
      }
    }
  }
}

void keyPressed() {
  // The variable "key" always contains the value
  // of the most recent key pressed.

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
      sendCommand("G01 Y" + distance/2 + " X" + -distance/2);
      break;
    case 't':
      sendCommand("G01 Y" + distance/2 + " X" + distance/2);
      break;
    case 'f':
      sendCommand("G01 Y" + -distance/2 + " X" + -distance/2);
      break;
    case 'g':
      sendCommand("G01 Y" + -distance/2 + " X" + distance/2);
      break;

    case 'y':
      sendCommand("G02 X2 Y0 R2");
      break;
    case 'u':
      sendCommand("G01 Y" + distance/2 + " X" + distance/2);
      break;
    case 'h':
      sendCommand("G01 Y" + -distance/2 + " X" + -distance/2);
      break;
    case 'j':
      sendCommand("G01 Y" + -distance/2 + " X" + distance/2);
      break;

    case 'o':
      //should not be needed anymore, but just in case.
      sendCommand("G91");
      break;
    }
  } else {
    String jsonKey = "" + key;
    if (charecters.hasKey(jsonKey)) {
      JSONArray symbolGcode = charecters.getJSONArray(jsonKey);
      for (int i = 0; i < symbolGcode.size (); i++) {
        sendCommand(symbolGcode.getString(i));
      }
    }
  }
}

public void lettersToSend(String keyCommandos) {
}

public void changeGridSize(float keyCommandos) {
  distance = keyCommandos;
}

public void keyToSave(String keyCommandos) {
  if (keyCommandos.length() == 1) {
    saveInSprites = false;
  } else {
    saveInSprites = true;
  }
  keyCommand = keyCommandos;
  startRecording();
}

public void drawSprite(String spriteName) {
  // Set commands to specific key
  if (sprites.hasKey(spriteName)) {
    JSONArray symbolGcode = sprites.getJSONArray(spriteName);
    for (int i = 0; i < symbolGcode.size (); i++) {
      sendCommand(symbolGcode.getString(i));
    }
  }
}

void endRecording() {
  println("Ended recording");
  isRecording = false;
  record.setColorBackground(color(255, 100, 0));
  record.captionLabel().set("Start recording");
  JSONArray commands = new JSONArray();
  for (int i = 0; i < gCodeSequence.size (); i++) {
    commands.append(gCodeSequence.get(i));
  }

  if (saveInSprites) {
    sprites.setJSONArray(keyCommand, commands);
    sprites.save(spriteFile, "");
  } else {
    charecters.setJSONArray(keyCommand, commands);
    charecters.save(fontFile, "");
  }
}

void startRecording() {
  isRecording = true;
  gCodeSequence.clear();
  println("isRecording now");
  record.setColorBackground(color(255, 0, 0));
  record.captionLabel().set("Recording...");
}

void sendCommand(String cmd) {
  String withNl = cmd + '\n';
  gcodeMachine.write(withNl);
  println(withNl);
  readOk();
  if (isRecording) {
    gCodeSequence.add(withNl);
  };
}

void readOk() {
  delay(100);
  String readData = gcodeMachine.readStringUntil('\n');
  
  println(readData);
  if (readData != null && readData == "ok") {
    println("recieved ok");
  } else {
    println("Other than OK" + readData);
  }
}

