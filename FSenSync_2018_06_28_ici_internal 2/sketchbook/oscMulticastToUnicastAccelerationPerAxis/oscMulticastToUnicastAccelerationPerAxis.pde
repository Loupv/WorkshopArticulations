import oscP5.*;
import netP5.*;

OscP5 oscP5;
OscMessage myMessage;

OscP5 multicastOsc;

NetAddress myRemoteLocation;

void setup() {
  
  size(200, 200);
  frameRate(20);

  System.setProperty("java.net.preferIPv4Stack" , "true");
  multicastOsc = new OscP5(this, "239.98.98.1", 10333, OscP5.MULTICAST);
  myRemoteLocation = new NetAddress("127.0.0.1", 8000);
  oscP5 = new OscP5(this, 7013);
}

void draw() {
  background(0);
  
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage message)
{
  if (message.checkAddrPattern("/fsensync/acc") == true)
  {
    int appId = message.get(0).intValue();
    String tags = message.get(1).stringValue();
    int packetNumber = message.get(2).intValue();
    int timeStamp = message.get(3).intValue();
    float x = message.get(4).floatValue();
    float y = message.get(5).floatValue();
    float z = message.get(6).floatValue();

    OscMessage xMesssage = new OscMessage("/fsensync/accx");
    xMesssage.add(appId);
    xMesssage.add(tags);
    xMesssage.add(packetNumber);
    xMesssage.add(timeStamp);
    xMesssage.add(x);
    oscP5.send(xMesssage, myRemoteLocation);
    
    OscMessage yMesssage = new OscMessage("/fsensync/accy");
    yMesssage.add(appId);
    yMesssage.add(tags);
    yMesssage.add(packetNumber);
    yMesssage.add(timeStamp);
    yMesssage.add(y);
    oscP5.send(yMesssage, myRemoteLocation); 
    
    OscMessage zMesssage = new OscMessage("/fsensync/accz");
    zMesssage.add(appId);
    zMesssage.add(tags);
    zMesssage.add(packetNumber);
    zMesssage.add(timeStamp);
    zMesssage.add(z);
    oscP5.send(zMesssage, myRemoteLocation); 
    
    return;
  }
  
}