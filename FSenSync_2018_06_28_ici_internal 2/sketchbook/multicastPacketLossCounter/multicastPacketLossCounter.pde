import oscP5.*;
import netP5.*;

OscP5 oscP5;
OscMessage myMessage;

OscP5 multicastOsc;

ArrayList<Integer> lastPacketNumber;
ArrayList<Integer> packetCount;
ArrayList<Integer> dataId;
ArrayList<NumberInfo> lossArray;
ArrayList<NumberInfo> streamNumArray;
ArrayList<NumberInfo> packetCountArray;
int accumulatedLoss;

MyLock myLock;
ArrayList<PacketInfo> inputBuffer;

float plottedMs = 60000.0;

void setup() {
  size(200, 200,P3D);
  frameRate(1);

  // The following is needed for Macs to get the Multicast
  System.setProperty("java.net.preferIPv4Stack" , "true");
  initializeReceiving();

  accumulatedLoss = 0;
  lastPacketNumber = new ArrayList<Integer>();
  packetCount = new ArrayList<Integer>();
  dataId = new ArrayList<Integer>();
  lossArray = new ArrayList<NumberInfo>();
  streamNumArray = new ArrayList<NumberInfo>();
  packetCountArray = new ArrayList<NumberInfo>();
  myLock = new MyLock();
  inputBuffer = new ArrayList<PacketInfo>();

  oscP5 = new OscP5(this, 7011);
}

void draw() {
 
  myLock.lock();
  for (int i = 0; i < inputBuffer.size(); i++)
  {
    PacketInfo p = inputBuffer.get(i);
    boolean found = false; 
    for (int listInd = 0; listInd < dataId.size(); listInd++)
    {
      if (dataId.get(listInd) == p.id)
      {
        found = true;
        if (p.number > lastPacketNumber.get(listInd))
        {
          accumulatedLoss += p.number - (lastPacketNumber.get(listInd) + 1);
          lastPacketNumber.set(listInd, p.number);
          packetCount.set(listInd, packetCount.get(listInd) + 1);
        }
      }
    }
    if (!found)
    {
      dataId.add(p.id);
      lastPacketNumber.add(p.number);
      packetCount.add(1);
    }
  }
  inputBuffer.clear();
  myLock.unlock();
  

  // Saving packet count to array, increasing streamNumber and zeroing the counts
  int streamNum = 0;
  int packetNum = 0;
  for (int i = 0; i < dataId.size(); i++)
  {
    if (packetCount.get(i) > 0)
    {
      streamNum += 1;
      packetNum += packetCount.get(i);
      packetCount.set(i, 0);
    }
  }
  

  println(streamNum + " " + packetNum + " " + accumulatedLoss);

  // TODO: saving data to arrays
  long currentStamp = System.currentTimeMillis();

  // Adding new data
  lossArray.add(new NumberInfo(accumulatedLoss, currentStamp));
  streamNumArray.add(new NumberInfo(streamNum, currentStamp));
  packetCountArray.add(new NumberInfo(packetNum, currentStamp));

  // TODO: Removing old data
  //for (int listInd = 0; listInd < dataList.size(); listInd++)
  //{
  //  ArrayList<AccelerationSample> data = dataList.get(listInd);
  //  if (data.size() > 1)
  //  {
  //    for (int i = data.size()-1; i >= 0; i--)
  //    {
  //      if (data.get(i).time < maxTime - (long)plottedMs)
  //      {
  //        data.remove(i);
  //      }
  //    }
  //  }
  //}

  background(0);
  // TODO: drawing arrays
  
  accumulatedLoss = 0;
}

void initializeReceiving()
{
  multicastOsc = new OscP5(this, "239.98.98.1", 10333, OscP5.MULTICAST);
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage message)
{
  
  if (message.addrPattern().startsWith("/fsensync"))
  {
    int appId = message.get(0).intValue();
    //String tags = message.get(1).stringValue();
    int packetNumber = message.get(2).intValue();
    //int timeStamp = message.get(3).intValue();
    
    
    int streamHash = appId;
    int zeros = 1;
    for (int k = 9; k < message.addrPattern().length(); k++)
    {
      zeros = zeros * 100;
      streamHash = (streamHash + ((int)message.addrPattern().charAt(k) * zeros)) % Integer.MAX_VALUE;
    }
    
    myLock.lock();
    inputBuffer.add(new PacketInfo(streamHash, packetNumber));
    myLock.unlock();
    
    return;
  }
  
  {
    println("got other message: " + message.addrPattern());
    return;
  }
}