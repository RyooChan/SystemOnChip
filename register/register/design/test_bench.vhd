
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_arith.all;
   use ieee.std_logic_unsigned.all;

entity test_bench is end;

architecture BEH of test_bench is

   component data_parsing is
      port(

         nRst          : in std_logic;
         clk           : in std_logic;
         in_data       : in std_logic_vector  (7 downto 0);
         valid         : in std_logic;
         write_s       : out std_logic;
         read_s        : out std_logic;
         address       : out std_logic_vector (7 downto 0);
         data          : out std_logic_vector (7 downto 0)
      );
    end component;
      
    component register_map is
      port(
         nRst          : in std_logic;
         clk           : in std_logic;
    
         uart_write    : in std_logic;
         uart_read     : in std_logic;
         uart_address  : in std_logic_vector  (7 downto 0);
         uart_data     : in std_logic_vector  (7 downto 0);
    
         trans_write   : out std_logic;
         trans_read    : out std_logic;
         trans_address : out std_logic_vector (7 downto 0);
         trans_data    : out std_logic_vector (7 downto 0);
     
         reg0          : out std_logic_vector (7 downto 0); -- led r0~r7
         reg1          : out std_logic_vector (7 downto 0); -- led r8~r15
         reg2          : out std_logic_vector (7 downto 0); -- led g0~g7
      
         reg3          : in std_logic_vector  (7 downto 0); -- led sw0~sw7
         reg4          : in std_logic_vector  (7 downto 0)  -- led sw8~sw15
      );
    end component;
        
      component load_tx_data is
      port(
         nRst          : in std_logic;
         clk           : in std_logic;
         write         : in std_logic;
         read          : in std_logic;
         address       : in std_logic_vector  (7 downto 0);
         data          : in std_logic_vector  (7 downto 0);
         busy          : in std_logic;
         start_sig     : out std_logic;
         tx_data       : out std_logic_vector (7 downto 0)
      );
    end component;
    
     component uart_tx is
     port(
      nRst             : in std_logic;
      clk              : in std_logic;
      start_sig        : in std_logic;
      data             : in std_logic_vector(7 downto 0);
      tx               : out std_logic;
      busy             : out std_logic
   );
  end component;

    signal nRst           : std_logic;
    signal clk            : std_logic;
    signal in_data        : std_logic_vector(7 downto 0);
    signal write_s        : std_logic;
    signal read_s         : std_logic;
    signal address        : std_logic_vector(7 downto 0);
    signal data           : std_logic_vector(7 downto 0);
    signal valid          : std_logic;
-----------------------------------------------------------------
    signal uart_write     : std_logic;
    signal uart_read      : std_logic;
    signal uart_address   : std_logic_vector(7 downto 0);
    signal uart_data      : std_logic_vector(7 downto 0);
    signal trans_write    : std_logic;
    
    signal trans_read     : std_logic;
    signal trans_address  : std_logic_vector(7 downto 0);
    signal trans_data     : std_logic_vector(7 downto 0);
    
    signal reg0           : std_logic_vector(7 downto 0);
    signal reg1           : std_logic_vector(7 downto 0);
    signal reg2           : std_logic_vector(7 downto 0);
    signal reg3           : std_logic_vector(7 downto 0);
    signal reg4           : std_logic_vector(7 downto 0);
-----------------------------------------------------------------
    signal write          : std_logic;
    signal read           : std_logic;
    --signal address        : std_logic_vector(7 downto 0);
    --signal data           : std_logic_vector(7 downto 0); 
    signal busy           : std_logic;
    signal start_sig      : std_logic;
    signal tx_data        : std_logic_vector(7 downto 0);   
-----------------------------------------------------------------    
   
    signal tx             : std_logic;
      
    signal int_cnt        : std_logic_vector(99 downto 0);
    

begin



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
         int_cnt      <= (others => '0');
      elsif rising_edge(clk) then
         int_cnt      <= int_cnt + 1;
      end if;
   end process;

   valid     <= '1'   when int_cnt = 1250 else
                '1'   when int_cnt = 2250 else
                '1'   when int_cnt = 3250 else
                '1'   when int_cnt = 4250 else
                '1'   when int_cnt = 5250 else
                '1'   when int_cnt = 6250 else
                '1'   when int_cnt = 7250 else
                '1'   when int_cnt = 8250 else
                '1'   when int_cnt = 9250 else
                '1'   when int_cnt = 10250 else
                '1'   when int_cnt = 11250 else
                '1'   when int_cnt = 12250 else
                
                '1'   when int_cnt = 15250 else
                '1'   when int_cnt = 16250 else
                '1'   when int_cnt = 17250 else
                '1'   when int_cnt = 18250 else
                '1'   when int_cnt = 19250 else
                '1'   when int_cnt = 20250 else
                '1'   when int_cnt = 21250 else
                
                '0';
                
   in_data   <= x"77" when int_cnt > 1000 and int_cnt < 1500 else
                x"20" when int_cnt > 2000 and int_cnt < 2500 else
                x"30" when int_cnt > 3000 and int_cnt < 3500 else
                x"78" when int_cnt > 4000 and int_cnt < 4500 else
                x"30" when int_cnt > 5000 and int_cnt < 5500 else
                x"31" when int_cnt > 6000 and int_cnt < 6500 else
                x"20" when int_cnt > 7000 and int_cnt < 7500 else
                x"30" when int_cnt > 8000 and int_cnt < 8500 else
                x"78" when int_cnt > 9000 and int_cnt < 9500 else
                x"30" when int_cnt >10000 and int_cnt <10500 else
                x"34" when int_cnt >11000 and int_cnt <11500 else
                x"0D" when int_cnt >12000 and int_cnt <12500 else
                
                x"72" when int_cnt >15000 and int_cnt <15500 else
                x"20" when int_cnt >16000 and int_cnt <16500 else
                x"30" when int_cnt >17000 and int_cnt <17500 else
                x"78" when int_cnt >18000 and int_cnt <18500 else
                x"31" when int_cnt >19000 and int_cnt <19500 else
                x"32" when int_cnt >20000 and int_cnt <20500 else
                x"0D" when int_cnt >21000 and int_cnt <21500 else
                
                x"00";
                
                
                
                
   U_data_parsing : data_parsing
   port map(
      nRst              => nRst,
      clk               => clk,
      in_data           => in_data,
      valid             => valid,
      write_s           => uart_write,
      read_s            => uart_read,
      address           => uart_address,
      data              => uart_data
   );
   
   U_register_map  : register_map
   port map(     
      nRst             => nRst,
      clk              => clk,
    
      uart_write       => uart_write,
      uart_read        => uart_read,
      uart_address     => uart_address,
      uart_data        => uart_data,
 
      trans_write      => trans_write,
      trans_read       => trans_read,
      trans_address    => trans_address,
      trans_data       => trans_data,
   
      reg0             => reg0,
      reg1             => reg1,
      reg2             => reg2,
   
      reg3             => reg3,
      reg4             => reg4
    );
       
     U_load_tx_data    : load_tx_data
     port map(
        
      nRst             => nRst,
      clk              => clk,
      write            => trans_write,   
      read             => trans_read,
      address          => trans_address,      
      data             => trans_data,   
      busy             => busy,
      start_sig        => start_sig,
      tx_data          => tx_data   
    );
    
     U_uart_tx        : uart_tx
     port map (
      nRst             => nRst,
      clk              => clk,
      start_sig        => start_sig,
      data             => tx_data,
      tx               => tx,
      busy             => busy
   );   
   
end BEH;


