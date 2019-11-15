import oscP5.*;
import netP5.*;
import java.util.Collections;
import java.util.Comparator;

OscP5 oscP5;
OscMessage myMessage;
OscP5 multicastOsc;

ArrayList<ArrayList<VProSample>> dataList;
ArrayList<Integer> dataId;

MyLock myLock;

float plottedMs = 10000.0;

void setup() {
  size(1200, 1000);
  frameRate(30);
  

  // The following is needed for Macs to get the Multicast
  System.setProperty("java.net.preferIPv4Stack" , "true");

  myLock = new MyLock();
  dataList = new ArrayList<ArrayList<VProSample>>();
  dataId = new ArrayList<Integer>();

  oscP5 = new OscP5(this, 7021);
  initializeReceiving();
}

void draw() {
  background(0);
  colorMode(HSB, 100);
  strokeWeight(2);
  
  int tSize = 32;
  textSize(tSize);
  fill(10, 100, 100);
  text("trigger", 10, (height * 0.0) + tSize);
  fill(20, 100, 100);
  text("ch1", 10, (height * 0.1) + tSize);
  fill(30, 100, 100);
  text("ch2", 10, (height * 0.2) + tSize);
  fill(40, 100, 100);
  text("ch3", 10, (height * 0.3) + tSize);
  fill(50, 100, 100);
  text("ch4", 10, (height * 0.4) + tSize);
  fill(60, 100, 100);
  text("ch5", 10, (height * 0.5) + tSize);
  fill(70, 100, 100);
  text("ch6", 10, (height * 0.6) + tSize);
  fill(80, 100, 100);
  text("ch7", 10, (height * 0.7) + tSize);
  fill(90, 100, 100);
  text("ch8", 10, (height * 0.8) + tSize);


  myLock.lock();
  
  // Sorting all data lists
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<VProSample> data = dataList.get(listInd);
  
    Collections.sort(data, new Comparator<VProSample>() {
      public int compare(VProSample acc1, VProSample acc2)
      {
        return (int)(acc1.time - acc2.time);
      }
    });
  }
  
  // Finding the max timestamp
  long maxTime = 0;
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<VProSample> data = dataList.get(listInd);
    if (data.size() > 1 && maxTime < data.get(data.size()-1).time)
    {
      maxTime = data.get(data.size()-1).time;
    }
  }
  
  // Removing old data
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<VProSample> data = dataList.get(listInd);
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
    ArrayList<VProSample> data = dataList.get(listInd);
    if (data.size() > 1)
    {
      stroke((15*listInd) % 100, 100, 100);
      
      long xStart = maxTime - (maxTime % 3000) + 3000;
      
      for (int i = 1; i < data.size(); i++)
      {
        VProSample s0 = data.get(i-1);
        VProSample s1 = data.get(i);
       
        if (s1.time - s0.time < 20)
        {
          stroke(10, 100, 100);
          line(width - ((xStart - s0.time) / plottedMs * width),
                (s0.trig * -10000.0) + (height * 0.5), 
                width - ((xStart - s1.time)  / plottedMs * width), 
                (s1.trig * -10000.0) + (height * 0.5));
          stroke(20, 100, 100);
          line(width - ((xStart - s0.time) / plottedMs * width),
                (s0.ch1 * -10000.0) + (height * 0.5), 
                width - ((xStart - s1.time)  / plottedMs * width), 
                (s1.ch1 * -10000.0) + (height * 0.5));
          stroke(30, 100, 100);
          line(width - ((xStart - s0.time) / plottedMs * width),
                (s0.ch2 * -10000.0) + (height * 0.5), 
                width - ((xStart - s1.time)  / plottedMs * width), 
                (s1.ch2 * -10000.0) + (height * 0.5));
          stroke(40, 100, 100);
          line(width - ((xStart - s0.time) / plottedMs * width),
                (s0.ch3 * -10000.0) + (height * 0.5), 
                width - ((xStart - s1.time)  / plottedMs * width), 
                (s1.ch3 * -10000.0) + (height * 0.5));
          stroke(50, 100, 100);
          line(width - ((xStart - s0.time) / plottedMs * width),
                (s0.ch4 * -10000.0) + (height * 0.5), 
                width - ((xStart - s1.time)  / plottedMs * width), 
                (s1.ch4 * -100.0) + (height * 0.5));
          stroke(60, 100, 100);
          line(width - ((xStart - s0.time) / plottedMs * width),
                (s0.ch5 * -10000.0) + (height * 0.5), 
                width - ((xStart - s1.time)  / plottedMs * width), 
                (s1.ch5 * -10000.0) + (height * 0.5));
          stroke(70, 100, 100);
          line(width - ((xStart - s0.time) / plottedMs * width),
                (s0.ch6 * -10000.0) + (height * 0.5), 
                width - ((xStart - s1.time)  / plottedMs * width), 
                (s1.ch6 * -10000.0) + (height * 0.5));
          stroke(80, 100, 100);
          line(width - ((xStart - s0.time) / plottedMs * width),
                (s0.ch7 * -10000.0) + (height * 0.5), 
                width - ((xStart - s1.time)  / plottedMs * width), 
                (s1.ch7 * -10000.0) + (height * 0.5));
          stroke(90, 100, 100);
          line(width - ((xStart - s0.time) / plottedMs * width),
                (s0.ch8 * -10000.0) + (height * 0.5), 
                width - ((xStart - s1.time)  / plottedMs * width), 
                (s1.ch8 * -10000.0) + (height * 0.5));
          
          
        }
      }
    }
  
  }
  
  myLock.unlock();
}

void initializeReceiving()
{
  multicastOsc = new OscP5(this, "239.98.98.1", 10333, OscP5.MULTICAST);
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage message)
{
  if (message.checkAddrPattern("/fsensync/vpro") == true)
  {
    int appId = message.get(0).intValue();
    String tags = message.get(1).stringValue();
    int packetNumber = message.get(2).intValue();
    int timeStamp = message.get(3).intValue();
    float trig = message.get(4).floatValue();
    float ch1 = message.get(5).floatValue();
    float ch2 = message.get(6).floatValue();
    float ch3 = message.get(7).floatValue();
    float ch4 = message.get(8).floatValue();
    float ch5 = message.get(9).floatValue();
    float ch6 = message.get(10).floatValue();
    float ch7 = message.get(11).floatValue();
    float ch8 = message.get(12).floatValue();

    myLock.lock();
    boolean found = false;
    for (int listInd = 0; listInd < dataList.size(); listInd++)
    {
      if (dataId.get(listInd) == appId)
      {
        found = true;
        ArrayList<VProSample> data = dataList.get(listInd);
        data.add(new VProSample(trig, ch1, ch2, ch3, ch4, ch5, ch6, ch7, ch8, appId, timeStamp));
      }
    }
    if (!found)
    {
      ArrayList<VProSample> data = new ArrayList<VProSample>();
      data.add(new VProSample(trig, ch1, ch2, ch3, ch4, ch5, ch6, ch7, ch8, appId, timeStamp));
      dataId.add(appId);
      dataList.add(data);
    }
    myLock.unlock();

    return;
  }
  else
  {
    {
      println("got other message: " + message.addrPattern());
      return;
    }
  }
}