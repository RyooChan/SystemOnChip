library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_arith.all;
   use ieee.std_logic_unsigned.all;

entity uart_rx is
   port(
      nRst     : in std_logic;
      clk      : in std_logic; -- clk
      serialin : in std_logic; -- serial data in
      rx_data  : out std_logic_vector(7 downto 0);
      valid    : out std_logic
   );
end uart_rx;

architecture BEH of uart_rx is

   type   state_type is (IDLE, START, RECEIVE, PARITY, STOP);
   signal state      : state_type;
   signal cnt        : std_logic_vector(5 downto 0);
   signal pclk       : std_logic;
   signal pcnt       : std_logic_vector(2 downto 0);
   signal bit_cnt    : std_logic_vector(2 downto 0);
   signal serialin_d : std_logic;
   signal flag       : std_logic;
   signal xmtdata    : std_logic_vector(7 downto 0);

begin

   process(nRst, clk)
   begin
      if(nRst = '0') then
         cnt  <= (others => '0');
         pclk <= '0';
      elsif rising_edge(clk) then
         if(cnt = 53) then
            cnt  <= (others => '0'); 
            pclk <= not pclk;
         else
            cnt  <= cnt + 1;
         end if;      
      end if;
   end process;

   process(nRst, clk)
   begin
      if(nRst = '0') then
         serialin_d <= '0';
         flag       <= '0';
      elsif rising_edge(clk) then
         serialin_d <= serialin;
         if state = IDLE then
            if(serialin_d = '1')and(serialin = '0') then
               flag <= '1';
            end if;
         elsif state = START then
            flag <= '0';
         end if;
      end if;
   end process;

   process(nRst, pclk)
   begin
      if(nRst = '0') then
         state   <= IDLE;
         pcnt    <= (others => '0');
         bit_cnt <= (others => '0');
         xmtdata <= (others => '0');
         rx_data <= (others => '0');
      elsif rising_edge(pclk) then
         case state is
            when IDLE =>
               if(flag = '1') then
                  state <= START;
               else
                  state <= IDLE;
               end if;
               pcnt    <= (others => '0');
               bit_cnt <= (others => '0');
               xmtdata <= (others => '0');
               rx_data <= (others => '0');
            when START =>
               if(pcnt = 3) then
                  pcnt  <= (others => '0');
                  state <= RECEIVE;
               else
                  pcnt  <= pcnt + 1;
                  state <= START;
               end if;
            when RECEIVE =>
               if(pcnt = 7) then
                  pcnt    <= (others => '0');
                  xmtdata <= serialin & xmtdata(7 downto 1);
                  if(bit_cnt = 7) then
                     bit_cnt <= (others => '0');
                     state   <= PARITY;
                  else
                     bit_cnt <= bit_cnt + 1;
                     state   <= RECEIVE;
                  end if;
               else
                  pcnt <= pcnt + 1;
               end if;
            when PARITY =>
               if(pcnt = 7) then
                  pcnt  <= (others => '0');
                  state <= STOP;
               else
                  pcnt  <= pcnt + 1;
                  state <= PARITY;
               end if;
            when STOP =>
               if(pcnt = 7) then
                  pcnt  <= (others => '0');
                  state <= IDLE;
               else
                  pcnt  <= pcnt + 1;
                  state <= STOP;
               end if;
               rx_data <= xmtdata;
            when others =>
               state <= IDLE;
         end case;
      end if;
   end process;

   valid <= '1' when (state = STOP and pcnt = 7) else '0';

end BEH;