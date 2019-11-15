import oscP5.*;
import netP5.*;
import java.util.Collections;
import java.util.Comparator;

OscP5 oscP5;
OscMessage myMessage;
OscP5 multicastOsc;

ArrayList<ArrayList<TouchSample>> dataList;
ArrayList<Integer> dataId;

MyLock myLock;
ArrayList<TouchSample> inputBuffer;

float plottedMs = 10000.0;
int areaHeight = 100;

void setup() {
  size(1200, 900,P3D);
  frameRate(30);

  // The following is needed for Macs to get the Multicast
  System.setProperty("java.net.preferIPv4Stack" , "true");

  myLock = new MyLock();
  inputBuffer = new ArrayList<TouchSample>();
  
  dataList = new ArrayList<ArrayList<TouchSample>>();
  dataId = new ArrayList<Integer>();

  oscP5 = new OscP5(this, 7014);
  initializeReceiving();
}

void draw() {
  background(0);
  colorMode(HSB, 100);
  strokeWeight(2);
  
  stroke(0, 0, 100);
  line(0, height - areaHeight - 10, width, height - areaHeight -10);

  myLock.lock();
  for (int i = 0; i < inputBuffer.size(); i++)
  {
    TouchSample sample = inputBuffer.get(i);
    boolean found = false;
    for (int listInd = 0; listInd < dataList.size(); listInd++)
    {
      if (dataId.get(listInd) == sample.id)
      {
        found = true;
        ArrayList<TouchSample> data = dataList.get(listInd);
        data.add(sample);
      }
    }
    if (!found)
    {
      ArrayList<TouchSample> data = new ArrayList<TouchSample>();
      data.add(sample);
      dataId.add(sample.id);
      dataList.add(data);
    }
  }
  inputBuffer.clear();
  myLock.unlock();

  // Sorting all data lists
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<TouchSample> data = dataList.get(listInd);
  
    Collections.sort(data, new Comparator<TouchSample>() {
      public int compare(TouchSample t1, TouchSample t2)
      {
        if (t1.pointerId != t2.pointerId)
        {
          return (int)(t1.pointerId - t2.pointerId);
        }
        else
        {
          return (int)(t1.time - t2.time);
        }
      }
    });
  }
  
  // Finding the max timestamp
  int maxTime = 0;
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<TouchSample> data = dataList.get(listInd);
    for (int i = 0; i < data.size(); i++)
    {
      if (maxTime < data.get(i).time)
      {
        maxTime = data.get(i).time;
      }
    }
  }
  
  // Removing old data
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<TouchSample> data = dataList.get(listInd);
    if (data.size() > 1)
    {
      for (int i = data.size()-1; i >= 0; i--)
      {
        if (data.get(i).time < maxTime - plottedMs)
        {
          data.remove(i);
        }
      }
    }
  }
  
  // Plotting the data
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<TouchSample> data = dataList.get(listInd);
    if (data.size() > 1)
    {
      stroke((15*listInd) % 100, 100, 100);
      
      int xStart = maxTime - (maxTime % 5000) + 5000;
      
      for (int i = 1; i < data.size(); i++)
      {
        TouchSample t0 = data.get(i-1);
        TouchSample t1 = data.get(i);
       
        if (t0.pointerId == t1.pointerId && t0.upDownEvent != 1 && t0.time > maxTime - 1000
            && (t1.time - t0.time) <= t1.timeFromStartOfTouch)
        {
          strokeWeight(2);
          line((t0.screenX / (float)t0.maxX) * width,
                (t0.screenY / (float)t0.maxY) * (height-100), 
                (t1.screenX / (float)t1.maxX) * width, 
                (t1.screenY / (float)t1.maxY) * (height-100));
        }
        
        if (t0.upDownEvent != 0  && t0.time > maxTime - 1000)
        {
          strokeWeight(8);
          point((t0.screenX / (float)t0.maxX) * width,
                (t0.screenY / (float)t0.maxY) * (height-100));
        }
        
        if (t1.upDownEvent != 0  && t1.time > maxTime - 1000)
        {
          strokeWeight(8);
          point((t1.screenX / (float)t1.maxX) * width,
                (t1.screenY / (float)t1.maxY) * (height-100));
        }
        
        if (t0.pointerId == t1.pointerId && t0.upDownEvent != 1 
            && (t1.time - t0.time) <= t1.timeFromStartOfTouch)
        {
          strokeWeight(4);
          line(width - ((xStart - t0.time) / plottedMs * width),
                ((listInd * 9) % areaHeight) + (height - areaHeight), 
                width - ((xStart - t1.time)  / plottedMs * width), 
                ((listInd * 9) % areaHeight) + (height - areaHeight));
        }
        
      }
    }
  }
  
}

void initializeReceiving()
{
  multicastOsc = new OscP5(this, "239.98.98.1", 10333, OscP5.MULTICAST);
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage message)
{
  if (message.checkAddrPattern("/fsensync/sti") == true
      || message.checkAddrPattern("/fsensync/cart") == true)
  {
    int appId = message.get(0).intValue();
    String tags = message.get(1).stringValue();
    int packetNumber = message.get(2).intValue();
    int timeStamp = message.get(3).intValue();
    int pointerId = message.get(4).intValue();
    int upDownEvent = message.get(5).intValue();
    float screenX = message.get(6).floatValue();
    float screenY = message.get(7).floatValue();
    int maxX = message.get(8).intValue();
    int maxY = message.get(9).intValue();
    int timeFromStartOfTouch = message.get(10).intValue();

    myLock.lock();
    inputBuffer.add(new TouchSample(pointerId, upDownEvent, screenX, screenY, maxX, maxY, appId, timeStamp, timeFromStartOfTouch));
    myLock.unlock();

    return;
  }

  {
    println("got other message: " + message.addrPattern());
    return;
  }
}