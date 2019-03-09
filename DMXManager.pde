import dmxP512.*;
import processing.serial.*;

boolean winMode = System.getProperty("os.name").toLowerCase().indexOf("win") >= 0; //automatic detection
String portToUse = "";
DMXManager manager;
public class DMXManager extends Component
{
  public ArrayList<DMXGroup> groups;
  public final int numGroups = 1;
  public boolean portOpened = false;
  public boolean useESP = false;
  public int selectedGroup;
  public IntList ESPvalues; 
  public int ESPMaster;
  DMXSlider masterSlider;
  long lastSendPing=0;
  long lastRcvPing = 0;
  //DMX
  DmxP512 dmxOutput;
  Serial espPort;
  
  public DMXManager(PApplet parent)
  {

    groups = new ArrayList<DMXGroup>();
    ESPvalues = new IntList();
    for(int i=0;i<numGroups;i++)
    {
      DMXGroup dg =new DMXGroup(parent); 
      groups.add(dg);
      for(int j = 0 ; j < dg.numChannels;j++){ESPvalues.append(0);}
    }
    
    parent.registerMethod("keyEvent",this);
    
    masterSlider = new DMXSlider(this,parent);
    masterSlider.sliderColor = color(200,50,30);
    setSelectedGroup(0);
    
    
    try
    {
      String [] allPorts = Serial.list();
 //<>//
      for (String s :allPorts){
        println("checking Port : "+s);
       if (s.contains("usbserial-EN") ){
         dmxOutput= new DmxP512(parent,512,false);
         dmxOutput.setupDmxPro(s,115200);
         portOpened = true;
         break;
       }
       else if( s.contains("usbserial-DN")){
         println("using esp");
         espPort = new Serial(parent, s, 115200);
          portOpened = true;
          useESP = true;
          break;
       }
 
         
      }
      if(!portOpened && (portToUse!="")){
          espPort = new Serial(parent, portToUse, 115200);
          portOpened = true;
          useESP = true;
      }
      /*if(!portOpened){
        dmxOutput= new DmxP512(parent,512,false);
        println("try to open default windows port");
        dmxOutput.setupDmxPro("COM8",115200);
        portOpened = true;
      }*/
    }catch(Exception e)
    {
      println(e);
      println("Error connecting DMX");
      //noLoop();
      portOpened = false;
    }
    
    loadDataFile();
    
    if(portOpened){
      long t = millis();
      lastSendPing=0;
      lastRcvPing=t;
    }
  }

  
   public void draw()
  {
    pushMatrix();
    
    int margin = 10;
    int gap = 5;
    
    masterSlider.x = margin;
    masterSlider.y = margin;
    masterSlider.width = 30;
    masterSlider.height = height-margin*2;
    masterSlider.draw();
    
    int startX = masterSlider.x+masterSlider.width+gap;
    int groupHeight = ((height-margin*2) - gap*(groups.size()-1))/groups.size();
    
    int i = 0;
    for(DMXGroup g : groups) 
    {
      g.x = startX+margin;
      g.y = margin+i*(groupHeight+gap);
      g.width = width-margin*2-startX;
      g.height = groupHeight;
      g.draw();
      i++;
    }
    popMatrix();
  }
  public boolean checkConnection(){
    
    if(portOpened){
      if(useESP){
      long t = millis();
      
      int av = espPort.available();
      if( av >0){
      lastRcvPing = t; //<>//
    }
      
      int pingTime = 1000;
      if(t-lastSendPing > pingTime){
        if(lastSendPing-lastRcvPing>4*pingTime){
        portOpened=false; //<>//
        espPort.stop();
        return false;
        }
        espPort.write('p'); //<>//
        espPort.write('\n');
        lastSendPing=t;
      }

 //<>//
    }

  }
  else{
      return false; //<>//
   }
  return true;
  }
  public void setSelectedGroup(int index)
  {
    groups.get(selectedGroup).setSelected(false);
    int channel = groups.get(selectedGroup).selectedChannel;
    selectedGroup = min(max(index,0),groups.size()-1);
    groups.get(selectedGroup).setSelected(true);
    groups.get(selectedGroup).setSelectedChannel(channel);
    
  }
  
  public void keyEvent(KeyEvent e)
  {
    if(e.getAction() == KeyEvent.PRESS)
    {
      switch(e.getKeyCode())
      {
        case DOWN:
        setSelectedGroup(selectedGroup+1);
        break;
        
        case UP:
        setSelectedGroup(selectedGroup-1);
        break;
      }
    }
    
    switch(e.getKey())
    {
      case 's':
      saveDataFile();
      break;
      
      case 'l':
      loadDataFile();
      break;
    }
  }
  
  public void sendDMX()
  {if(!portOpened)return;
  
  if(useESP){
    int mV = round(masterSlider.value*255);
    if(mV!=ESPMaster){
      ESPMaster=mV;
      espPort.write('m');
      espPort.write((char)ESPMaster);
    }
  }
    int listIdx = 0;
    for(DMXGroup g : groups) 
    {
      for(DMXChannel c : g.channels)
      {
        
        
        if(c.channel == 0) continue;
        float value = c.slider.value*masterSlider.value*g.groupSlider.value;
        
         
        if(useESP){
          int espValue = (int)(value*255.0);//65535.0);
          boolean hasChanged = ESPvalues.get(listIdx)!=espValue;//c.slider.verifyChanged()
          if(hasChanged ){
          espPort.write('l');
          espPort.write((char)(c.channel+48-1));
          espPort.write((char)espValue);
          //espPort.write((char)espValue>>8);
          //espPort.write('\n');
          }
          ESPvalues.set(listIdx,espValue);
          listIdx++;
        }
        else{
          int dmxValue = round(value*255);
        dmxOutput.set(c.channel,dmxValue);
        }

      }
    }
  }
  
  
  public void setMasterValue(float value)
  {
    masterSlider.setValue(value);
  }
  
  
  public void setGroupValue(int group, float value)
  {
    if(group < 0 || group >= groups.size()) return;
    groups.get(group).groupSlider.setValue(value);
  }
  
  public void setChannelValue(int group, int channel, float value)
  {
      if(group < 0 || group >= groups.size()) return;
      DMXGroup g =  groups.get(group);
      if(channel < 0 || channel >= g.channels.size()) return;
      g.channels.get(channel).slider.setValue(value);
  }
  
  public JSONObject getData()
  {
    JSONObject data = new JSONObject();

    data.setFloat("masterVolume",masterSlider.value);
    
    JSONArray groupData = new JSONArray();
    int i=0;
    for(DMXGroup g : groups)
    {
      groupData.setJSONObject(i,g.getData());
      i++;
    }
    
    data.setJSONArray("groups",groupData);
    
    return data;
  }
  
  
  public void loadData(JSONObject data)
  {
    masterSlider.setValue(data.getFloat("masterVolume"));
    JSONArray groupsData = data.getJSONArray("groups");
    
    for(int i=0;i<groupsData.size() && i<groups.size();i++)
    {
      groups.get(i).loadData(groupsData.getJSONObject(i));
    }
  }
  
  
  void saveDataFile()
  {
      println("saving data/config.json");
      saveJSONObject(getData(), "data/config.json");
  }
  
  void loadDataFile()
  {
    try
    {
      JSONObject data =loadJSONObject("data/config.json");
      loadData(data);
    }catch(Exception e)
    {
      println("Error loading file : "+e.getStackTrace());
    }
  }
    
}