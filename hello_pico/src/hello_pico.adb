with RP.Clock;
with RP.Device;
with RP.DMA;
with RP.GPIO;
with RP.PIO;
with Pico;


with HAL;

with Dac;
with R2R;

procedure Hello_Pico is
   -- hardware resources
   DAC_Ping_Channel : constant RP.DMA.DMA_Channel_Id := 0;
   DAC_Pong_Channel : constant RP.DMA.DMA_Channel_Id := 1;
   DAC_PIO_Device   : RP.PIO.PIO_Device renames RP.Device.PIO_0;
   DAC_PIO_SM       : constant RP.PIO.PIO_SM := 0;

   Ones             : array (Integer range 1 .. 4) of HAL.UInt16;
   Zeros            : array (Integer range 1 .. 4) of HAL.UInt16;
begin
   for Sample of Ones  loop Sample := 16#FFFF#; end loop;
   for Sample of Zeros loop Sample := 16#0000#; end loop;

   RP.Clock.Initialize (Pico.XOSC_Frequency);
   RP.Device.Timer.Enable;

   -- Dac.Initialize (Ping_Channel => DAC_Ping_Channel,
   --                 Pong_Channel => DAC_Pong_Channel,
   --                 Pio_Device   => DAC_PIO_Device,
   --                 Pio_SM       => DAC_PIO_SM);

   -- Pico.LED.Configure (RP.GPIO.Output);

   R2R.Initialize;

   RP.DMA.Enable;
   RP.DMA.Configure (DAC_Ping_Channel,
      (Data_Size       => RP.DMA.Transfer_16,
       Increment_Read  => True,
       Increment_Write => False,
       others          => <>));

   loop
      -- null;
      -- R2R.Go;
      -- Dac.Start;
      -- RP.Device.Timer.Delay_Milliseconds (2000);
      -- Dac.Stop;

      -- R2R.Put(1);
      RP.DMA.Start
         (Channel => DAC_Ping_Channel,
          From  => Ones'Address,
          To    => R2r.TX_Address,
          Count => Ones'Length);
      RP.Device.Timer.Delay_Milliseconds (100);

      -- R2R.Put(0);
      RP.DMA.Start
         (Channel => DAC_Ping_Channel,
          From  => Zeros'Address,
          To    => R2r.TX_Address,
          Count => Zeros'Length);
      RP.Device.Timer.Delay_Milliseconds (100);

      -- for I in 1..3 loop
      --    Pico.LED.Toggle;
      --    RP.Device.Timer.Delay_Milliseconds (100);
      -- end loop;
   end loop;
end Hello_Pico;
