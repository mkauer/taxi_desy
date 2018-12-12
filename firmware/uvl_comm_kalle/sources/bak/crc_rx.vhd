-------------------------------------------------------------------------------
-- Title      : COMMUNICATION
-- Project    : IceCube DOM main board/ DOR Card
-------------------------------------------------------------------------------
-- File       : crc_rx.vhd
-- Author     : thorsten
-- Company    : LBNL
-- Created    : 
-- Last update: 2004/04/05
-- Platform   : Altera Excalibur/Altera APEX
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: this module interfaces the CRC32 module for receive
-------------------------------------------------------------------------------
-- Copyright (c) 2004 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version     Author    Description
-- 2004-04-05  V01-01-00   thorsten  
-------------------------------------------------------------------------------



LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_arith.ALL;
USE IEEE.std_logic_unsigned.ALL;


ENTITY crc_rx IS
    PORT (
        CLK      : IN  STD_LOGIC;
        RST      : IN  STD_LOGIC;
        crc_init : IN  STD_LOGIC;
        data_stb : IN  STD_LOGIC;
        data     : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
        crc_zero : OUT STD_LOGIC
        );
END crc_rx;


ARCHITECTURE crc_rx_arch OF crc_rx IS

    COMPONENT crc32
        PORT (
            CLK     : IN  STD_LOGIC;
            RST     : IN  STD_LOGIC;
            init    : IN  STD_LOGIC;
            data_en : IN  STD_LOGIC;
            data_in : IN  STD_LOGIC;
            crc     : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
            );
    END COMPONENT;


    SIGNAL loopcnt : INTEGER RANGE 0 TO 9;
    SIGNAL srg     : STD_LOGIC_VECTOR (7 DOWNTO 0);

    SIGNAL crc32_en   : STD_LOGIC;
    SIGNAL crc32_init : STD_LOGIC;
    SIGNAL crc32_data : STD_LOGIC;
    SIGNAL crc        : STD_LOGIC_VECTOR (31 DOWNTO 0);

    TYPE state_type IS (IDLE, wait_byte, uart);
    SIGNAL state : state_type;

BEGIN  -- crc_tx_arch

    -- purpose: controls clearing, shifting in data and shifting in trailing 0 into CRC shiftregister
    -- type : sequential
    -- inputs : CLK, RST
    crc_control : PROCESS (CLK, RST)
    BEGIN  -- process crc_control
        IF RST = '1' THEN               -- asynchronous reset (active high
            state                       <= IDLE;
        ELSIF CLK'EVENT AND CLK = '1' THEN  -- rising clock edge
            IF crc_init = '1' THEN      -- reset CRC
                state                   <= idle;
                crc32_en                <= '0';
            ELSE
                CASE state IS
                    WHEN IDLE      =>
                        state           <= wait_byte;
                        crc32_en        <= '0';
                    WHEN wait_byte =>   -- wait for next byte
                        srg             <= data;
                        loopcnt         <= 0;
                        crc32_en        <= '0';
                        IF data_stb = '1' THEN  -- new data byte
                            state       <= uart;
                        END IF;
                    WHEN uart      =>   -- shift the byte through the CRC
                        srg(7 DOWNTO 1) <= srg(6 DOWNTO 0);
                        srg(0)          <= '0';
                        crc32_en        <= '1';
                        loopcnt         <= loopcnt + 1;
                        IF loopcnt = 7 THEN
                            state       <= wait_byte;
                        END IF;
                    WHEN OTHERS    =>
                        NULL;
                END CASE;
            END IF;  -- init
            crc32_data                  <= srg(7);
        END IF;  -- CLK
    END PROCESS crc_control;



    crc32_init <= crc_init;

    -- CRC32
    inst_crc32 : crc32
        PORT MAP (
            CLK     => CLK,
            RST     => RST,
            init    => crc32_init,
            data_en => crc32_en,
            data_in => crc32_data,
            crc     => crc
            );

    crc_zero <= '1' WHEN crc = X"00000000" ELSE '0';


END crc_rx_arch;











