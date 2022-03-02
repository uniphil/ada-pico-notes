package body R2R is

   Program        : constant RP.PIO.Program :=
      (1 => Encode (SHIFT_OUT'  (Destination => PINS,
                                 Bit_Count => 16,
                                 others => <>)));
   Program_Offset : constant PIO_Address := 0;
   SM             : constant PIO_SM := 0;
   Config         : PIO_SM_Config := Default_SM_Config;
   P              : PIO_Device renames RP.Device.PIO_0;

   procedure Initialize is
   begin
      RP.Clock.Initialize (Pico.XOSC_Frequency);
      Pico.LED.Configure (RP.GPIO.Output, RP.GPIO.Floating, P.GPIO_Function);

      P.Enable;
      P.Load (Program, Program_Offset);

      Set_Out_Pins (Config, Pico.LED.Pin, 1);
      Set_Set_Pins (Config, Pico.LED.Pin, 1);
      Set_Wrap (Config,
         Wrap_Target => Program_Offset,
         Wrap        => Program_Offset + Program'Length);
      Set_Clock_Frequency (Config, 100_000);
      Set_Out_Shift (Config,
         Shift_Right    => True,
         Autopull       => True,
         Pull_Threshold => 1);
      Set_FIFO_Join (Config,
         Join_TX => True,
         Join_RX => False);

      P.SM_Initialize (SM,
         Initial_PC => Program_Offset,
         Config     => Config);
      P.Set_Pin_Direction (SM, Pico.LED.Pin, Output);
      P.Set_Enabled (SM, True);

      RP.Device.Timer.Enable;
   end Initialize;

   procedure Start is
   begin
      loop
         P.Put (SM, 1);
         RP.Device.Timer.Delay_Milliseconds (300);
         P.Put (SM, 0);
         RP.Device.Timer.Delay_Milliseconds (300);
      end loop;
   end Start;

   function TX_Address
      return System.Address
   is (P.TX_FIFO_Address (SM));

   procedure Put (Sample : HAL.UInt16) is
      Pin : HAL.UInt16; for Pin'Address use TX_Address;
   begin
      Pin := Sample;
   end Put;

end R2R;
