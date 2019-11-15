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

float plottedMs = 1000.0;
int areaHeight = 100;

PImage img1;
PImage img2;

int location1X = -100;
int location1Y = -100;
int location2X = -100;
int location2Y = -100;

void setup() {
  size(1200, 900, P3D);
  frameRate(30);

  img1 = loadImage("img01.png");
  img2 = loadImage("img02.png");

  // The following is needed for Macs to get the Multicast
  System.setProperty("java.net.preferIPv4Stack", "true");

  myLock = new MyLock();
  dataList = new ArrayList<ArrayList<TouchSample>>();
  dataId = new ArrayList<Integer>();

  oscP5 = new OscP5(this, 7014);
  initializeReceiving();
}

void draw() {
  background(255, 255, 255);
  colorMode(RGB, 100);
  strokeWeight(2);

  //stroke(0, 0, 100);
  //line(0, height - areaHeight - 10, width, height - areaHeight -10);

  myLock.lock();

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
        } else
        {
          return (int)(t1.time - t2.time);
        }
      }
    }
    );
  }

  // Finding the max timestamp
  long maxTime = 0;
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
        if (data.get(i).time < maxTime - (long)plottedMs)
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
      TouchSample t0 = data.get(data.size() - 1);

      if (listInd == 0)
      {
        location1X = (int)((t0.screenX / (float)t0.maxX) * (width-100));
        location1Y = (int)((t0.screenY / (float)t0.maxY) * (height-100));
        
        println(t0.screenX + " max: " + t0.maxX);
      }

      if (listInd == 1)
      {
        location2X = (int)((t0.screenX / (float)t0.maxX) * (width-100));
        location2Y = (int)((t0.screenY / (float)t0.maxY) * (height-100));
      }

    }
  }

  myLock.unlock();

  image(img1, location1X, location1Y);
  image(img2, location2X, location2Y);
}

void initializeReceiving()
{
  multicastOsc = new OscP5(this, "239.98.98.1", 10333, OscP5.MULTICAST);
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage message)
{
  if (message.checkAddrPattern("/fsensync/sti") == true)
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

    myLock.lock();
    boolean found = false;
    for (int listInd = 0; listInd < dataList.size(); listInd++)
    {
      if (dataId.get(listInd) == appId)
      {
        found = true;
        ArrayList<TouchSample> data = dataList.get(listInd);
        data.add(new TouchSample(pointerId, upDownEvent, screenX, screenY, maxX, maxY, appId, timeStamp));
      }
    }
    if (!found && dataList.size() < 2)
    {
      ArrayList<TouchSample> data = new ArrayList<TouchSample>();
      data.add(new TouchSample(pointerId, upDownEvent, screenX, screenY, maxX, maxY, appId, timeStamp));
      dataId.add(appId);
      dataList.add(data);
    }
    myLock.unlock();

    return;
  }

  {
    println("got other message: " + message.addrPattern());
    return;
  }
}