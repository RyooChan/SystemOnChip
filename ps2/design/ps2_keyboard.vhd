library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;
  
entity ps2_keyboard is
  port(
    nRst      : in std_logic;
    clk       : in std_logic;
    start_sig : in std_logic;
    data      : in std_logic_vector(7 downto 0);
    ps2_clk   : out std_logic;
    ps2_data  : out std_logic
  );
end ps2_keyboard;

architecture BEH of ps2_keyboard is
  
  type state_type is (IDLE, START, SEND, PARITY, STOP);
  signal state      : state_type;
  signal cnt        : std_logic_vector (9 downto 0);
  signal pclk       : std_logic; -- 80Khz, 12.5ns
  signal pclk_cnt   : std_logic_vector (1 downto 0);
  signal bit_cnt    : std_logic_vector (2 downto 0);
  signal temp_data   : std_logic_vector (7 downto 0);
  signal tx_data    : std_logic_vector (7 downto 0);
  
  signal start_d    : std_logic;
  signal flag       : std_logic;
  
begin
  
  process (nRst, clk)
  begin
    if (nRst = '0') then
      cnt <= (others => '0');
      pclk <= '0';
    elsif rising_edge(clk) then
      if(cnt = 624) then
         cnt <= (others => '0');
         pclk <= not pclk;
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;
  
  process (nRst, clk)
  begin
    if (nRst = '0') then
      start_d   <= '0';
      flag      <= '0';
      temp_data <= (others => '0');
    elsif rising_edge(clk) then
      start_d   <= start_sig;
      if(start_d = '0') and (start_sig = '1') then
        flag       <= '1';
        temp_data  <= data;
      elsif (state = START) then
        flag <= '0';
      end if;
    end if;
  end process;
  
  process (nRst, pclk)
  begin
    if (nRst = '0') then
      state     <= IDLE;
      pclk_cnt  <= (others => '0');
      bit_cnt   <= (others => '0');
      tx_data   <= (others => '0');
    elsif rising_edge(pclk) then
      case state is
        when IDLE =>
          if (flag = '1') then
            state <= START;
          else 
            state <= IDLE;
          end if;
          pclk_cnt  <= (others => '0');
          bit_cnt   <= (others => '0');
          tx_data   <= (others => '0');
        when START =>
          if (pclk_cnt = 3)  then
            pclk_cnt <= (others => '0');
            state    <= SEND;
          else
            pclk_cnt <= pclk_cnt + 1;
            state   <= START;
          end if;
          tx_data <= temp_data;
        when SEND =>
          if (pclk_cnt = 3) then 
            pclk_cnt <= (others => '0');
            if (bit_cnt =  7) then
              bit_cnt <= (others => '0');
              state <= PARITY;
            else
              tx_data <= '0' & tx_data (7 downto 1);
              bit_cnt <= bit_cnt + 1;
              state <= SEND;
            end if;
          else
            pclk_cnt  <= pclk_cnt + 1;
            state     <= SEND;
          end if;
        when PARITY =>
          if (pclk_cnt = 3)  then
            pclk_cnt <= (others => '0');
            state    <= STOP;
          else
            pclk_cnt <= pclk_cnt + 1;
            state   <= PARITY;
          end if; 
        when STOP =>
          if (pclk_cnt = 3)  then
            pclk_cnt <= (others => '0');
            state    <= IDLE;
          else
            pclk_cnt <= pclk_cnt + 1;
            state   <= STOP;
          end if; 
        when others =>
          state <= STOP;
      end case;
    end if;
  end process;
  
  ps2_clk   <= '0' when pclk_cnt >= 1 and pclk_cnt <= 2
              else  '1';
  ps2_data  <= tx_data(0) when state = SEND else
                '0'       when state = START or state = PARITY
              else '1';
              
end BEH;                  
           