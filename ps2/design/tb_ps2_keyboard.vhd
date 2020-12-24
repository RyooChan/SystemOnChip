library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;
  
entity tb_ps2_keyboard is end;

architecture BEH of tb_ps2_keyboard is
  component ps2_keyboard is
  port(
    nRst      : in std_logic;
    clk       : in std_logic;
    start_sig : in std_logic;
    data      : in std_logic_vector(7 downto 0);
    ps2_clk   : out std_logic;
    ps2_data  : out std_logic
  ); 
  end component;
  
  signal nRst       : std_logic;
  signal clk        : std_logic;
  signal start_sig  : std_logic;
  signal data       : std_logic_vector(7 downto 0);
  signal ps2_clk    : std_logic;
  signal ps2_data   : std_logic;
  
begin
  
  process
  begin
    if (NOW = 0 ns) then
      nRst <= '0', '1' after 200 ns;
    end if;
    wait for 1 sec;
  end process;
  
  process
  begin 
    clk <= '0', '1' after 5 ns;
    wait for 10 ns;
  end process;
  
  process 
  begin
    data <= "00000000", "00100011" after 20000 ns, "00000000" after 60000 ns;
    wait for 1 sec;
  end process;
  
  process
    begin
      start_sig <= '0', '1' after 22000 ns, '0' after 22450 ns;
      wait for 1 sec;
  end process;
  
  
  U_ps2_keyboard : ps2_keyboard
  port map (
    nRst      => nRst,
    clk       => clk,
    start_sig => start_sig,
    data      => data,
    ps2_clk   => ps2_clk,
    ps2_data  => ps2_data
  );
  
    
end BEH;   