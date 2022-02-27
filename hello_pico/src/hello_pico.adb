with RP.Device;
with RP.Clock;
with RP.GPIO;
with Pico;

with Dac;

procedure Hello_Pico is

begin
   RP.Clock.Initialize (Pico.XOSC_Frequency);
   RP.Device.Timer.Enable;

   Dac.Initialize (Ping_Channel => 0,
                   Pong_Channel => 1);

   Pico.LED.Configure (RP.GPIO.Output);


   loop
      Pico.LED.Toggle;
      RP.Device.Timer.Delay_Milliseconds (100);
   end loop;
end Hello_Pico;
