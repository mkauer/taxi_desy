-----------------------------------------------------------------------------------------
-- Design Name : iserdes_in_del
-- File Name   : iserdes_in_del.vhd
-- Device      : Spartan 6
-- Function    : iserdes channel with input delay control
-- Coder       : K.-H. Sulanke, DESY, 2018-07-10
-----------------------------------------------------------------------------------------
-- UV logger, dummy 

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all ;

library unisim ;
use unisim.vcomponents.all ;

entity iserdes_in_del is  
 generic (
          S           : integer                      := 8;	 -- Parameter to set the serdes factor 1..8
          INIT_DELAY  : std_logic_vector(4 downto 0) --:= B"0_0001"
         );        -- clock period (ns) of input clock on clkin_p
  port (
        reset 		            :  in std_logic ;   -- reset (active high)
        clk                   :  in std_logic ;   -- global clock input
        del_data              :  in std_logic_vector (7 downto 0);  -- delay value, 4..0 => ps, 7..5 => ns
        del_load              :  in std_logic;   -- to initiate the DELAY cycle, single pulse, synchronous state machine reset 
        del_busy              :  out std_logic;  -- delay status
        sdat_in_p           	:  in std_logic;   -- lvds serial data inputs
        sdat_in_n	            :  in std_logic;   -- lvds serial data inputs
        iserdes_ioclk         :  in std_logic ;   -- high speed i/o clock
        iserdes_stb           :  in std_logic ;   --       
        pdat_out              :  out std_logic_vector (7 downto 0)  -- synchronized (clk) iserdes par. data output
        );
  end iserdes_in_del ;

architecture arch_iserdes_in_del of iserdes_in_del is

-- iodelay
  signal init           : std_logic;
	signal sdat_in        : std_logic;  -- input, 
	signal sdat_dld_m     : std_logic;  -- output, delayed data 1 to ILOGIC/ISERDES2
  signal sdat_dld_s     : std_logic;  -- output, delayed data 1 to ILOGIC/ISERDES2
  signal cal_m          : std_logic :='0';
  signal cal_s          : std_logic :='0';
  signal iodelay_rst    : std_logic :='0';
  signal busy_m         : std_logic :='0';
  signal busy_s         : std_logic :='0';
  signal ce             : std_logic :='0';
  signal inc            : std_logic :='0';
  signal del_37ps       : std_logic_vector(4 downto 0) := B"0_0000";
  signal del_1ns        : std_logic_vector(2 downto 0) := B"000";
  
  signal stm_reset      : std_logic :='0';
  signal set_del        : std_logic :='0';
  signal del_done       : std_logic :='0';
 
  signal pdat           : std_logic_vector(7 downto 0)  := X"00";
  signal pdat_pipe      : std_logic_vector(31 downto 0) := X"0000_0000";

  type   top_state_type is (IDLE, RUNNING, RECOVER); -- top level state machine
  signal top_state : top_state_type := IDLE;

  type   state_type is (DEL_IDLE, DEL_START, DEL_CAL_WAIT, DEL_CAL, DEL_RST, DEL_WAITING, DEL_INC_WAIT, DEL_INC);
  signal state : state_type := DEL_IDLE;
   
  signal wait_ct       : std_logic_vector(7 downto 0)  := X"00";   
     
--iserdes
  signal sdat_cascade   : std_logic :='0';  --  
  signal iserdes_rst    : std_logic :='0';
  
begin


-------------------------------- INPUT_DELAY_inst instantiation -----------------------------------------
 
  iob_data_in : IBUFDS generic map(
    DIFF_TERM		=> true)
  port map (
    I    			=> sdat_in_p,
    IB       	=> sdat_in_n,
    O         => sdat_in);
    
 
  iodelay_m : IODELAY2 generic map(
    DATA_RATE      		=> "SDR", 			-- <SDR>, DDR
    SIM_TAPDELAY_VALUE	=> 37,  			-- nominal tap delay (sim parameter only)
    IDELAY_VALUE  		=> 0, 				-- {0 ... 255}
    IDELAY2_VALUE 		=> 0, 				-- {0 ... 255}
    ODELAY_VALUE  		=> 0, 				-- {0 ... 255}
    IDELAY_MODE   		=> "NORMAL", 			-- "NORMAL", "PCI"
    SERDES_MODE   		=> "MASTER", 			-- <NONE>, MASTER, SLAVE
    IDELAY_TYPE   		=> "VARIABLE_FROM_ZERO", 	-- "DEFAULT", "DIFF_PHASE_DETECTOR", "FIXED", "VARIABLE_FROM_HALF_MAX", "VARIABLE_FROM_ZERO"
    COUNTER_WRAPAROUND 	=> "STAY_AT_LIMIT", 		-- STAY_AT_LIMIT, WRAPAROUND
    DELAY_SRC     		=> "IDATAIN" )			-- "IO", "IDATAIN", "ODATAIN"
  port map (
    IDATAIN  		=> sdat_in, 		     -- input, data from master IOB
    TOUT     		=> open, 			  -- output, tri-state signal to IOB
    DOUT     		=> open, 			  -- output, data to IOB
    T        		=> '1', 			     -- input, tri-state control from OLOGIC/OSERDES2, tie high fro input only mode
    ODATAIN  		=> '0', 			     -- input, data from OLOGIC/OSERDES2
    DATAOUT  		=> sdat_dld_m, 	  -- output, delayed data 1 to ILOGIC/ISERDES2
    DATAOUT2 		=> open,--sdat_dld, 			  -- output, data 2 to ILOGIC/ISERDES2, for PCI ?
    IOCLK0   		=> iserdes_ioclk, 			  -- input, High speed clock for calibration
    IOCLK1   		=> '0', 			     -- input, High speed clock for calibration
    CLK      		=> clk,         -- input, Fabric clock (GCLK) for control signals
    CAL      		=> cal_m, 	  -- input, Calibrate enable signal
    INC      		=> inc, 			     -- input, increment / decrement delay counter
    CE       		=> ce, 			     -- input, enable increment / decrement delay counter
    RST      		=> iodelay_rst,     -- input, Reset delay line to 1/2 max in this case
    BUSY        => busy_m) ;         -- output signal indicating sync circuit has finished / calibration has finished

  iodelay_s : IODELAY2 generic map(
    DATA_RATE      		=> "SDR", 			-- <SDR>, DDR
    SIM_TAPDELAY_VALUE	=> 37,  			-- nominal tap delay (sim parameter only)
    IDELAY_VALUE  		=> 0, 				-- {0 ... 255}
    IDELAY2_VALUE 		=> 0, 				-- {0 ... 255}
    ODELAY_VALUE  		=> 0, 				-- {0 ... 255}
    IDELAY_MODE   		=> "NORMAL", 			-- "NORMAL", "PCI"
    SERDES_MODE   		=> "SLAVE", 			-- <NONE>, MASTER, SLAVE
    IDELAY_TYPE   		=> "VARIABLE_FROM_ZERO", 	-- "DEFAULT", "DIFF_PHASE_DETECTOR", "FIXED", "VARIABLE_FROM_HALF_MAX", "VARIABLE_FROM_ZERO"
    COUNTER_WRAPAROUND 	=> "STAY_AT_LIMIT", 		-- STAY_AT_LIMIT, WRAPAROUND
    DELAY_SRC     		=> "IDATAIN" )			-- "IO", "IDATAIN", "ODATAIN"
  port map (
    IDATAIN  		=> sdat_in, 		     -- input, data from master IOB
    TOUT     		=> open, 			  -- output, tri-state signal to IOB
    DOUT     		=> open, 			  -- output, data to IOB
    T        		=> '1', 			     -- input, tri-state control from OLOGIC/OSERDES2, tie high fro input only mode
    ODATAIN  		=> '0', 			     -- input, data from OLOGIC/OSERDES2
    DATAOUT  		=> sdat_dld_s, 	  -- output, delayed data 1 to ILOGIC/ISERDES2
    DATAOUT2 		=> open, 			  -- output, data 2 to ILOGIC/ISERDES2, for PCI ?
    IOCLK0   		=> iserdes_ioclk, 			  -- input, High speed clock for calibration
    IOCLK1   		=> '0', 			     -- input, High speed clock for calibration
    CLK      		=> clk,         -- input, Fabric clock (GCLK) for control signals
    CAL      		=> cal_s, 	  -- input, Calibrate enable signal
    INC      		=> inc, 			     -- input, increment / decrement delay counter
    CE       		=> ce, 			     -- input, enable increment / decrement delay counter
    RST      		=> iodelay_rst,       -- input, Reset delay line to 1/2 max in this case
    BUSY      	=> busy_s) ;         -- output signal indicating sync circuit has finished / calibration has finished

   -- iserdes2 instantiation
    
     iserdes_rst <= reset;
   
     ISERDES2_master_inst : ISERDES2
     generic map (
        BITSLIP_ENABLE => FALSE,     -- Enable Bitslip Functionality (TRUE/FALSE)
        DATA_RATE      => "SDR",     -- Data-rate ("SDR" or "DDR")
        DATA_WIDTH     => S,         -- Parallel data width selection (2-8)
        INTERFACE_TYPE => "RETIMED", -- "NETWORKING", "NETWORKING_PIPELINED" or "RETIMED" 
                                     -- "RETIMED" to meet the timing requirements !!!
        SERDES_MODE => "MASTER"           -- "NONE", "MASTER" or "SLAVE" 
     )
     port map (
        CFB0      => open,      -- 1-bit output: Clock feed-through route output
        CFB1      => open,      -- 1-bit output: Clock feed-through route output
        DFB       => open,      -- 1-bit output: Feed-through clock output
        FABRICOUT => open,      -- 1-bit output: Unsynchrnonized data output
        INCDEC    => open,      -- 1-bit output: Phase detector output
                      -- Q1 - Q4: 1-bit (each) output: Registered outputs to FPGA logic
        Q1       => pdat(4),
        Q2       => pdat(5),
        Q3       => pdat(6),
        Q4       => pdat(7),
        SHIFTOUT => sdat_cascade, -- 1-bit output: Cascade output signal for master/slave I/O
        VALID    => open,         -- 1-bit output: Output status of the phase detector
        BITSLIP  => '0',          -- 1-bit input: Bitslip enable input
        CE0      => '1',          -- 1-bit input: Clock enable input
        CLK0     => iserdes_ioclk,-- 1-bit input: I/O clock network input
        CLK1     => '0',          -- 1-bit input: Secondary I/O clock network input
        CLKDIV   => clk,          -- 1-bit input: FPGA logic domain clock input
        D        => sdat_dld_m,   -- 1-bit input: Input data
        IOCE     => iserdes_stb,  -- 1-bit input: Data strobe input
        RST      => iserdes_rst,          -- 1-bit input: Asynchronous reset input
        SHIFTIN  => '0'           -- 1-bit input: Cascade input signal for master/slave I/O
     );

    sdat_ISERDES2_slave_inst : ISERDES2
     generic map (
        BITSLIP_ENABLE => FALSE,        -- Enable Bitslip Functionality (TRUE/FALSE)
        DATA_RATE => "SDR",             -- Data-rate ("SDR" or "DDR")
        DATA_WIDTH => S,                -- Parallel data width selection (2-8)
        INTERFACE_TYPE => "RETIMED",    -- "NETWORKING", "NETWORKING_PIPELINED" or "RETIMED"
                                        -- "RETIMED" to meet the timing requirements !!!
        SERDES_MODE => "SLAVE"          -- "NONE", "MASTER" or "SLAVE" 
     )
     port map (
        CFB0     => open,    -- 1-bit output: Clock feed-through route output
        CFB1     => open,    -- 1-bit output: Clock feed-through route output
        DFB      => open,    -- 1-bit output: Feed-through clock output
        FABRICOUT=> open,    -- 1-bit output: Unsynchrnonized data output
        INCDEC   => open,    -- 1-bit output: Phase detector output
                             -- Q1 - Q4: 1-bit (each) output: Registered outputs to FPGA logic
        Q1       => pdat(0),
        Q2       => pdat(1),
        Q3       => pdat(2),
        Q4       => pdat(3),
        SHIFTOUT => open,    -- 1-bit output: Cascade output signal for master/slave I/O
        VALID    => open,   -- 1-bit output: Output status of the phase detector
        BITSLIP  => '0',     -- 1-bit input: Bitslip enable input
        CE0      => '1',       -- 1-bit input: Clock enable input
        CLK0     => iserdes_ioclk, -- 1-bit input: I/O clock network input
        CLK1     => '0',        -- 1-bit input: Secondary I/O clock network input
        CLKDIV   => clk,     -- 1-bit input: FPGA logic domain clock input
        D        => sdat_dld_s,    -- 1-bit input: Input data
        IOCE     => iserdes_stb, -- 1-bit input: Data strobe input
        RST      => iserdes_rst,   -- 1-bit input: Asynchronous reset input
        SHIFTIN  => sdat_cascade   -- 1-bit input: Cascade input signal for master/slave I/O
     );

  SET_COARSE_DELAY: process(clk, reset)
    begin
     if rising_edge(clk) then
      pdat_pipe(7)           <= pdat(0);
      pdat_pipe(6)           <= pdat(1);
      pdat_pipe(5)           <= pdat(2);
      pdat_pipe(4)           <= pdat(3);
      pdat_pipe(3)           <= pdat(4);
      pdat_pipe(2)           <= pdat(5);
      pdat_pipe(1)           <= pdat(6);
      pdat_pipe(0)           <= pdat(7);
      pdat_pipe(31 downto 8) <= pdat_pipe(23 downto 0) ;
      if (reset='1') then   -- initial delay to compensate for shorter delay from central cluster
       del_1ns  <= B"000";
       pdat_out <= B"0000_0000";
      else
       if del_load = '1' then
        del_1ns  <= del_data(7 downto 5);
       end if; -- del_load = '1'       
        case del_1ns is
         when B"000" => pdat_out <= pdat_pipe(18 downto 11);      
         when B"001" => pdat_out <= pdat_pipe(19 downto 12);      
         when B"010" => pdat_out <= pdat_pipe(20 downto 13);      
         when B"011" => pdat_out <= pdat_pipe(21 downto 14);      
         when B"100" => pdat_out <= pdat_pipe(22 downto 15);      
         when B"101" => pdat_out <= pdat_pipe(23 downto 16);      
         when B"110" => pdat_out <= pdat_pipe(24 downto 17);      
         when B"111" => pdat_out <= pdat_pipe(25 downto 18);
         when others => NULL; -- required line         
        end case;
      end if; -- (reset=1)
     end if; -- rising_edge(clk)
    end process SET_COARSE_DELAY;      


  DEL_STM_RESET : process (clk) -- reset DEL_SM if reset or del_load while del_busy
   begin
    if rising_edge(clk) then
     if reset = '1' then
      top_state <= IDLE;
      set_del   <= '0'; 
      init      <= '1';
     else    
      TOP_STM: case (top_state) is
     
      when IDLE     =>    
        if del_load = '1' or init = '1' then
         set_del   <= '1';
        end if;              
        if state = DEL_CAL_WAIT then
         top_state <= RUNNING;
        end if;
  
      when  RUNNING =>
        set_del   <= '0';
        if del_done = '1' then
         init      <= '0';
         top_state <= IDLE;
        elsif  
         del_load   = '1' then
         stm_reset <= '1';
         top_state <= RECOVER;
        end if;

      when RECOVER =>
         init      <= '0';
         stm_reset <= '0';
         set_del   <= '1';
         top_state <= IDLE;

      when others =>
         top_state <= IDLE;
    
      end case TOP_STM; 
     end if; -- if reset = '1' 
    end if; --rising_edge(clk) 
   end process DEL_STM_RESET;     
        
        

--
-- in_del_serdes_07.vhd, snippet seee below
--
 SET_INPUT_DELAY: process (clk)
    begin
     if rising_edge(clk) then    
       if stm_reset = '1' then
         state       <= DEL_IDLE;
       else
       
   DEL_SM : case (state) is
   
          when DEL_IDLE => 
            cal_m       <= '0';
            cal_s       <= '0';
            inc         <= '0';
            ce          <= '0';
            iodelay_rst <= '0';
            del_busy    <= '0';
            del_done    <= '0';            
            state       <= DEL_START;
            
          when DEL_START =>
            if set_del = '1' then          -- delayed del_load signal
              cal_m    <= '1';
              cal_s    <= '1';
              del_busy <= '1';
              state    <= DEL_CAL_WAIT;
            end if;
            
          when DEL_CAL_WAIT =>                 -- wait for the command being accepted
           if (busy_m and busy_s) = '1' then 
              cal_m <= '0';
              cal_s <= '0';
              state <= DEL_CAL;
            end if;  
              
          when DEL_CAL =>                      -- wait for calbration-readiness
            if ((busy_m or busy_s) = '0') then -- both busy are gone
              iodelay_rst <= '1';             
              state       <= DEL_RST;
            end if;    

          when DEL_RST =>                       -- reset the delay channel
            iodelay_rst <= '0';
            if ((busy_m or busy_s) = '0') then
             if init = '1' then
              del_37ps  <= INIT_DELAY;
             else 
              del_37ps <= del_data(4 downto 0);
             end if; 
              wait_ct   <= X"FF";
              state     <= DEL_WAITING;
            end if;    

          when DEL_WAITING => 
             if wait_ct /= X"00" then
               wait_ct <= wait_ct - '1';
             else               
               inc       <= '1';
               ce        <= '1';
              state     <= DEL_INC_WAIT;
             end if;    

          when DEL_INC_WAIT =>
             inc   <= '0';
             ce    <= '0';
             if ((busy_m and busy_s) = '1') then 
              state <= DEL_INC;
             end if;    

          when DEL_INC =>
             if ((busy_m or busy_s) = '0') then
              if del_37ps = B"0_0000" then
                del_busy   <= '0';
                state      <= DEL_IDLE;
                del_done   <= '1';
              else
               del_37ps <= del_37ps - '1';
               wait_ct  <= X"FF";
               state    <= DEL_WAITING;
              end if;
            end if;

          when others =>
               state      <= DEL_IDLE;
             
        end case DEL_SM;
      end if;
    end if;
   end process SET_INPUT_DELAY; 


end arch_iserdes_in_del;