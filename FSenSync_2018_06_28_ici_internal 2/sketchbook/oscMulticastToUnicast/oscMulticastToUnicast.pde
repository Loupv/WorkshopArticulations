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
  if (message.addrPattern().startsWith("/fsensync"))
  {
    oscP5.send(message, myRemoteLocation); 
    //println(message.typetag());
    return;
  }
  
  {
    println("got other message: " + message.addrPattern());
    return;
  }
}