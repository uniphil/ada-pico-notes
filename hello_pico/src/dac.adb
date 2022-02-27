with RP.Device;
with RP.Clock;
with RP.GPIO;
with Pico;

package body Dac is
   DMA_Buffer_Size : constant Natural := 4096;
   type DMA_Buffer is array (Integer range 1 .. DMA_Buffer_Size) of HAL.UInt16;

   Ping_Buffer : DMA_Buffer;
   Pong_Buffer : DMA_Buffer;
   for Ping_Buffer'Alignment use DMA_Buffer_Size;
   for Pong_Buffer'Alignment use DMA_Buffer_Size;

   Ping_Channel_Id : DMA_Channel_Id;
   Pong_Channel_Id : DMA_Channel_Id;

   ---------------
   -- Chain_DMA --
   ---------------

   procedure Chain_DMA (A, B : DMA_Channel_Id;
                        Irq  : DMA_Request_Trigger) is
   begin
      RP.DMA.Configure (Channel => A,
                        Config  => (Data_Size       => Transfer_32,
                                    Increment_Read  => True,
                                    Increment_Write => False,
                                    Ring_Wrap       => Wrap_Read,
                                    Trigger         => Irq,
                                    Chain_To        => B,
                                    others          => <>));
   end Chain_DMA;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Ping_Channel, Pong_Channel : DMA_Channel_Id) is
   begin
      Ping_Channel_Id := Ping_Channel;
      Pong_Channel_Id := Pong_Channel;
      for Sample of Ping_Buffer loop
         Sample := 0;
      end loop;
      for Sample of Pong_Buffer loop
         Sample := 0;
      end loop;

      RP.DMA.Enable;
      Chain_DMA(Ping_Channel, Pong_Channel, PIO0_TX0);  -- todo: accept PIO0_TX0
      Chain_DMA(Pong_Channel, Ping_Channel, PIO0_TX0);

      RP.DMA.Start(Channel => Pong_Channel,
                   From    => Pong_Buffer'Address,
                   To      => Pong_Buffer'Address,  -- fixme
                   Count   => HAL.UInt32 (DMA_Buffer_Size / 2));  -- /2 because dma is transferring 32bits
      RP.DMA.Disable(Pong_Channel);  -- might glitch from start ^^ but not sure how to configure addresses without starting with the pico ada stuff

      RP.DMA.Start(Channel => Ping_Channel,
             From    => Ping_Buffer'Address,
             To      => Ping_Buffer'Address,  -- fixme
             Count   => HAL.UInt32 (DMA_Buffer_Size / 2));  -- /2 because dma is transferring 32bits
      -- actually let ping start

   end Initialize;

end Dac;
