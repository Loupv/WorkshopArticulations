import oscP5.*;
import netP5.*;
import java.util.Collections;
import java.util.Comparator;

OscP5 oscP5, oscUnity;
OscMessage myMessage;
OscP5 multicastOsc;
NetAddress myRemoteLocation;
ArrayList<ArrayList<SummarySample>> dataList;
ArrayList<Integer> dataId;

MyLock myLock;

float plottedMs = 120000.0;

void setup() {
  size(100, 100);
  frameRate(30);
  

  // The following is needed for Macs to get the Multicast
  System.setProperty("java.net.preferIPv4Stack" , "true");

  myLock = new MyLock();
  dataList = new ArrayList<ArrayList<SummarySample>>();
  dataId = new ArrayList<Integer>();

  oscP5 = new OscP5(this, 7016);
  oscUnity = new OscP5(this, 6666);
  myRemoteLocation = new NetAddress("127.0.0.1",12000);
  
  initializeReceiving();
}

void draw() {
  background(0);
  colorMode(HSB, 100);
  strokeWeight(2);
  
}

void initializeReceiving()
{
  multicastOsc = new OscP5(this, "239.98.98.1", 10333, OscP5.MULTICAST);
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage message)
{
  if (message.checkAddrPattern("/fsensync/bio/summary") == true)
  {
    int heartRate = message.get(6).intValue();
    float respirationRate = message.get(7).floatValue();
    
    OscMessage myMessage = new OscMessage("/sensors/respiration");
    myMessage.add(respirationRate);
    oscUnity.send(myMessage, myRemoteLocation); 

    myMessage = new OscMessage("/sensors/heartrate");
    myMessage.add(heartRate);
    oscUnity.send(myMessage, myRemoteLocation); 
    
    return;
  }
  
  else if (message.checkAddrPattern("/fsensync/acc") == true)
  {
    float x = message.get(4).floatValue();
    float y = message.get(5).floatValue();
    float z = message.get(6).floatValue();
    OscMessage myMessage = new OscMessage("/sensors/peak");
    
    myMessage.add(x);
    myMessage.add(y);
    myMessage.add(z);
    oscUnity.send(myMessage, myRemoteLocation);
    
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
