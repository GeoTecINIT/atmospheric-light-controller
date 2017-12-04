import oscP5.*;
import netP5.*;
OscP5 oscP5;

char receivedString; // string received by osc/node server
void setup(){
oscP5 = new OscP5(this,3333);
}
 void receive(char s){
   receivedString=s;
 }
/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  if(theOscMessage.checkAddrPattern("/clientMsg")==true) {
    /* check if the typetag is the right one. */
    if(theOscMessage.checkTypetag("f")) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      receivedString=theOscMessage.get(0).floatValue();
      print("Key received by webserver",receivedString);
    }  
  }
}