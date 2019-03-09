public class DMXSlider extends Component
{
  float value;
  PApplet parent;
  color sliderColor;
  int opacity;
  boolean hasChanged;
  
  public boolean dragging;
  
  public DMXSlider(Component parentComponent, PApplet parent)
  {
    super(parentComponent);
    
    name = "slider";
    this.parent = parent;
    parent.registerMethod("mouseEvent", this);
    sliderColor = color(0,150,250);
    opacity = 255;
    hasChanged = true;
  }
  
  void draw()
  {
    pushMatrix();
    pushStyle();
    parent.translate(this.x,this.y);
    fill(50);
    rect(0,0,this.width,this.height);
    fill(sliderColor,opacity);
    
    rect(0,(1-value)*this.height,this.width,value*this.height);
    popStyle();
    popMatrix();
  }
  
  public void mouseEvent(MouseEvent e)
  {
    switch(e.getAction())
    {
      case MouseEvent.PRESS:
      dragging = isInRect();
      break;
      
      case MouseEvent.DRAG:
      if(dragging)
      {
        PVector relMouse = getRelativeMouse();
        setValue( min(max(1-relMouse.y,0),1));
      }
      break;
      
      case MouseEvent.RELEASE:
      dragging = false;
      break;
    }
    
  }
  
  public void setValue(float newVal)
  {
    hasChanged = newVal!=value;
    value = min(max(newVal,0),1);
    
  }
  public float getValue(){
    return value;
  }
  public boolean verifyChanged(){
    if(hasChanged){
      hasChanged = false;
      return true;
    }
    return false;
  }
}