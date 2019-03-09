import oscP5.*;
import netP5.*;
import controlP5.*;
import java.util.*;

ControlP5 cp5;
ScrollableList scList;
OscP5 oscP5;
NetAddress myRemoteLocation;

boolean managerLoaded = false;
int headerHeight=30;
int h = 400;
void setup() 
{
   thread("createManager");

  loadPrefFile();
 
 cp5 = new ControlP5(this);
  /* add a ScrollableList, by default it behaves like a DropdownList */
  scList = cp5.addScrollableList("dropdown")
     .setPosition(0, headerHeight)
     .setSize(200, h-headerHeight)
     .setBarHeight(headerHeight)
     .setItemHeight(headerHeight)
     // .setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
     ;
  refreshSerialList();
  oscP5 = new OscP5(this,12001);
  oscP5.plug(this,"anyMsg","/*");
  oscP5.plug(this,"setMasterValue","/master");
  oscP5.plug(this,"setGroupValue","/group");
  oscP5.plug(this,"setChannelValue","/channel");
  //oscP5.plug(this,"setChannel1","/channel/1");
  //oscP5.plug(this,"setChannel2","/channel/2");
  
  //oscP5.plug(this,"setChannel3","/channel/3");
  //oscP5.plug(this,"setChannel4","/channel/4");
  //oscP5.plug(this,"setChannel5","/channel/5");
  //oscP5.plug(this,"setChanneltest","/test");
  size(400,400,P2D);  
  frameRate(30);
}



void createManager(){
  managerLoaded = false;
  manager = new DMXManager(this);
  synchronized(this){
    managerLoaded = true;
    }
}
void refreshSerialList(){
  String [] allPorts = Serial.list();
  scList.setItems(allPorts);
  scList.update();
}
void dropdown(int n) {
  /* request the selected item based on index n */

  portToUse = cp5.get(ScrollableList.class, "dropdown").getItem(n).get("name")+"";
  println(portToUse);
  managerLoaded = false;
    thread("createManager");
    savePrefFile();
}
void draw() {
  background(0);
  if(managerLoaded && manager.portOpened){
if(scList.isVisible()){
  scList.setVisible(false);
}
  
  
  manager.x = 0;
  manager.y = headerHeight;
  manager.width = width-20;
  manager.height = height-headerHeight;
  manager.draw();
  
  manager.sendDMX();

  pushStyle();
  fill(50,255,20);
  ellipse(width-15,15,10,10);
  popStyle();   
  }
  else{
    textSize(headerHeight);
    text("connecting", 10, headerHeight-4); 
    fill(0, 102, 153);
    if(!scList.isVisible()){
  scList.setVisible(true);
}
  }
   /* if(managerLoaded && !manager.checkConnection()){
    
    delay(1500);
    if(!manager.checkConnection()){
    managerLoaded = false;
    thread("createManager");
    return;
    }
  }*/
}


void anyMsg(){
  print("any msg");
}
void setMasterValue(float value)
{
  manager.setMasterValue(value);
}


void setGroupValue(int group, float value)
{
  manager.setGroupValue(group,value);
}

void setChannelValue(int group, int channel, float value)
{
  manager.setChannelValue(group,channel, value);
}


void oscEvent(OscMessage msg) {
  if(msg.checkAddrPattern("/channel/0")){
      manager.setChannelValue(0,0, msg.get(0).floatValue());
  }   
  if(msg.checkAddrPattern("/channel/1")){
      manager.setChannelValue(0,1, msg.get(0).floatValue());
  }
    if(msg.checkAddrPattern("/channel/2")){
      manager.setChannelValue(0,2, msg.get(0).floatValue());
  }
    if(msg.checkAddrPattern("/channel/3")){
      manager.setChannelValue(0,3, msg.get(0).floatValue());
  }
    if(msg.checkAddrPattern("/channel/4")){
      manager.setChannelValue(0,4, msg.get(0).floatValue());
  }
    if(msg.checkAddrPattern("/channel/5")){
      manager.setChannelValue(0,5, msg.get(0).floatValue());
  }

}

  public JSONObject getPrefs()
  {
    JSONObject data = new JSONObject();

    data.setString("portToUse",portToUse);

    return data;
  }
  
  
  public void loadPrefs(JSONObject data)
  {
    portToUse = data.getString("portToUse");
  }
  
  void savePrefFile()
  {
      println("saving data/prefs.json");
      saveJSONObject(getPrefs(), "data/prefs.json");
  }
  
  void loadPrefFile()
  {
    try
    {
      JSONObject data =loadJSONObject("data/prefs.json");
      loadPrefs(data);
    }catch(Exception e)
    {
      println("Error loading file : "+e.getStackTrace());
    }
  }