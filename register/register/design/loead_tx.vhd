library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity load_tx_data is
  port(
    nRst      : in std_logic;
    clk       : in std_logic;
    write     : in std_logic;
    read      : in std_logic;
    address   : in std_logic_vector (7 downto 0);
    data      : in std_logic_vector (7 downto 0);
    busy      : in std_logic;
    start_sig : out std_logic;
    tx_data   : out std_logic_vector (7 downto 0)
  );
end load_tx_data;

architecture beh of load_tx_data is
  
  function data_decode(in_data : std_logic_vector (3 downto 0)) return
                                 std_logic_vector is 
                                 variable return_data : std_logic_vector (7 downto 0);                               
    begin
      case in_data is
        when "0000" => return_data := "00110000"; -- 0   0x30
        when "0001" => return_data := "00110001"; -- 1   0x31
        when "0010" => return_data := "00110010"; -- 2   0x32
        when "0011" => return_data := "00110011"; -- 3   0x33
        when "0100" => return_data := "00110100"; -- 4   0x34
        when "0101" => return_data := "00110101"; -- 5   0x35
        when "0110" => return_data := "00110110"; -- 6   0x36
        when "0111" => return_data := "00110111"; -- 7   0x37
        when "1000" => return_data := "00111000"; -- 8   0x38
        when "1001" => return_data := "00111001"; -- 9   0x39
        when "1010" => return_data := "01000001"; -- A   0x41
        when "1011" => return_data := "01000010"; -- B   0x42
        when "1100" => return_data := "01000011"; -- C   0x43
        when "1101" => return_data := "01000100"; -- D   0x44
        when "1110" => return_data := "01000101"; -- E   0x45
        when "1111" => return_data := "01000110"; -- F   0x46
        when others     => return_data := "00111111"; -- ?
      end case;
    return(return_data);
  end data_decode;
  
  type state_type is (IDLE, WRN_LOAD, WRN_SEND, WRN_WAIT, RDN_LOAD, RDN_SEND, RDN_WAIT);
  type mem_tbl is array(0 to 26) of std_logic_vector (7 downto 0);
  signal state        : state_type;
  signal reg_tbl      : mem_tbl;
  signal write_d      : std_logic;
  signal write_det    : std_logic;
  signal read_d       : std_logic;
  signal read_det     : std_logic;
  signal busy_d       : std_logic;
  signal busy_det     : std_logic;
  signal data_cnt     : std_logic_vector (7 downto 0);
  signal temp_address : std_logic_vector (7 downto 0);
  signal temp_data    : std_logic_vector (7 downto 0);
  signal cnt          : std_logic_vector (25 downto 0);
  
  signal data_sp  : std_logic_vector (7 downto 0) := x"20";                                  
  signal data_a   : std_logic_vector (7 downto 0) := x"41";
  signal data_d   : std_logic_vector (7 downto 0) := x"44";
  signal data_0   : std_logic_vector (7 downto 0) := x"30";
  signal data_x   : std_logic_vector (7 downto 0) := x"78";
  signal data_m   : std_logic_vector (7 downto 0) := x"4D";
  signal data_g   : std_logic_vector (7 downto 0) := x"47";

  signal data_w   : std_logic_vector (7 downto 0) := x"57";
  signal data_r   : std_logic_vector (7 downto 0) := x"52";
  signal data_i   : std_logic_vector (7 downto 0) := x"49";
  signal data_t   : std_logic_vector (7 downto 0) := x"54";
  signal data_e   : std_logic_vector (7 downto 0) := x"45";
  
  signal data_cr  : std_logic_vector (7 downto 0) := x"0D";
  signal data_lf  : std_logic_vector (7 downto 0) := x"0A";
  signal data_ff  : std_logic_vector (7 downto 0) := x"0C";
  signal data_nl  : std_logic_vector (7 downto 0) := x"00";
  signal data_ds  : std_logic_vector (7 downto 0) := x"2D";
  signal data_cm  : std_logic_vector (7 downto 0) := x"2C";
  
begin

  process (nRst, clk)
  begin
    if (nRst = '0') then
      write_d      <= '0';
      write_det    <= '0';
      read_d       <= '0';
      read_det     <= '0';
      busy_d       <= '0';
      busy_det     <= '0';
      temp_address <= (others => '0');
      temp_data    <= (others => '0');
    elsif rising_edge(clk) then
      write_d <= write;
      read_d  <= read;
      busy_d  <= busy;
      if (write_d = '0') and (write = '1') then
        write_det     <= '1';
        temp_address  <= address;
        temp_data     <= data;
      else
        write_det <= '0';
      end if;
      if (read_d = '0') and (read = '1') then
        read_det      <= '1';
        temp_address  <= address;
        temp_data     <= data;
      else
        read_det <= '0';
      end if;
      if (busy_d = '0') and (busy = '1') then
        busy_det <= '1';
      else
        busy_det <= '0';
      end if;
    end if;
  end process;
  
  process(nRst, clk)
    variable ADDR : natural;
  begin
    if(nRst ='0') then 
    state <= IDLE;
    data_cnt      <=(others => '0');
    reg_tbl(0)    <= data_nl;
    reg_tbl(1)    <=(others => '0');
    reg_tbl(2)    <=(others => '0');
    reg_tbl(3)    <=(others => '0');
    reg_tbl(4)    <=(others => '0');
    reg_tbl(5)    <=(others => '0');
    reg_tbl(6)    <=data_sp;
    reg_tbl(7)    <=data_a;
    reg_tbl(8)    <=data_d;
    reg_tbl(9)    <=data_d;
    reg_tbl(10)   <=data_sp;
    reg_tbl(11)   <=data_0;
    reg_tbl(12)   <=data_x;
    reg_tbl(13)   <=(others => '0'); --address msb
    reg_tbl(14)   <=(others => '0'); --address lsb
    reg_tbl(15)   <=data_sp;
    reg_tbl(16)   <=data_d;
    reg_tbl(17)   <=data_a;
    reg_tbl(18)   <=data_t;
    reg_tbl(19)   <=data_a;
    reg_tbl(20)   <=data_sp;
    reg_tbl(21)   <=data_0;
    reg_tbl(22)   <=data_x;
    reg_tbl(23)   <=(others => '0'); --data msb
    reg_tbl(24)   <=(others => '0'); --data lsb
    reg_tbl(25)   <=data_lf;
    reg_tbl(26)   <=data_cr;
    tx_data       <=(others => '0');
    start_sig     <= '0';
  elsif rising_edge(clk) then
    case state is
      when IDLE =>
        if(write_det = '1') then
          state         <= WRN_LOAD;
        elsif(read_det = '1') then
          state         <= RDN_LOAD;
        else
          state <= IDLE;
        end if;
        data_cnt    <= (others => '0');
        tx_data     <= (others => '0');
        start_sig   <= '0';
        cnt         <= (others => '0');
      when WRN_LOAD =>
        state      <= WRN_SEND;
        reg_tbl(1)  <= data_w;
        reg_tbl(2)  <= data_r;
        reg_tbl(3)  <= data_i;
        reg_tbl(4)  <= data_t;
        reg_tbl(5)  <= data_e;
        reg_tbl(13) <= data_decode(temp_address(7 downto 4)); --address msb
        reg_tbl(14) <= data_decode(temp_address(3 downto 0)); --address lsb
        reg_tbl(23) <= data_decode(temp_data(7 downto 4)); --data msb
        reg_tbl(24) <= data_decode(temp_data(3 downto 0)); --data lsb
      when WRN_SEND =>
        state      <= WRN_WAIT;
        ADDR       := conv_integer(data_cnt);
        tx_data    <=reg_tbl(ADDR);
        start_sig  <= '1';
      when WRN_WAIT =>
        if(busy_det = '1') then
           if(data_cnt = 26) then
              data_cnt  <= (others => '0');
              state     <= IDLE;
            else
              state     <=WRN_SEND;
              data_cnt  <= data_cnt +1;
            end if;
          else
            state       <=WRN_WAIT;
          end if;
          start_sig <='0';
        when RDN_LOAD =>
        state      <= WRN_SEND;
        reg_tbl(1)  <= data_r;
        reg_tbl(2)  <= data_e;
        reg_tbl(3)  <= data_a;
        reg_tbl(4)  <= data_d;
        reg_tbl(5)  <= data_sp;
        reg_tbl(13) <= data_decode(temp_address(7 downto 4)); --address msb
        reg_tbl(14) <= data_decode(temp_address(3 downto 0)); --address lsb
        reg_tbl(23) <= data_decode(temp_data(7 downto 4)); --data msb
        reg_tbl(24) <= data_decode(temp_data(3 downto 0)); --data lsb          
      when RDN_SEND =>
        state      <= RDN_WAIT;
        ADDR       := conv_integer(data_cnt);
        tx_data    <= reg_tbl(ADDR);
        start_sig  <= '1';
      when RDN_WAIT =>
        if(busy_det = '1') then
           if(data_cnt = 26) then
              state    <= IDLE;
              data_cnt <= (others => '0');
            else
              state    <= RDN_SEND;
              data_cnt <= data_cnt +1;
            end if;
          else
            state <= RDN_WAIT;
          end if;
          start_sig <='0';
        when others =>
          state <= IDLE;
        end case;
      end if;
    end process;
    
  end beh;
        

