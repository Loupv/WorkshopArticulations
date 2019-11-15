
class TouchSample {
  
  float screenX;
  float screenY;
  int maxX;
  int maxY;
  int pointerId;
  int upDownEvent;
  int time;
  int id;
  
  TouchSample(int pointerId, int upDownEvent, float screenX, float screenY, int maxX, int maxY, int id, int time)
  {
    this.pointerId = pointerId;
    this.upDownEvent = upDownEvent;
    this.screenX = screenX;
    this.screenY = screenY;
    this.screenX = screenX;
    this.maxX = maxX;
    this.maxY = maxY;
    this.id = id;
    this.time = time;
  }
  
}