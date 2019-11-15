import oscP5.*;
import netP5.*;
import java.util.Collections;
import java.util.Comparator;

OscP5 oscP5;
OscMessage myMessage;
OscP5 multicastOsc;

ArrayList<ArrayList<EdaSample>> dataList;
ArrayList<Integer> dataId;

MyLock myLock;
ArrayList<EdaSample> inputBuffer;

float plottedMs = 60000.0;
float accMult = 2.0;

void setup() {
  size(1200, 800,P3D);
  frameRate(30);

  // The following is needed for Macs to get the Multicast
  System.setProperty("java.net.preferIPv4Stack" , "true");

  myLock = new MyLock();
  inputBuffer = new ArrayList<EdaSample>();
  
  dataList = new ArrayList<ArrayList<EdaSample>>();
  dataId = new ArrayList<Integer>();

  oscP5 = new OscP5(this, 7012);
  initializeReceiving();
}

void draw() {
  background(0);
  colorMode(HSB, 100);
  strokeWeight(2);

  myLock.lock();
  for (int i = 0; i < inputBuffer.size(); i++)
  {
    EdaSample sample = inputBuffer.get(i);
    boolean found = false;
    for (int listInd = 0; listInd < dataList.size(); listInd++)
    {
      if (dataId.get(listInd) == sample.id)
      {
        found = true;
        ArrayList<EdaSample> data = dataList.get(listInd);
        data.add(sample);
      }
    }
    if (!found)
    {
      ArrayList<EdaSample> data = new ArrayList<EdaSample>();
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
    ArrayList<EdaSample> data = dataList.get(listInd);
  
    Collections.sort(data, new Comparator<EdaSample>() {
      public int compare(EdaSample eda1, EdaSample eda2)
      {
        return (int)(eda1.time - eda2.time);
      }
    });
  }
  
  // Finding the max timestamp
  long maxTime = 0;
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<EdaSample> data = dataList.get(listInd);
    if (data.size() > 1 && maxTime < data.get(data.size()-1).time)
    {
      maxTime = data.get(data.size()-1).time;
    }
  }
  
  // Removing old data
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<EdaSample> data = dataList.get(listInd);
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
    ArrayList<EdaSample> data = dataList.get(listInd);
    if (data.size() > 1)
    {
      stroke((15*listInd) % 100, 100, 100);
      
      long xStart = maxTime - (maxTime % 5000) + 5000;
      
      for (int i = 1; i < data.size(); i++)
      {
        EdaSample acc0 = data.get(i-1);
        EdaSample acc1 = data.get(i);
       
        if (acc1.time - acc0.time < 1000)
        {
          line(width - ((xStart - acc0.time) / plottedMs * width),
                (acc0.x * accMult) + (height * 0.10), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                (acc1.x * accMult) + (height * 0.10));
          
          line(width - ((xStart - acc0.time) / plottedMs * width),
                (acc0.y * accMult) + (height * 0.25), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                (acc1.y * accMult) + (height * 0.25));
          
          line(width - ((xStart - acc0.time) / plottedMs * width),
                (acc0.z * accMult) + (height * 0.40), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                (acc1.z * accMult) + (height * 0.40));
          
          float abs0 = (float)Math.sqrt((acc0.x * acc0.x) + (acc0.y * acc0.y) + (acc0.z * acc0.z));
          float abs1 = (float)Math.sqrt((acc1.x * acc1.x) + (acc1.y * acc1.y) + (acc1.z * acc1.z));
          
          line(width - ((xStart - acc0.time) / plottedMs * width),
                ((-abs0 + 0.0) * accMult) + (height * 0.55), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                ((-abs1 + 0.0) * accMult) + (height * 0.55));
                
          line(width - ((xStart - acc0.time) / plottedMs * width),
                ((-acc0.mm + 0.0)) + (height * 0.99), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                ((-acc1.mm + 0.0)) + (height * 0.99));
           
           float edaMin = 14500.0;
           float edaRange = 4000.0;
           float edaPlotRange = 0.4;
           line(width - ((xStart - acc0.time) / plottedMs * width),
                (-(((float)(acc0.skin) - edaMin) / edaRange) * (edaPlotRange * height)) + (height * 0.95), 
                width - ((xStart - acc1.time)  / plottedMs * width), 
                (-(((float)(acc1.skin) - edaMin) / edaRange) * (edaPlotRange * height)) + (height * 0.95));

        }
      }
    }
  
  }
  
  int tSize = 32;
  textSize(tSize);
  text("X", 10, (height * 0.05) + tSize);
  text("Y", 10, (height * 0.20) + tSize);
  text("Z", 10, (height * 0.35) + tSize);
  text("abs acc", 10, (height * 0.45) + tSize);
  text("skin resistance", 10, (height * 0.75) + tSize);
  text("MM number", 10, (height * 0.95) + tSize);
}

void initializeReceiving()
{
  multicastOsc = new OscP5(this, "239.98.98.1", 10333, OscP5.MULTICAST);
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage message)
{
  if (message.checkAddrPattern("/fsensync/eda") == true)
  {
    int appId = message.get(0).intValue();
    String tags = message.get(1).stringValue();
    int packetNumber = message.get(2).intValue();
    int timeStamp = message.get(3).intValue();
    String ringAddress = message.get(4).stringValue();
    int status = message.get(5).intValue();
    int moodMetricNumber = message.get(6).intValue();
    int skinResistance = message.get(7).intValue();
    float x = message.get(8).floatValue();
    float y = message.get(9).floatValue();
    float z = message.get(10).floatValue();

    int ringId = 0;
    int zeros = 1;
    for (int k = 0; k < ringAddress.length(); k++)
    {
      zeros = zeros * 100;
      ringId = (ringId + ((int)ringAddress.charAt(k) * zeros)) % Integer.MAX_VALUE;
    }

    myLock.lock();
    inputBuffer.add(new EdaSample(x, y, z, ringId, timeStamp, skinResistance, moodMetricNumber));
    myLock.unlock();

    return;
  }

  {
    println("got other message: " + message.addrPattern());
    return;
  }
}