import oscP5.*;
import netP5.*;

OscMessage myMessage;

OscP5 unicastOsc;

void setup() {

  size(200, 200);
  frameRate(20);

  // The following is needed for Macs to get the Multicast
  System.setProperty("java.net.preferIPv4Stack" , "true");
  unicastOsc = new OscP5(this, 8000);

}

void draw() {
  background(0);
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
    println("got STI: " + appId + " " + tags + " " + packetNumber + " " + upDownEvent + " " + timeStamp 
    + " " + screenX  + " " + screenY + " " + pointerId + " " + maxX 
    + " " + maxY + " " + timeFromStartOfTouch);

    return;
  }

  if (message.checkAddrPattern("/fsensync/acc") == true)
  {
    int appId = message.get(0).intValue();
    String tags = message.get(1).stringValue();
    int packetNumber = message.get(2).intValue();
    int timeStamp = message.get(3).intValue();
    float x = message.get(4).floatValue();
    float y = message.get(5).floatValue();
    float z = message.get(6).floatValue();
    println("got ACC: " + appId + " " + tags + " " + packetNumber + " " + timeStamp + " " + x  + " " + y + " " + z);
    return;
  }

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
    println("got EDA: " + appId + " " + tags + " " + packetNumber + " " + timeStamp + " "
    + ringAddress + " " + status + " " + moodMetricNumber + " " + skinResistance + " " + x + " " + y + " " + z);
    return;
  }
  
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

    println("got BIO summary: " + appId + " " + tags + " " + packetNumber + " " + timeStamp + " "
    + harnessName + " " + batteryLevel + " " + heartRate + " " + respirationRate + " " + coreTemperature + " " 
    + breathingWaveAmplitude + " " + breathingRateConfidence + " " + heartRateRateConfidence + " "
    + ecgNoise + " " + hearRateVariability + " " + peakAcceleration);
    return;
  }
  
  if (message.checkAddrPattern("/fsensync/bio/accel") == true)
  {
    int appId = message.get(0).intValue();
    String tags = message.get(1).stringValue();
    int packetNumber = message.get(2).intValue();
    int timeStamp = message.get(3).intValue();
    String harnessName = message.get(4).stringValue();
    float x = message.get(5).floatValue();
    float y = message.get(6).floatValue();
    float z = message.get(7).floatValue();
   

    println("got BIO acceleration: " + appId + " " + tags + " " + packetNumber + " " + timeStamp + " "
    + harnessName + " " + x + " " + y + " " + z);
    return;
  }

  {
    println("got other message: " + message.addrPattern());
    return;
  }
}