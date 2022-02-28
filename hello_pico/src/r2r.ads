with HAL;
with Pico;
with RP.PIO.Encoding; use RP.PIO.Encoding;
with RP.PIO; use RP.PIO;
with RP.Device;
with RP.Clock;
with RP.GPIO;
with System;


package R2R is

   procedure Initialize;

   procedure Start;

   function TX_Address
      return System.Address;

   procedure Put (Sample : HAL.UInt16);

end R2R;
