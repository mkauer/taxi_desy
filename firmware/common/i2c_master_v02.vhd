--
-- VHDL Architecture rada_comp_lib.i2c_master_v01.arc
--
-- Created:
--          by - elis@(ELIS-WXP)
--          at - 15:30:47 01/03/2009
--
-- using Mentor Graphics HDL Designer(TM) 2008.1 (Build 17)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY i2c_master_v02 IS
   GENERIC( 
      CLK_FREQ : natural; -- := 25000000;
      BAUD     : natural -- := 100000
   );
   PORT( 
      --INPUTS
      sys_clk    : IN     std_logic;
      sys_rst    : IN     std_logic;
      start      : IN     std_logic;
      stop       : IN     std_logic;
      read       : IN     std_logic;
      write      : IN     std_logic;
      send_ack   : IN     std_logic;
      mstr_din   : IN     std_logic_vector (7 DOWNTO 0);
      --OUTPUTS
      --sda        : INOUT  std_logic;
      --scl        : INOUT  std_logic;
      free       : OUT    std_logic;
      rec_ack    : OUT    std_logic;
      ready      : OUT    std_logic;
      core_state : OUT    std_logic_vector (5 DOWNTO 0);  --for debug purpose
      mstr_dout  : OUT    std_logic_vector (7 DOWNTO 0);
		
		sda_in		: in    std_logic;
		sda_out		: out   std_logic;
		scl_out		: out   std_logic;
		sda_tri		: out   std_logic
   );

-- Declarations

END i2c_master_v02;

--
ARCHITECTURE arc OF i2c_master_v02 IS
  
  constant FRAME     : natural := 11; -- number of bits in frame: start, stop, 8 bits data, 1 bit acknoledge
 -- constant BAUD      : natural := 100000;
  constant FULL_BIT  : natural := ( CLK_FREQ / BAUD - 1 ) / 2;
  constant HALF_BIT  : natural := FULL_BIT / 2;
  constant GAP_WIDTH : natural := FULL_BIT * 4;  

  signal i_free     : std_logic;
  signal i_ready    : std_logic;
  signal i_sda_tristate : std_logic;
  signal i_sda_mstr : std_logic;
  signal i_scl_mstr : std_logic;
  signal i_scl_cntr : natural range 0 to GAP_WIDTH;
  signal i_bit_cntr_mstr : natural range 0 to 7;
  signal i_ack_mstr : std_logic;
  signal i_s_rd_data : std_logic_vector( 7 downto 0 );
  
  signal i_s_ad  : std_logic_vector( 7 downto 0 ); --latched address and data
  alias  fld_rd_wr  : std_logic is i_s_ad( 0 ); --1 - read, 0 - write

  type i2c_master_state is ( s_idle, s_start_cnt , s_active , s_wait_first_half , s_wait_second_half ,
                             s_wait_full , s_wait_ack , s_wait_ack_second_half , s_wait_ack_third_half ,
                             s_wait_ack_fourth_half , s_rd_wait_low , s_rd_wait_half , s_rd_read , s_stop ,
                             s_rd_wait_ack_bit , s_rd_wait_ack , s_rd_get_ack , s_restart , s_gap , s_stop_1 ,
                             s_rd_wait_last_half , s_restart_clk_high );
                             
  signal state : i2c_master_state;
  
  signal i_in_state : natural;
    
BEGIN
--	sda_out <= '1' when i_sda_mstr = '1' else
--			   '0' when i_sda_mstr = '0';
--
--in_out <= '1' when i_sda_mstr = '1' else
--		  '1' when i_sda_mstr = '0' else
--			'0' when i_sda_mstr = 'Z';
	
	sda_out <= i_sda_mstr;
	sda_tri <= i_sda_tristate;

  scl_out <= i_scl_mstr;
  free <= i_free;
  ready <= i_ready;
  rec_ack <= not i_ack_mstr;
  
  core_state <= conv_std_logic_vector( i_in_state , 6 );
  
  i2c_master: 
  process( sys_clk , sys_rst )
    begin
      if ( sys_rst = '1' ) then
        state <= s_idle;
        i_free     <= '0';
        i_ready    <= '0';  
        i_sda_mstr <= '0'; i_sda_tristate <= '1'; -- i_sda_mstr <= 'Z';
        i_scl_mstr <= 'Z';
        i_scl_cntr <= 0;
        i_bit_cntr_mstr <= 7;
        i_ack_mstr <= '1';
        i_s_rd_data <= ( others => '0' ); 
        mstr_dout  <= ( others => '0' ); 
        i_s_ad  <= ( others => '0' );   
        i_in_state <= 0;   
      elsif rising_edge( sys_clk ) then      
          case state is
          -------------------  
          when s_idle =>
            i_free <= '1';
            i_ready <= '0';
        	i_sda_mstr <= '0'; i_sda_tristate <= '1'; -- i_sda_mstr <= 'Z';
            i_scl_mstr <= 'Z';                                      
            if ( start = '1' ) then
              state <= s_start_cnt;
              i_free <= '0';          
            else
              state <= s_idle;
            end if;
          -------------------
          when s_start_cnt =>
            i_sda_mstr <= '0'; i_sda_tristate <= '0'; -- i_sda_mstr <= '0';
            i_scl_mstr <= '1';
            if ( i_scl_cntr < HALF_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
              state <= s_start_cnt;
            else  
              i_scl_cntr <= 0;
              state <= s_active;
              i_scl_mstr <= '0';
            end if;
          -------------------
          when s_active =>
            i_ready <= '1';   
            i_scl_mstr <= '0';
            i_sda_mstr <= '0';  i_sda_tristate <= '0'; -- i_sda_mstr <= '0';
            i_bit_cntr_mstr <= 7;
            i_in_state <= 1;
            if ( read = '1' ) then 
              i_ack_mstr <= '1'; -- marko
              state <= s_rd_wait_low;
              i_ready <= '0';
              i_in_state <= 3;
            elsif ( write = '1' ) then
              i_ack_mstr <= '1'; -- marko
              i_in_state <= 2;
              i_s_ad <= mstr_din;
              i_ready <= '0';
              state <= s_wait_first_half; 
            elsif ( stop = '1' ) then
              i_ack_mstr <= '1'; -- marko
              i_in_state <= 4;
              i_ready <= '0';
              state <= s_stop_1;
            elsif ( start = '1' ) then
              i_ack_mstr <= '1'; -- marko
              i_in_state <= 5;
              i_ready <= '0';
              state <= s_restart;
            end if;
          --------------------
          --####################
          --##### WRITE ########
          --####################
          when s_wait_first_half =>
            if ( i_scl_cntr < HALF_BIT ) then
              i_scl_mstr <= '0';
              i_scl_cntr <= i_scl_cntr + 1;
            else
              i_scl_cntr <= 0;
              state <= s_wait_second_half;
              i_sda_mstr <= i_s_ad( i_bit_cntr_mstr ); i_sda_tristate <= '0'; -- i_sda_mstr <= xxxx;
            end if;
          --------------------
          when s_wait_second_half =>
            if ( i_scl_cntr < HALF_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
              state <= s_wait_second_half;
            else            
              i_scl_cntr <= 0;              
              state <= s_wait_full;              
            end if;
          ---------------------
          when s_wait_full =>
            if ( i_scl_cntr < FULL_BIT ) then 
              i_scl_mstr <= '1';
              i_scl_cntr <= i_scl_cntr + 1;
              state <= s_wait_full;
            else  
              i_scl_cntr <= 0;              
              if ( i_bit_cntr_mstr >= 1 ) then
                i_bit_cntr_mstr <= i_bit_cntr_mstr - 1;
                state <= s_wait_first_half;
              elsif ( i_bit_cntr_mstr = 0 ) then
                --i_sda_mstr <= 'Z';
              	i_sda_mstr <= '0'; i_sda_tristate <= '1'; -- i_sda_mstr <= 'Z';
                state <= s_wait_ack;                
              end if;                                          
            end if;
          --------------------
          --####################
          --#### ACKNOWLEDGE ###
          --####################
          when s_wait_ack =>
            i_scl_mstr <= '0';
            if ( i_scl_cntr < HALF_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
            else
              i_scl_cntr <= 0;
              i_sda_mstr <= '0'; i_sda_tristate <= '1'; -- i_sda_mstr <= 'Z';
              state <= s_wait_ack_second_half;
            end if;
          --------------------
          when s_wait_ack_second_half => 
            if ( i_scl_cntr < HALF_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
            else
              i_scl_cntr <= 0;
        	  i_sda_mstr <= '0'; i_sda_tristate <= '1'; -- i_sda_mstr <= 'Z';
              state <= s_wait_ack_third_half;
            end if;               
          --------------------  
          when s_wait_ack_third_half =>
            i_scl_mstr <= '1';
            if ( i_scl_cntr < HALF_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
            else
              i_scl_cntr <= 0;
        	  i_sda_mstr <= '0'; i_sda_tristate <= '1'; -- i_sda_mstr <= 'Z';
              i_ack_mstr <= to_x01( sda_in );
              state <= s_wait_ack_fourth_half;
            end if;        
          --------------------
          when s_wait_ack_fourth_half =>
            if ( i_scl_cntr < HALF_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
            else
              i_scl_cntr <= 0;
        	  i_sda_mstr <= '0'; i_sda_tristate <= '1'; -- i_sda_mstr <= 'Z';
              state <= s_active;
            end if;     
          --------------------
          --####################
          --###### READ ########
          --####################
          when s_rd_wait_low =>
            i_scl_mstr <= '0';
        	i_sda_mstr <= '0'; i_sda_tristate <= '1'; -- i_sda_mstr <= 'Z';
            if ( i_scl_cntr < FULL_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
              state <= s_rd_wait_low;
            else                           
              i_scl_cntr <= 0;
              state <= s_rd_wait_half;  
            end if;
          --------------------
          when s_rd_wait_half =>
            i_scl_mstr <= '1';
            if ( i_scl_cntr < HALF_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
              state <= s_rd_wait_half;
            else                           
              i_scl_cntr <= 0;
              i_s_rd_data <= i_s_rd_data( 6 downto 0 ) & to_x01( sda_in );
              state <= s_rd_read;               
            end if;  
          --------------------- 
          when s_rd_read =>
            i_scl_mstr <= '1';
            if ( i_scl_cntr < HALF_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
              state <= s_rd_read;
            else                           
              i_scl_cntr <= 0;               
              if ( i_bit_cntr_mstr > 0 ) then
                i_bit_cntr_mstr <= i_bit_cntr_mstr - 1;
                i_scl_mstr <= '0';              
                state <= s_rd_wait_low;  
              else
                i_s_ad <= ( others => '0' );  
                mstr_dout <= i_s_rd_data;               
                state <= s_rd_wait_ack;
              end if;
            end if;      
          ---------------------
          --#######################
          --### SEND ACKNOWELEDGE #
          --#######################
          when s_rd_wait_ack =>
            i_scl_mstr <= '0';
            if ( i_scl_cntr < HALF_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
              state <= s_rd_wait_ack;
            else                           
              i_scl_cntr <= 0;
              i_sda_mstr <= not send_ack; i_sda_tristate <= '0'; -- i_sda_mstr <= xxxx;
              state <= s_rd_get_ack;
            end if;
          ----------------------              
          when s_rd_get_ack =>
            i_scl_mstr <= '0';
            if ( i_scl_cntr < HALF_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
              state <= s_rd_get_ack;
            else
              i_scl_cntr <= 0;
              --i_ack_mstr <= sda;
              state <= s_rd_wait_ack_bit;
            end if;
          ----------------------
          when s_rd_wait_ack_bit =>
            i_scl_mstr <= '1';
            if ( i_scl_cntr < FULL_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
              state <= s_rd_wait_ack_bit;
            else              
              i_scl_cntr <= 0;
              state <= s_rd_wait_last_half;
            end if;
          ---------------------- 
          when s_rd_wait_last_half =>
            i_scl_mstr <= '0';            
            if ( i_scl_cntr < HALF_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
              state <= s_rd_wait_last_half;
            else
              i_scl_cntr <= 0;
        	  i_sda_mstr <= '0'; i_sda_tristate <= '1'; -- i_sda_mstr <= 'Z';
              state <= s_active;
            end if;
          --######################
          --######## STOP ########
          --###################### 
          when s_stop_1 =>
            i_scl_mstr <= '0';
            i_sda_mstr <= '0'; i_sda_tristate <= '0'; -- i_sda_mstr <= '0';
            if ( i_scl_cntr < HALF_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
              state <= s_stop_1;
            else
              i_scl_cntr <= 0;
              state <= s_stop;
            end if;
          ----------------------                                     
          when s_stop =>
            i_scl_mstr <= '1';
            i_sda_mstr <= '0'; i_sda_tristate <= '0'; -- i_sda_mstr <= '0';
            if ( i_scl_cntr < HALF_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
              state <= s_stop;
            else
              i_scl_cntr <= 0;
              i_sda_mstr <= '1'; i_sda_tristate <= '0'; -- i_sda_mstr <= '1';
              state <= s_gap;
            end if;                                                  
          ---------------------  
          when s_gap =>
            if ( i_scl_cntr < GAP_WIDTH ) then
              i_scl_cntr <= i_scl_cntr + 1;
              state <= s_gap;
            else
              i_scl_cntr <= 0;
              i_in_state <= 0;
              state <= s_idle;
            end if;
          --#####################
          --###### RESTART ######        
          --#####################
          when s_restart =>
            i_scl_mstr <= '0';
            i_sda_mstr <= '1'; i_sda_tristate <= '0'; -- i_sda_mstr <= '1';
            i_ready <= '0';
            if ( i_scl_cntr < FULL_BIT ) then
              i_scl_cntr <= i_scl_cntr + 1;
              state <= s_restart;
            else
              i_scl_cntr <= 0;
              i_sda_mstr <= '1'; i_sda_tristate <= '0'; -- i_sda_mstr <= '1';
              state <= s_restart_clk_high;
            end if;                      
          ----------------------
          when s_restart_clk_high =>
            i_scl_mstr <= '1';
            i_sda_mstr <= '1'; i_sda_tristate <= '0'; -- i_sda_mstr <= '1';
            i_ready <= '0';
            if ( i_scl_cntr < HALF_BIT ) then
              state <= s_restart_clk_high;
              i_scl_cntr <= i_scl_cntr + 1;
            else
              i_scl_cntr <= 0;
              state <= s_start_cnt;
            end if;                              
          when others => state <= s_idle;
          end case;       
      end if;
    end process i2c_master;
END ARCHITECTURE arc;
