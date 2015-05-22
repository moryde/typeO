class Comm {
  
  public String[] serialDevices;
  
  private DropdownList serialDL;

  public Comm(int uiX, int uiY) {
    Group g = cp5.addGroup("Serial Settings");
    g.setPosition(10,20);
    g.setBackgroundHeight(100);
    g.setSize(400,30);
    g.setBackgroundColor(color(255, 50));

    Button serialRefresh = cp5.addButton("serialRefresh");
    serialRefresh.setGroup(g);
    serialRefresh.setPosition(10,10);
    serialRefresh.setWidth(100);
    serialRefresh.captionLabel().set("Refresh serial list");
    serialRefresh.addListener(new ControlListener() {
      private Comm c;
      

      
      public void controlEvent(ControlEvent e) {
        println("LOL");
        c.populateSerialSelect();
      }
    });

    this.serialDL = cp5.addDropdownList("serialSelect");
    this.serialDL.setGroup(g);
    this.serialDL.setPosition(110, 25);
    this.serialDL.setSize(250, 250);
    this.serialDL.setBackgroundColor(color(190));
    this.serialDL.setItemHeight(15);
    this.serialDL.setBarHeight(15);
    this.serialDL.captionLabel().set("Select serial");
    this.serialDL.captionLabel().style().marginTop = 3;
    this.serialDL.captionLabel().style().marginLeft = 3;
    this.serialDL.valueLabel().style().marginTop = 3;
    this.serialDL.setColorBackground(color(60));
    this.serialDL.setColorActive(color(255, 128));

    this.populateSerialSelect();
  }

  public void draw() {
  }

  private void populateSerialSelect() {
    this.serialDL.clear();
    this.serialDevices = Serial.list();
    for (int i = 0; i < this.serialDevices.length; i++) {
      this.serialDL.addItem(serialDevices[i], i);
    }
  }
}

