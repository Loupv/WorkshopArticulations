import oscP5.*;
import netP5.*;
import java.util.Collections;
import java.util.Comparator;

OscP5 oscP5;
OscMessage myMessage;

ArrayList<ArrayList<AccelerationSample>> dataList;
ArrayList<Integer> dataId;

MyLock myLock;
ArrayList<AccelerationSample> inputBuffer;

float plottedMs = 15000.0;
float accMult = 2.0;

void setup() {
  size(1200, 800, P3D);
  frameRate(30);

  // The following is needed for Macs to get the Multicast
  System.setProperty("java.net.preferIPv4Stack", "true");

  myLock = new MyLock();
  inputBuffer = new ArrayList<AccelerationSample>();

  dataList = new ArrayList<ArrayList<AccelerationSample>>();
  dataId = new ArrayList<Integer>();

  oscP5 = new OscP5(this, 8000);
}

void draw() {
  background(0);
  colorMode(HSB, 100);
  strokeWeight(2);

  int tSize = 32;
  textSize(tSize);
  text("X", 10, (height * 0.0) + tSize);
  text("Y", 10, (height * 0.25) + tSize);
  text("Z", 10, (height * 0.5) + tSize);

  myLock.lock();
  for (int i = 0; i < inputBuffer.size(); i++)
  {
    AccelerationSample sample = inputBuffer.get(i);
    boolean found = false;
    for (int listInd = 0; listInd < dataList.size(); listInd++)
    {
      if (dataId.get(listInd) == sample.id)
      {
        found = true;
        ArrayList<AccelerationSample> data = dataList.get(listInd);
        data.add(sample);
      }
    }
    if (!found)
    {
      ArrayList<AccelerationSample> data = new ArrayList<AccelerationSample>();
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
    ArrayList<AccelerationSample> data = dataList.get(listInd);

    Collections.sort(data, new Comparator<AccelerationSample>() {
      public int compare(AccelerationSample acc1, AccelerationSample acc2)
      {
        return (int)(acc1.time - acc2.time) + ((acc1.axis - acc2.axis) * 10000000);
      }
    }
    );
  }

  // Finding the max timestamp
  long maxTime = 0;
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<AccelerationSample> data = dataList.get(listInd);
    if (data.size() > 1 && maxTime < data.get(data.size()-1).time)
    {
      maxTime = data.get(data.size()-1).time;
    }
  }

  // Removing old data
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<AccelerationSample> data = dataList.get(listInd);
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
    ArrayList<AccelerationSample> data = dataList.get(listInd);
    if (data.size() > 1)
    {
      stroke((15*listInd) % 100, 100, 100);

      long xStart = maxTime - (maxTime % 5000) + 5000;

      for (int i = 1; i < data.size(); i++)
      {
        AccelerationSample acc0 = data.get(i-1);
        AccelerationSample acc1 = data.get(i);

        if (acc1.time - acc0.time < 1000)
        {
          if (acc1.axis == 0 && acc0.axis == 0)
          {
            line(width - ((xStart - acc0.time) / plottedMs * width), 
              (acc0.value * accMult) + (height * 0.125), 
              width - ((xStart - acc1.time)  / plottedMs * width), 
              (acc1.value * accMult) + (height * 0.125));
          }
          if (acc1.axis == 1 && acc0.axis == 1)
          {
            line(width - ((xStart - acc0.time) / plottedMs * width), 
              (acc0.value * accMult) + (height * 0.375), 
              width - ((xStart - acc1.time)  / plottedMs * width), 
              (acc1.value * accMult) + (height * 0.375));
          }
          if (acc1.axis == 2 && acc0.axis == 2)
          {
            line(width - ((xStart - acc0.time) / plottedMs * width), 
              (acc0.value * accMult) + (height * 0.625), 
              width - ((xStart - acc1.time)  / plottedMs * width), 
              (acc1.value * accMult) + (height * 0.625));
          }
        }
      }
    }
  }
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage message)
{
  if (message.checkAddrPattern("/fsensync/accx") == true)
  {
    int appId = message.get(0).intValue();
    String tags = message.get(1).stringValue();
    int packetNumber = message.get(2).intValue();
    int timeStamp = message.get(3).intValue();
    float value = message.get(4).floatValue();
    int axis = 0;

    myLock.lock();
    inputBuffer.add(new AccelerationSample(value, axis, appId, timeStamp));
    myLock.unlock();

    return;
  }

  if (message.checkAddrPattern("/fsensync/accy") == true)
  {
    int appId = message.get(0).intValue();
    String tags = message.get(1).stringValue();
    int packetNumber = message.get(2).intValue();
    int timeStamp = message.get(3).intValue();
    float value = message.get(4).floatValue();
    int axis = 1;

    myLock.lock();
    inputBuffer.add(new AccelerationSample(value, axis, appId, timeStamp));
    myLock.unlock();

    return;
  }

  if (message.checkAddrPattern("/fsensync/accz") == true)
  {
    int appId = message.get(0).intValue();
    String tags = message.get(1).stringValue();
    int packetNumber = message.get(2).intValue();
    int timeStamp = message.get(3).intValue();
    float value = message.get(4).floatValue();
    int axis = 2;

    myLock.lock();
    inputBuffer.add(new AccelerationSample(value, axis, appId, timeStamp));
    myLock.unlock();

    return;
  }

  {
    println("got other message: " + message.addrPattern());
    return;
  }
}