import oscP5.*;
import netP5.*;
import java.util.Collections;
import java.util.Comparator;

OscP5 oscP5;
OscMessage myMessage;
OscP5 multicastOsc;

ArrayList<ArrayList<SummarySample>> dataList;
ArrayList<Integer> dataId;

MyLock myLock;

float plottedMs = 120000.0;

void setup() {
  size(1200, 1000);
  frameRate(30);
  

  // The following is needed for Macs to get the Multicast
  System.setProperty("java.net.preferIPv4Stack" , "true");

  myLock = new MyLock();
  dataList = new ArrayList<ArrayList<SummarySample>>();
  dataId = new ArrayList<Integer>();

  oscP5 = new OscP5(this, 7016);
  initializeReceiving();
}

void draw() {
  background(0);
  colorMode(HSB, 100);
  strokeWeight(2);
  
  int tSize = 32;
  textSize(tSize);
  fill(10, 100, 100);
  text("batteryLevel", 10, (height * 0.0) + tSize);
  fill(20, 100, 100);
  text("heartRate", 10, (height * 0.1) + tSize);
  fill(30, 100, 100);
  text("respirationRate", 10, (height * 0.2) + tSize);
  fill(40, 100, 100);
  text("coreTemperature", 10, (height * 0.3) + tSize);
  fill(50, 100, 100);
  text("breathingWaveAmplitude", 10, (height * 0.4) + tSize);
  fill(60, 100, 100);
  text("breathingRateConfidence", 10, (height * 0.5) + tSize);
  fill(70, 100, 100);
  text("heartRateRateConfidence", 10, (height * 0.6) + tSize);
  fill(80, 100, 100);
  text("ecgNoise", 10, (height * 0.7) + tSize);
  fill(90, 100, 100);
  text("heartRateVariability", 10, (height * 0.8) + tSize);
  fill(100, 100, 100);
  text("peakAcceleration", 10, (height * 0.9) + tSize);

  fill(10, 100, 100);
  text("batteryLevel2", 10 +  width/2, (height * 0.0) + tSize);
  fill(20, 100, 100);
  text("heartRate2", 10 +  width/2, (height * 0.1) + tSize);
  fill(30, 100, 100);
  text("respirationRate2", 10 +  width/2, (height * 0.2) + tSize);
  fill(40, 100, 100);
  text("coreTemperature2", 10 +  width/2, (height * 0.3) + tSize);
  fill(50, 100, 100);
  text("breathingWaveAmplitude2", 10 +  width/2, (height * 0.4) + tSize);
  fill(60, 100, 100);
  text("breathingRateConfidence2", 10 +  width/2, (height * 0.5) + tSize);
  fill(70, 100, 100);
  text("heartRateRateConfidence2", 10 +  width/2, (height * 0.6) + tSize);
  fill(80, 100, 100);
  text("ecgNoise2", 10 +  width/2, (height * 0.7) + tSize);
  fill(90, 100, 100);
  text("heartRateVariability2", 10 +  width/2, (height * 0.8) + tSize);
  fill(100, 100, 100);
  text("peakAcceleration2", 10 +  width/2, (height * 0.9) + tSize);


  myLock.lock();
  
  // Sorting all data lists
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<SummarySample> data = dataList.get(listInd);
  
    Collections.sort(data, new Comparator<SummarySample>() {
      public int compare(SummarySample acc1, SummarySample acc2)
      {
        return (int)(acc1.time - acc2.time);
      }
    });
  }
  
  // Finding the max timestamp
  long maxTime = 0;
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<SummarySample> data = dataList.get(listInd);
    if (data.size() > 1 && maxTime < data.get(data.size()-1).time)
    {
      maxTime = data.get(data.size()-1).time;
    }
  }
  
  // Removing old data
  for (int listInd = 0; listInd < dataList.size(); listInd++)
  {
    ArrayList<SummarySample> data = dataList.get(listInd);
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
    // To change the colors you should define here a variable that depends on the listInd. Basically, listInd 0 means data from one harness, 
    // and listInd 1 is from another. 
    // If you then give your variable as the first value to the stroke methods below, you will change the hues of the graphs.
    
    long gap = 0; // Loup
    if(listInd == 0) gap = 0;
    else if(listInd == 1) gap = width / 2;
    
    
    ArrayList<SummarySample> data = dataList.get(listInd);
    if (data.size() > 1)
    {
      stroke((15*listInd) % 100, 100, 100);
      
      long xStart = maxTime - (maxTime % 10000) + 10000;
      
      for (int i = 1; i < data.size(); i++)
      {
        
        SummarySample sum0 = data.get(i-1);
        SummarySample sum1 = data.get(i);
       
        if (sum1.time - sum0.time < 2000)
        {
          stroke(10, 100, 100);
          line(width/2 - ((xStart - sum0.time) / plottedMs * width/2) + gap,
                (sum0.batteryLevel * -10.0) + (height * 0.99), 
                width/2 - ((xStart - sum1.time)  / plottedMs * width/2) + gap, 
                (sum1.batteryLevel * -10.0) + (height * 0.99));
          stroke(20, 100, 100);      
          line(width/2 - ((xStart - sum0.time) / plottedMs * width/2) + gap,
                (sum0.heartRate * -7.0) + (height * 0.99), 
                width/2 - ((xStart - sum1.time)  / plottedMs * width/2) + gap, 
                (sum1.heartRate * -7.0) + (height * 0.99));
          stroke(30, 100, 100);      
          line(width/2 - ((xStart - sum0.time) / plottedMs * width/2) + gap,
                (sum0.respirationRate * -40.0) + (height * 0.99), 
                width/2 - ((xStart - sum1.time)  / plottedMs * width/2) + gap, 
                (sum1.respirationRate * -40.0) + (height * 0.99));
          stroke(40, 100, 100);      
          line(width/2 - ((xStart - sum0.time) / plottedMs * width/2) + gap,
                (sum0.coreTemperature * -20.0) + (height * 0.99), 
                width/2 - ((xStart - sum1.time)  / plottedMs * width/2) + gap, 
                (sum1.coreTemperature * -20.0) + (height * 0.99));
          stroke(50, 100, 100);
          line(width/2 - ((xStart - sum0.time) / plottedMs * width/2) + gap,
                (sum0.breathingWaveAmplitude * -5000.0) + (height * 0.99), 
                width/2 - ((xStart - sum1.time)  / plottedMs * width/2) + gap, 
                (sum1.breathingWaveAmplitude * -5000.0) + (height * 0.99));
          stroke(60, 100, 100);      
          line(width/2 - ((xStart - sum0.time) / plottedMs * width/2) + gap,
                (sum0.breathingRateConfidence * -9.5) + (height * 0.99), 
                width/2 - ((xStart - sum1.time)  / plottedMs * width/2) + gap, 
                (sum1.breathingRateConfidence * -9.5) + (height * 0.99));
          stroke(70, 100, 100);     
          line(width/2 - ((xStart - sum0.time) / plottedMs * width/2) + gap,
                (sum0.heartRateRateConfidence * -9.5) + (height * 0.99), 
                width/2 - ((xStart - sum1.time)  / plottedMs * width/2) + gap, 
                (sum1.heartRateRateConfidence * -9.5) + (height * 0.99));
           stroke(80, 100, 100);     
           line(width/2 - ((xStart - sum0.time) / plottedMs * width/2) + gap,
                (sum0.ecgNoise * -1000000.0) + (height * 0.99), 
                width/2 - ((xStart - sum1.time)  / plottedMs * width/2) + gap, 
                (sum1.ecgNoise * -1000000.0) + (height * 0.99));
           stroke(90, 100, 100);     
           line(width/2 - ((xStart - sum0.time) / plottedMs * width/2) + gap,
                (sum0.hearRateVariability * -10.0) + (height * 0.99), 
                width/2 - ((xStart - sum1.time)  / plottedMs * width/2) + gap, 
                (sum1.hearRateVariability * -10.0) + (height * 0.99));
           stroke(100, 100, 100);     
           line(width/2 - ((xStart - sum0.time) / plottedMs * width/2) + gap,
                (sum0.peakAcceleration * -400.0) + (height * 0.99), 
                width/2 - ((xStart - sum1.time)  / plottedMs * width/2) + gap, 
                (sum1.peakAcceleration * -400.0) + (height * 0.99));
        }
      }
    }
  
  }
  
  myLock.unlock();
}

void initializeReceiving()
{
  multicastOsc = new OscP5(this, "127.0.0.1", 10333, OscP5.MULTICAST);
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage message)
{
  if (message.checkAddrPattern("/fsensync/bio/summary") == true)
  {
    int appId = message.get(0).intValue();
    String tags = message.get(1).stringValue();
    int packetNumber = message.get(2).intValue();
    int timeStamp = message.get(3).intValue();
    String harnessName = message.get(4).stringValue();
    int batteryLevel = message.get(5).intValue();
    int heartRate = message.get(6).intValue();
    float respirationRate = message.get(7).floatValue();
    float coreTemperature = message.get(8).floatValue();
    float breathingWaveAmplitude = message.get(9).floatValue();
    int breathingRateConfidence = message.get(10).intValue();
    int heartRateRateConfidence = message.get(11).intValue();
    float ecgNoise = message.get(12).floatValue();
    int hearRateVariability = message.get(13).intValue();
    float peakAcceleration = message.get(14).floatValue();

    int harnessId = 0;
    for (int k = 0; k < harnessName.length(); k++)
    {
      harnessId = (harnessId + harnessName.charAt(k) * (k+100)) % Integer.MAX_VALUE;
    }

    myLock.lock();
    boolean found = false;
    for (int listInd = 0; listInd < dataList.size(); listInd++)
    {
      if (dataId.get(listInd) == harnessId)
      {
        found = true;
        ArrayList<SummarySample> data = dataList.get(listInd);
        data.add(new SummarySample(batteryLevel, heartRate, respirationRate, coreTemperature, breathingWaveAmplitude,
          breathingRateConfidence, heartRateRateConfidence, ecgNoise, hearRateVariability, peakAcceleration, harnessId, timeStamp));
      }
    }
    if (!found)
    {
      ArrayList<SummarySample> data = new ArrayList<SummarySample>();
      data.add(new SummarySample(batteryLevel, heartRate, respirationRate, coreTemperature, breathingWaveAmplitude,
        breathingRateConfidence, heartRateRateConfidence, ecgNoise, hearRateVariability, peakAcceleration, harnessId, timeStamp));
      dataId.add(harnessId);
      dataList.add(data);
    }
    myLock.unlock();

    return;
  }
  else
  {
    if (!message.addrPattern().equals("/fsensync/bio/accel")
    && !message.addrPattern().equals("/fsensync/bio/ecg"))
    {
      println("got other message: " + message.addrPattern());
      return;
    }
  }
}
