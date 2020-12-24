library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_arith.all;
   use ieee.std_logic_unsigned.all;

entity tb_uart is end;

architecture BEH of tb_uart is

   component uart_tx is
      port(
         nRst      : in std_logic;
         clk       : in std_logic;
         start_sig : in std_logic;
         data      : in std_logic_vector(7 downto 0);
         tx        : out std_logic;
         busy      : out std_logic
      );   
   end component;

   signal nRst      : std_logic;
   signal clk       : std_logic;
   signal start_sig : std_logic;
   signal data      : std_logic_vector(7 downto 0);
   signal tx        : std_logic;
   signal busy      : std_logic;

   signal int_cnt   : std_logic_vector(99 downto 0);

   component uart_rx is
      port(
         nRst     : in std_logic;
         clk      : in std_logic; -- clk
         serialin : in std_logic; -- serial data in
         rx_data  : out std_logic_vector(7 downto 0);
         valid    : out std_logic
      );
   end component;

   --signal serialin : std_logic;
   signal rx_data  : std_logic_vector(7 downto 0);
   signal valid    : std_logic;

begin

   U_uart_tx : uart_tx
   port map(
      nRst      => nRst,
      clk       => clk,
      start_sig => start_sig,
      data      => data,
      tx        => tx,
      busy      => busy
   );

   U_uart_rx : uart_rx
   port map(
      nRst     => nRst,
      clk      => clk,
      serialin => tx,
      --serialin => serialin,
      rx_data  => rx_data,
      valid    => valid
   );

   process
   begin
      if(NOW = 0 ns) then
         nRst <= '0', '1' after 200 ns;
      end if;
      wait for 1 sec;
   end process;

   process
   begin
      clk <= '0', '1' after 5 ns;
      wait for 10 ns;
   end process;

   process(nRst, clk)
   begin
      if(nRst = '0') then
         int_cnt <= (others => '0');
      elsif rising_edge(clk) then
         int_cnt <= int_cnt + 1;
      end if;
   end process;

   start_sig <= '1' when int_cnt = 1000 else
                '0';
   data      <= x"A7" when int_cnt > 900 and int_cnt < 1400 else
                x"00"; 
 
end BEH;

