import controlP5.*;

import processing.serial.*;
import geomerative.*;

RShape shp;
RShape polyshp;

File configFile = dataFile("config.json");
JSONObject config;

ArrayList<String> gCodeSequence = new ArrayList<String>();

boolean isRecording = false;
boolean editMode = false;
boolean saveInSprites = false;
String keyCommand;
File fontFile = dataFile("third_font.json");
File spriteFile = dataFile("sprites.json");
JSONObject charecters;
JSONObject sprites;

float distance = 1.0;
float polygonizerAngle = 1.0;


RSVG svg;
Button record;
Toggle edit;
Textfield lettersToSend;

Slider polygonizerAngleSlider;
Button renderShape;
Button printShape;

float currentPositionA;
float currentPositionB;

Serial gcodeMachine;

ControlP5 cp5;
Comm comm;

void setup() {
  cp5 = new ControlP5(this);
  
  comm = new Comm(200,300);
  
  size(1000,1000);
  frameRate( 5 );
  RG.init(this);
  RG.setPolygonizer(RG.ADAPTATIVE);
  
  shp = RG.loadShape("50x50square.svg");

  polyshp = RG.polygonize(shp);
  polyshp.translate(20, 250);
  //polyshp.scale(0.5);

  
  if (configFile.exists()) {
    config = new JSONObject(createReader(configFile));
    println("Got config file");
    if (config.hasKey("serialDevice")) {
      String loadedSerial = config.getString("serialDevice");
      comm.serialDevices = Serial.list();

      boolean foundDevice = false;
      for (int i = 0; i < comm.serialDevices.length; i++) {
        if (loadedSerial.equals(comm.serialDevices[i])) {
          foundDevice = true;
        }
      }

      if (foundDevice) {
        // Device still available, lets connect
        //setSerial(loadedSerial);
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

  textFont(createFont("Georgia", 36));
  textSize(14);

  
  int labels = color(0);
  
  Button gridSize1 = cp5.addButton("debugInfo");
    gridSize1.setPosition(200, 200);

  edit = cp5.addToggle("toggleEdit");
  edit.setPosition(420, 40);
  edit.setSize(100, 20);
  edit.captionLabel().set("Typewriter mode");
  edit.setValue(editMode);
  edit.setMode(ControlP5.SWITCH);

  record = cp5.addButton("record");
  record.setPosition(420, 10);
  record.setSize(50, 20);
  record.setWidth(100);
  record.captionLabel().set("Record");


  cp5.addTextfield("keyToSave")
    .setPosition(10, 90)
      .setSize(200, 20)
        .setFocus(true)
          .setColor(color(255, 0, 0))
            .setCaptionLabel("Key to record")
  ;   

  cp5.addTextfield("drawSprite")
    .setPosition(220, 90)
      .setSize(200, 20)
        .setFocus(true)
          .setColor(color(255, 0, 0))
            .setCaptionLabel("Sprite to play")
  ;

  lettersToSend = cp5.addTextfield("lettersToSend")
    .setPosition(430, 90)
      .setSize(200, 20)
        .setColor(color(255, 0, 0))
          .setFont(createFont("arial", 12))
            .setCaptionLabel("Letters to write...")
  ;

  cp5.addSlider("changeGridSize")
    .setPosition(10, 60)
      .setValue(10)
      .setRange(0, 30)
        ;
        
  polygonizerAngleSlider = cp5.addSlider("polygonizerAngleSlider")
    .setPosition(20, 130)
      .setValue(polygonizerAngle)
      .setRange(0, 3.14/2)
        ;
        
  renderShape = cp5.addButton("renderShape");
  renderShape.setPosition(20, 150);
  renderShape.setSize(50, 20);
  renderShape.setWidth(100);
  renderShape.captionLabel().set("Render shape");
  
  printShape = cp5.addButton("printShape");
  printShape.setPosition(130, 150);
  printShape.setSize(50, 20);
  printShape.setWidth(100);
  printShape.captionLabel().set("Print shape");
}

void draw() {
  background(0); // Set background to black

  //background(255);
  
  RG.setPolygonizerAngle(polygonizerAngle);
  
  polyshp.draw();
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
      int serialIndex = int(event.getGroup().getValue());
      setSerial(comm.serialDevices[serialIndex]);
    }
  } else if (event.isController()) {
    println("event from controller : "+event.getController().getValue()+" from "+event.getController());

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
    
    if (event.getController().getName().equals("polygonizerAngleSlider")) {
      polygonizerAngle = event.getController().getValue();
    }
  }
}


void keyPressed() {
  // The variable "key" always contains the value
  // of the most recent key pressed.
  println(lettersToSend.isFocus());

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

    case 'q':
      sendCommand("G01 Y" + distance/2 + " X" + -distance/2);
      break;
    case 'e':
      sendCommand("G01 Y" + distance/2 + " X" + distance/2);
      break;
    case 'z':
      sendCommand("G01 Y" + -distance/2 + " X" + -distance/2);
      break;
    case 'c':
      sendCommand("G01 Y" + -distance/2 + " X" + distance/2);
      break;

    case 'y':
      sendCommand("G01 Y" + distance/2);
      break;
    case 'g':
      sendCommand("G01 X-" + distance/2);
      break;
    case 'h':
      sendCommand("G01 Y-" + distance/2);
      break;
    case 'j':
      sendCommand("G01 X" + distance/2);
      break;

    case 't':
      sendCommand("G01 Y" + distance/4 + " X" + -distance/4);
      break;
    case 'u':
      sendCommand("G01 Y" + distance/4 + " X" + distance/4);
      break;
    case 'v':
      sendCommand("G01 Y" + -distance/4 + " X" + -distance/4);
      break;
    case 'm':
      sendCommand("G01 Y" + -distance/4 + " X" + distance/4);
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

public void debugInfo() {
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

void renderShape() {
  RPoint[] points = polyshp.getPoints();
  
  if(points != null){
    noFill();
    stroke(0,200,0);
    beginShape();
    for(int i=0; i<points.length; i++){
      vertex(points[i].x, points[i].y);
    }
    endShape();
  
    fill(0);
    stroke(0);
    for(int i=0; i<points.length; i++){
      ellipse(points[i].x, points[i].y,5,5);  
    }
  }
}

void printShape() {
  
  RPoint[] points = polyshp.getPoints();

  if(points != null){
    ArrayList<String> shapeGcode = new ArrayList<String>();
    shapeGcode.add("G90");
    
    for(int i=0; i<points.length; i++){
      shapeGcode.add("G01 X" + points[i].x + " Y" + points[i].y);
    }
    
    for (int i = 0; i < shapeGcode.size(); i++) {
      println(shapeGcode.get(i));
      sendCommand(shapeGcode.get(i));
    }
  } else {
    println("No points to print :<");
  }
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
  
  if (readData != null) {
    readData = readData.trim();  
    if (readData.equals("ok")) {
      println("Recieved ok");
    } else {
      println("Recieved: " + readData);
    }
  } else {
    println("Got nothing, waiting...");
    while (true) {
      delay(75);
      if (gcodeMachine.available() > 0) {
        break;
      } 
    }
    readOk();
  }
}


