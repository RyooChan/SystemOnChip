
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity register_map is
  port(
    nRst          : in std_logic;
    clk           : in std_logic;
    
    uart_write    : in std_logic;
    uart_read     : in std_logic;
    uart_address  : in std_logic_vector (7 downto 0);
    uart_data     : in std_logic_vector (7 downto 0);
    
    trans_write   : out std_logic;
    trans_read    : out std_logic;
    trans_address : out std_logic_vector (7 downto 0);
    trans_data    : out std_logic_vector (7 downto 0);
    
    reg0          : out std_logic_vector (7 downto 0); -- led r0~r7
    reg1          : out std_logic_vector (7 downto 0); -- led r8~r15
    reg2          : out std_logic_vector (7 downto 0); -- led g0~g7
      
    reg3          : in std_logic_vector (7 downto 0); -- led sw0~sw7
    reg4          : in std_logic_vector (7 downto 0)  -- led sw8~sw15
  );
end register_map;

architecture beh of register_map is
  
  type state_type is (IDLE, WRN_START, WRN_DEC, WRN_END, WRN_STOP, RDN_START, RDN_DEC, RDN_END, RDN_STOP);
  signal state : state_type;
  
  type mem_tbl is array(0 to 15) of std_logic_vector (7 downto 0);
  signal reg_tbl : mem_tbl;
  
  signal temp_wr_add    : std_logic_vector (7 downto 0);
  signal temp_rd_add    : std_logic_vector (7 downto 0);
  signal temp_address   : std_logic_vector (7 downto 0);
  signal temp_data      : std_logic_vector (7 downto 0);
  signal temp_mdi       : std_logic_vector (7 downto 0);
  signal temp_mdo       : std_logic_vector (7 downto 0);
  
  signal write_d    : std_logic;
  signal write_det  : std_logic;
  signal read_d     : std_logic;
  signal read_det   : std_logic;
    
begin

  process(nRst, clk)
  begin
    if (nRst = '0') then
      write_d      <= '0';
      write_det    <= '0';
      read_d       <= '0';
      read_det     <= '0';
      temp_wr_add  <= (others => '0');
      temp_rd_add  <= (others => '0');
      temp_mdi     <= (others => '0');
    elsif rising_edge(clk) then
      write_d <= uart_write;
      read_d  <= uart_read;
      if (write_d = '0') and (uart_write = '1') then
        write_det   <= '1';
        temp_wr_add <= uart_address;
        temp_mdi    <= uart_data;
      elsif (state = WRN_START) then
        temp_wr_add <= (others => '0');
        temp_mdi    <= (others => '0');
      else 
        write_det <= '0';
      end if;
      if (read_d = '0') and (uart_read = '1') then
        read_det    <= '1';
        temp_rd_add <= uart_address;
      elsif (state = RDN_START) then
        temp_rd_add <= (others => '0');
      else
        read_det <= '0';
      end if;
    end if;
  end process;
  
  process (nRst, clk)
    variable I_ADDR : natural;
  begin
    if (nRst = '0') then
      state         <= IDLE;
      temp_address  <= (others => '0');
      temp_data     <= (others => '0');
      I_ADDR        := 0;
      trans_address <= (others => '0');
      trans_data    <= (others => '0');
      trans_write   <= '0';
      trans_read    <= '0';
    elsif rising_edge(clk) then
      case state is
        when IDLE =>
          if (write_det = '1') then
            state <= WRN_START;
          elsif (read_det = '1') then
            state <= RDN_START;
          else
            state <= IDLE;
          end if;
          temp_address  <= (others => '0');
          temp_data     <= (others => '0');
          I_ADDR        := 0;
          trans_address <= (others => '0');
          trans_data    <= (others => '0');
          trans_write   <= '0';
          trans_read    <= '0';
        when WRN_START =>
          temp_address  <= temp_wr_add;
          temp_data     <= temp_mdi;
          I_ADDR        := conv_integer(temp_wr_add);
          state         <= WRN_DEC;
        when WRN_DEC =>
          state           <= WRN_END;
          reg_tbl(I_ADDR) <= temp_data;
          trans_address   <= temp_address;
          trans_data      <= temp_data;
        when WRN_END =>
          trans_write <= '1';
          state       <= WRN_STOP;
        when WRN_STOP =>
          trans_write <= '0';
          state       <= IDLE;
        when RDN_START =>
          temp_address  <= temp_rd_add;
          I_ADDR        := conv_integer(temp_rd_add);
          temp_data     <= reg_tbl(I_ADDR);
          state         <= RDN_DEC;
        when RDN_DEC =>
          state          <= RDN_END;
          trans_address  <= temp_address;
          trans_data     <= temp_data;
        when RDN_END =>
          trans_read  <= '1';
          state       <= RDN_STOP;
        when RDN_STOP =>
          trans_read  <= '0';
          state       <= IDLE;
        when others =>
          state <= IDLE;
      end case;
      reg0        <= reg_tbl(0);
      reg1        <= reg_tbl(1);
      reg2        <= reg_tbl(2);
      reg_tbl(3)  <= reg3;
      reg_tbl(4)  <= reg4;
    end if;
  end process;
  
end beh;
