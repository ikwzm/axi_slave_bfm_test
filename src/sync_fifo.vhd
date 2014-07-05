-- Synchronous FIFO for Simulation
--
-- 2014/07/03 by marsee
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use IEEE.math_real.all;

entity sync_fifo is 
    generic (
        C_MEMORY_SIZE    : integer := 512;    -- Word (not byte), 2のn乗
        DATA_BUS_WIDTH    : integer := 32        -- RAM Data Width
    );
    port (
        clk                : in    std_logic;
        rst                : in    std_logic;
        wr_en            : in    std_logic;
        din                : in    std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        full            : out    std_logic;
        almost_full        : out    std_logic;
        rd_en            : in    std_logic;
        dout            : out    std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        empty            : out     std_logic;
        almost_empty    : out    std_logic
    );
end sync_fifo;

architecture RTL of sync_fifo is

constant C_MEMORY_LENGTH : natural := natural(ceil(log(real(C_MEMORY_SIZE), 2.0))); -- C_MEMORY_SIZEの2進数の桁数

type mem_type is array (0 to C_MEMORY_SIZE-1) of std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
signal mem             : mem_type := (OTHERS => (OTHERS => '0'));
signal mem_waddr    : std_logic_vector(C_MEMORY_LENGTH-1 downto 0) := (others => '0');
signal mem_raddr    : std_logic_vector(C_MEMORY_LENGTH-1 downto 0) := (others => '0');
signal rp            : std_logic_vector(C_MEMORY_LENGTH-1 downto 0) := (others => '0');
signal wp            : std_logic_vector(C_MEMORY_LENGTH-1 downto 0) := (others => '0');

signal almost_full_node        : std_logic;
signal almost_empty_node    : std_logic;
signal full_node                : std_logic;
signal empty_node                : std_logic;
begin
    -- Write
    process (clk) begin
        if clk'event and clk='1' then
            if rst='1' then
                mem_waddr <= (others => '0');
                wp <= (others => '0');
            else
                if wr_en='1' then
                    mem_waddr <= std_logic_vector(unsigned(mem_waddr) + 1);
                    wp <= std_logic_vector(unsigned(wp) + 1);
                end if;
            end if;
        end if;
    end process;

    process (clk) begin
        if clk'event and clk='1' then
            if wr_en='1' then
                mem(TO_INTEGER(unsigned(mem_waddr))) <= din;
            end if;
        end if;
    end process;

    full_node <= '1' when std_logic_vector(unsigned(wp)+1)=rp else '0';
    full <= full_node;
    almost_full_node <= '1' when std_logic_vector(unsigned(wp)+2)=rp else '0';
    almost_full <= full_node or almost_full_node;

    -- Read
    process (clk) begin
        if clk'event and clk='1' then
            if rst='1' then
                mem_raddr <= (others => '0');
                rp <= (others => '0');
            else
                if rd_en='1' then
                    mem_raddr <= std_logic_vector(unsigned(mem_raddr) + 1);
                    rp <= std_logic_vector(unsigned(rp) + 1);
                end if;
            end if;
        end if;
    end process;

    dout <= mem(TO_INTEGER(unsigned(mem_raddr)));

    empty_node <= '1' when wp=rp else '0';
    empty <= empty_node;
    almost_empty_node <= '1' when wp=std_logic_vector(unsigned(rp)+1) else '0';
    almost_empty <= empty_node or almost_empty_node;
end RTL;
