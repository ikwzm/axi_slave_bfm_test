-----------------------------------------------------------------------------
--
-- AXI Master用 Slave Bus Function Mode (BFM)
-- axi_slave_BFM.vhd
--
-----------------------------------------------------------------------------
-- 2012/02/25 : S_AXI_AWBURST＝1 (INCR) にのみ対応、AWSIZE, ARSIZE = 000 (1byte), 001 (2bytes), 010 (4bytes) のみ対応。
-- 2012/07/04 : READ_ONLY_TRANSACTION を追加。Read機能のみでも+1したデータを出力することが出来るように変更した。
-- sync_fifo を使用したオーバーラップ対応版
-- 2014/07/04 : M_AXIをスレーブに対応した名前のS_AXIに変更
-- 2014/07/16 : Write Respose Channel に sync_fifo を使用した
-- 2014/08/31 : READ_RANDOM_WAIT=1 の時に、S_AXI_RREADY が S_AXI_RVALID に依存するバグをフィック。
--              WRITE_RANDOM_WAIT=1 の時に、S_AXI_WVALID が S_AXI_WREADY に依存するバグをフィック。
--
-- 2016/07/03 : AWREADY_IS_USUALLY_HIGH　と ARREADY_IS_USUALLY_HIGH　の2つのパラメータを追加 by marsee
--
-- ライセンスは二条項BSDライセンス (2-clause BSD license)とします。
--


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

package m_seq_bfm_pack is
    function M_SEQ16_BFM_F(mseq16in : std_logic_vector
        )return std_logic_vector;
end package m_seq_bfm_pack;
package body m_seq_bfm_pack is
    function M_SEQ16_BFM_F(mseq16in : std_logic_vector
        )return std_logic_vector is
            variable mseq16 : std_logic_vector(15 downto 0);
            variable xor_result : std_logic;
    begin
        xor_result := mseq16in(15) xor mseq16in(12) xor mseq16in(10) xor mseq16in(8) xor mseq16in(7) xor mseq16in(6) xor mseq16in(3) xor mseq16in(2);
        mseq16 := mseq16in(14 downto 0) & xor_result;
        return mseq16;
    end M_SEQ16_BFM_F;
end m_seq_bfm_pack;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use IEEE.math_real.all;

library work;
use work.m_seq_bfm_pack.all;

--library unisim;
--use unisim.vcomponents.all;

entity axi_slave_bfm is
  generic (
    C_S_AXI_ID_WIDTH             : integer := 1;
    C_S_AXI_ADDR_WIDTH           : integer := 32;
    C_S_AXI_DATA_WIDTH           : integer := 32;
    C_S_AXI_AWUSER_WIDTH    : integer := 1;
    C_S_AXI_ARUSER_WIDTH    : integer := 1;
    C_S_AXI_WUSER_WIDTH     : integer := 1;
    C_S_AXI_RUSER_WIDTH     : integer := 1;
    C_S_AXI_BUSER_WIDTH      : integer := 1;
    
    C_S_AXI_TARGET            : integer := 0;
    C_OFFSET_WIDTH            : integer := 10; -- 割り当てるRAMのアドレスのビット幅
    C_S_AXI_BURST_LEN        : integer := 256;
    
    WRITE_RANDOM_WAIT        : integer := 1; -- Write Transaction のデータ転送の時にランダムなWaitを発生させる=1, Waitしない=0
    READ_RANDOM_WAIT        : integer := 0; -- Read Transaction のデータ転送の時にランダムなWaitを発生させる=1, Waitしない=0
    READ_DATA_IS_INCREMENT    : integer := 0; -- ReadトランザクションでRAMの内容をReadする = 0（RAMにWriteしたものをReadする）、Readデータを+1する = 1（データは+1したデータをReadデータとして使用する
    RANDOM_BVALID_WAIT        : integer := 0;    -- Write Data Transaction が終了した後で、BVALID をランダムにWaitする = 1、BVALID をランダムにWaitしない = 0, 31 ~ 0 クロックのWait
    AWREADY_IS_USUALLY_HIGH    : integer := 1; -- AWRAEDY は通常はLow=0, High=1
    ARREADY_IS_USUALLY_HIGH : integer := 1  -- AWRAEDY は通常はLow=0, High=1
    );
  port(
    -- System Signals
    ACLK    : in std_logic;
    ARESETN : in std_logic;

    -- Master Interface Write Address Ports
    S_AXI_AWID     : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_AWADDR   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWLEN    : in  std_logic_vector(8-1 downto 0);
    S_AXI_AWSIZE   : in  std_logic_vector(3-1 downto 0);
    S_AXI_AWBURST  : in  std_logic_vector(2-1 downto 0);
    -- S_AXI_AWLOCK   : in  std_logic_vector(2-1 downto 0);
    S_AXI_AWLOCK   : in  std_logic_vector(1 downto 0);
    S_AXI_AWCACHE  : in  std_logic_vector(4-1 downto 0);
    S_AXI_AWPROT   : in  std_logic_vector(3-1 downto 0);
    S_AXI_AWQOS    : in  std_logic_vector(4-1 downto 0);
    S_AXI_AWUSER   : in  std_logic_vector(C_S_AXI_AWUSER_WIDTH-1 downto 0);
    S_AXI_AWVALID  : in  std_logic;
    S_AXI_AWREADY  : out std_logic;

    -- Master Interface Write Data Ports
    S_AXI_WDATA  : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB  : in  std_logic_vector(C_S_AXI_DATA_WIDTH/8-1 downto 0);
    S_AXI_WLAST  : in  std_logic;
    S_AXI_WUSER  : in  std_logic_vector(C_S_AXI_WUSER_WIDTH-1 downto 0);
    S_AXI_WVALID : in  std_logic;
    S_AXI_WREADY : out std_logic;

    -- Master Interface Write Response Ports
    S_AXI_BID    : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_BRESP  : out std_logic_vector(2-1 downto 0);
    S_AXI_BUSER  : out std_logic_vector(C_S_AXI_BUSER_WIDTH-1 downto 0);
    S_AXI_BVALID : out std_logic;
    S_AXI_BREADY : in  std_logic;

    -- Master Interface Read Address Ports
    S_AXI_ARID     : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_ARADDR   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARLEN    : in  std_logic_vector(8-1 downto 0);
    S_AXI_ARSIZE   : in  std_logic_vector(3-1 downto 0);
    S_AXI_ARBURST  : in  std_logic_vector(2-1 downto 0);
    S_AXI_ARLOCK   : in  std_logic_vector(2-1 downto 0);
    S_AXI_ARCACHE  : in  std_logic_vector(4-1 downto 0);
    S_AXI_ARPROT   : in  std_logic_vector(3-1 downto 0);
    S_AXI_ARQOS    : in  std_logic_vector(4-1 downto 0);
    S_AXI_ARUSER   : in  std_logic_vector(C_S_AXI_ARUSER_WIDTH-1 downto 0);
    S_AXI_ARVALID  : in  std_logic;
    S_AXI_ARREADY  : out std_logic;

    -- Master Interface Read Data Ports
    S_AXI_RID    : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_RDATA  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP  : out std_logic_vector(2-1 downto 0);
    S_AXI_RLAST  : out std_logic;
    S_AXI_RUSER  : out std_logic_vector(C_S_AXI_RUSER_WIDTH-1 downto 0);
    S_AXI_RVALID : out std_logic;
    S_AXI_RREADY : in  std_logic
    );

end axi_slave_bfm;

architecture implementation of axi_slave_bfm is

constant    AxBURST_FIXED    : std_logic_vector := "00";
constant    AxBURST_INCR    : std_logic_vector := "01";
constant    AxBURST_WRAP    : std_logic_vector := "10";

constant    RESP_OKAY        : std_logic_vector := "00";
constant    RESP_EXOKAY        : std_logic_vector := "01";
constant    RESP_SLVERR        : std_logic_vector := "10";
constant    RESP_DECERR        : std_logic_vector := "11";

constant    DATA_BUS_BYTES     : natural := C_S_AXI_DATA_WIDTH/8; -- データバスのビット幅
constant    ADD_INC_OFFSET    : natural := natural(log(real(DATA_BUS_BYTES), 2.0));

-- fifo depth for address
constant    AD_FIFO_DEPTH            : natural := 16;

-- wad_fifo field
constant    WAD_FIFO_WIDTH            : natural := C_S_AXI_ADDR_WIDTH+5+C_S_AXI_ID_WIDTH-1+1;
constant    WAD_FIFO_AWID_HIGH        : natural := C_S_AXI_ADDR_WIDTH+5+C_S_AXI_ID_WIDTH-1;
constant    WAD_FIFO_AWID_LOW        : natural := C_S_AXI_ADDR_WIDTH+5;
constant    WAD_FIFO_AWBURST_HIGH    : natural := C_S_AXI_ADDR_WIDTH+4;
constant    WAD_FIFO_AWBURST_LOW    : natural := C_S_AXI_ADDR_WIDTH+3;
constant    WAD_FIFO_AWSIZE_HIGH    : natural := C_S_AXI_ADDR_WIDTH+2;
constant    WAD_FIFO_AWSIZE_LOW        : natural := C_S_AXI_ADDR_WIDTH;
constant    WAD_FIFO_ADDR_HIGH        : natural := C_S_AXI_ADDR_WIDTH-1;
constant    WAD_FIFO_ADDR_LOW        : natural := 0;

-- wres_fifo field
constant    WRES_FIFO_WIDTH            : natural := 2+C_S_AXI_ID_WIDTH-1+1;
constant    WRES_FIFO_AWID_HIGH        : natural := 2+C_S_AXI_ID_WIDTH-1;
constant    WRES_FIFO_AWID_LOW        : natural := 2;
constant    WRES_FIFO_AWBURST_HIGH    : natural := 1;
constant    WRES_FIFO_AWBURST_LOW    : natural := 0;

-- rad_fifo field
constant    RAD_FIFO_WIDTH            : natural := C_S_AXI_ADDR_WIDTH+13+C_S_AXI_ID_WIDTH-1+1;
constant    RAD_FIFO_ARID_HIGH        : natural := C_S_AXI_ADDR_WIDTH+13+C_S_AXI_ID_WIDTH-1;
constant    RAD_FIFO_ARID_LOW        : natural := C_S_AXI_ADDR_WIDTH+13;
constant    RAD_FIFO_ARBURST_HIGH    : natural := C_S_AXI_ADDR_WIDTH+12;
constant    RAD_FIFO_ARBURST_LOW    : natural := C_S_AXI_ADDR_WIDTH+11;
constant    RAD_FIFO_ARSIZE_HIGH    : natural := C_S_AXI_ADDR_WIDTH+10;
constant    RAD_FIFO_ARSIZE_LOW        : natural := C_S_AXI_ADDR_WIDTH+8;
constant    RAD_FIFO_ARLEN_HIGH        : natural := C_S_AXI_ADDR_WIDTH+7;
constant    RAD_FIFO_ARLEN_LOW        : natural := C_S_AXI_ADDR_WIDTH;
constant    RAD_FIFO_ADDR_HIGH        : natural := C_S_AXI_ADDR_WIDTH-1;
constant    RAD_FIFO_ADDR_LOW        : natural := 0;

-- RAMの生成
constant    SLAVE_ADDR_NUMBER    : integer := 2**(C_OFFSET_WIDTH - ADD_INC_OFFSET);
type ram_array_def is array (SLAVE_ADDR_NUMBER-1 downto 0) of std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
signal ram_array : ram_array_def := (others => (others => '0'));

-- for write transaction
type write_address_state is (idle_wrad, awr_accept);
type write_data_state is (idle_wrdt, wr_burst);
type write_response_state is (idle_wres, wait_bvalid, bvalid_assert);
signal wradr_cs : write_address_state;
signal wrdat_cs : write_data_state;
signal wrres_cs : write_response_state;
signal addr_inc_step_wr : integer := 1;
signal awready         : std_logic;
signal wr_addr         : std_logic_vector(C_OFFSET_WIDTH-1 downto 0);
signal wr_bvalid     : std_logic;
signal m_seq16_wr    : std_logic_vector(15 downto 0);
signal wready        : std_logic;
type wready_state is (idle_wready, assert_wready, deassert_wready);
signal cs_wready : wready_state;
signal cdc_we : std_logic;
signal wad_fifo_full, wad_fifo_empty : std_logic;
signal wad_fifo_almost_full, wad_fifo_almost_empty : std_logic;
signal wad_fifo_rd_en : std_logic;
signal wad_fifo_wr_en : std_logic;
signal wad_fifo_din : std_logic_vector(WAD_FIFO_WIDTH-1 downto 0);
signal wad_fifo_dout : std_logic_vector(WAD_FIFO_WIDTH-1 downto 0);
signal m_seq16_wr_res    : std_logic_vector(15 downto 0);
signal wr_resp_cnt : std_logic_vector(4 downto 0);
signal wres_fifo_wr_en : std_logic;
signal wres_fifo_full, wres_fifo_empty : std_logic;
signal wres_fifo_almost_full, wres_fifo_almost_empty : std_logic;
signal wres_fifo_rd_en : std_logic;
signal wres_fifo_din : std_logic_vector(WRES_FIFO_WIDTH-1 downto 0);
signal wres_fifo_dout : std_logic_vector(WRES_FIFO_WIDTH-1 downto 0);

-- for read transaction
type read_address_state is (idle_rda, arr_accept);
type read_data_state is (idle_rdd, rd_burst);
type read_last_state is (idle_rlast, rlast_assert);
signal rdadr_cs : read_address_state;
signal rddat_cs : read_data_state;
signal rdlast : read_last_state;
signal addr_inc_step_rd : integer := 1;
signal arready         : std_logic;
signal rd_addr         : std_logic_vector(C_OFFSET_WIDTH-1 downto 0);
signal rd_axi_count    : std_logic_vector(7 downto 0);
signal rvalid        : std_logic;
signal rlast        : std_logic;
signal m_seq16_rd    : std_logic_vector(15 downto 0);
type rvalid_state is (idle_rvalid, assert_rvalid, deassert_rvalid);
signal cs_rvalid : rvalid_state;
signal read_data_count : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

signal reset_1d, reset_2d, reset : std_logic := '1';
signal rad_fifo_full, rad_fifo_empty : std_logic;
signal rad_fifo_almost_full, rad_fifo_almost_empty : std_logic;
signal rad_fifo_rd_en : std_logic;
signal rad_fifo_wr_en : std_logic;
signal rad_fifo_din : std_logic_vector(RAD_FIFO_WIDTH-1 downto 0);
signal rad_fifo_dout : std_logic_vector(RAD_FIFO_WIDTH-1 downto 0);

component sync_fifo generic (
    constant    C_MEMORY_SIZE     : integer := 512;    -- Word (not byte), 2のn乗
    constant    DATA_BUS_WIDTH    : integer := 32        -- RAM Data Width
);
 port (
    clk                : in    std_logic;
    rst                : in     std_logic;
    wr_en            : in     std_logic;
    din                : in     std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    full            : out     std_logic;
    almost_full     : out     std_logic;
    rd_en            : in     std_logic;
    dout            : out    std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    empty            : out    std_logic;
    almost_empty    : out    std_logic
);
end component;

begin
    -- ARESETN をACLK で同期化
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            reset_1d <= not ARESETN;
            reset_2d <= reset_1d;
        end if;
    end process;
    reset <= reset_2d;
    
    -- AXI4バス Write Address State Machine
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                wradr_cs <= idle_wrad;
                awready <= '0';
            else
                case (wradr_cs) is
                    when idle_wrad =>
                        if S_AXI_AWVALID='1' and wad_fifo_full='0' and wres_fifo_full='0' then -- S_AXI_AWVALID が1にアサートされた
                            wradr_cs <= awr_accept;
                            awready <= '1';
                        end if;
                    when awr_accept => -- S_AXI_AWREADY をアサート
                        wradr_cs <= idle_wrad;
                        awready <= '0';
                end case;
            end if;
        end if;
    end process;
    S_AXI_AWREADY <= not wad_fifo_full when AWREADY_IS_USUALLY_HIGH=1 else awready;
    
    -- S_AXI_AWID & S_AXI_AWBURST & S_AXI_AWSIZE & S_AXI_AWADDR　を保存しておく同期FIFO
    wad_fifo_din <= (S_AXI_AWID & S_AXI_AWBURST & S_AXI_AWSIZE & S_AXI_AWADDR);
    wad_fifo_wr_en <= (S_AXI_AWVALID and (not wad_fifo_full)) when AWREADY_IS_USUALLY_HIGH=1 else awready;

    wad_fifo : sync_fifo generic map(
        C_MEMORY_SIZE => AD_FIFO_DEPTH,
        DATA_BUS_WIDTH => WAD_FIFO_WIDTH
    ) port map (
        clk =>            ACLK,
        rst =>            reset,
        wr_en =>         wad_fifo_wr_en,
        din =>            wad_fifo_din,
        full =>            wad_fifo_full,
        almost_full =>    wad_fifo_almost_full,
        rd_en =>        wad_fifo_rd_en,
        dout =>            wad_fifo_dout,
        empty =>         wad_fifo_empty,
        almost_empty =>    wad_fifo_almost_empty
    );
    wad_fifo_rd_en <= '1' when wready='1' and S_AXI_WVALID='1' and S_AXI_WLAST='1' else '0';

    -- AXI4バス Write Data State Machine
    process (ACLK) begin
        if ACLK'event and ACLK='1' then
            if reset='1' then
                wrdat_cs <= idle_wrdt;
            else
                case( wrdat_cs ) is
                    when idle_wrdt =>
                        if wad_fifo_empty='0' then -- AXI Write アドレス転送の残りが1個以上ある
                            wrdat_cs <= wr_burst;
                        end if;
                    when wr_burst => -- Writeデータの転送
                        if S_AXI_WLAST='1' and S_AXI_WVALID='1' and wready='1' then -- Write Transaction 終了
                            wrdat_cs <= idle_wrdt;
                        end if;
                    when others =>
                
                end case ;
            end if;
        end if;
    end process;

    -- m_seq_wr、16ビットのM系列を計算する
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                m_seq16_wr <= (0 => '1', others => '0');
            else
                if WRITE_RANDOM_WAIT=1 then -- Write Transaction 時にランダムなWaitを挿入する
                    if wrdat_cs=wr_burst then
                        m_seq16_wr <= M_SEQ16_BFM_F(m_seq16_wr);
                    end if;
                else -- Wait無し
                    m_seq16_wr <= (others => '0');
                end if;
            end if;
        end if;
    end process;
                
    -- wready の処理、M系列を計算して128以上だったらWaitする。
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                cs_wready <= idle_wready;
                wready <= '0';
            else
                case (cs_wready) is
                    when idle_wready =>
                        if wrdat_cs=idle_wrdt and wad_fifo_empty='0' then -- 次はwr_burst
                            if m_seq16_wr(7)='0' and wres_fifo_full='0' then -- wready='1'
                                cs_wready <= assert_wready;
                                wready <= '1';
                            else -- m_seq16_wr(7)='1' then -- wready='0'
                                cs_wready <= deassert_wready;
                                wready <= '0';
                            end if;
                        end if;
                    when assert_wready => -- 一度wreadyがアサートされたら、1つのトランザクションが終了するまでwready='1'
                        if wrdat_cs=wr_burst and S_AXI_WLAST='1' and S_AXI_WVALID='1' then -- 終了
                            cs_wready <= idle_wready;
                            wready <= '0';
                        elsif wrdat_cs=wr_burst and S_AXI_WVALID='1' then -- 1つのトランザクション終了。
                            if m_seq16_wr(7)='1' or wres_fifo_full='1' then
                                cs_wready <= deassert_wready;
                                wready <= '0';
                            end if;
                        end if;
                    when deassert_wready =>
                        if m_seq16_wr(7)='0' and wres_fifo_full='0' then -- wready='1'
                            cs_wready <= assert_wready;
                            wready <= '1';
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    S_AXI_WREADY <= wready;
    cdc_we <= '1' when wrdat_cs=wr_burst and wready='1' and S_AXI_WVALID='1' else '0';
    
    -- addr_inc_step_wr の処理
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                addr_inc_step_wr <= 1;
            else
                if wrdat_cs=idle_wrdt and wad_fifo_empty='0' then
                    case (wad_fifo_dout(WAD_FIFO_AWSIZE_HIGH downto WAD_FIFO_AWSIZE_LOW)) is
                        when "000" => -- 8ビット転送
                            addr_inc_step_wr <= 1;
                        when "001" => -- 16ビット転送
                            addr_inc_step_wr <= 2;
                        when "010" => -- 32ビット転送
                            addr_inc_step_wr <= 4;
                        when "011" => -- 64ビット転送
                            addr_inc_step_wr <= 8;
                        when "100" => -- 128ビット転送
                            addr_inc_step_wr <= 16;
                        when "101" => -- 256ビット転送
                            addr_inc_step_wr <= 32;
                        when "110" => -- 512ビット転送
                            addr_inc_step_wr <= 64;
                        when others => --"111" => -- 1024ビット転送
                            addr_inc_step_wr <= 128;
                    end case;
                end if;
            end if;
        end if;
    end process;
    
    -- wr_addr の処理
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                wr_addr <= (others => '0');
            else
                if wrdat_cs=idle_wrdt and wad_fifo_empty='0' then
                    wr_addr <= wad_fifo_dout(C_OFFSET_WIDTH-1 downto 0);
                elsif wrdat_cs=wr_burst and S_AXI_WVALID='1' and wready='1' then -- アドレスを進める
                    wr_addr <= std_logic_vector(unsigned(wr_addr) + addr_inc_step_wr);
                end if;
            end if;
        end if;
    end process;
    
    -- Wirte Response FIFO (wres_fifo)
    wres_fifo : sync_fifo generic map(
        C_MEMORY_SIZE => AD_FIFO_DEPTH,
        DATA_BUS_WIDTH => WRES_FIFO_WIDTH
    ) port map (
        clk =>            ACLK,
        rst =>            reset,
        wr_en =>         wres_fifo_wr_en,
        din =>            wres_fifo_din,
        full =>            wres_fifo_full,
        almost_full =>    wres_fifo_almost_full,
        rd_en =>        wres_fifo_rd_en,
        dout =>            wres_fifo_dout,
        empty =>         wres_fifo_empty,
        almost_empty =>    wres_fifo_almost_empty
    );
    wres_fifo_wr_en <= '1' when S_AXI_WLAST='1' and S_AXI_WVALID='1' and wready='1' else '0'; -- Write Transaction 終了
    wres_fifo_din <= (wad_fifo_dout(WAD_FIFO_AWID_HIGH downto WAD_FIFO_AWID_LOW) & wad_fifo_dout(WAD_FIFO_AWBURST_HIGH downto WAD_FIFO_AWBURST_LOW));
    wres_fifo_rd_en <= '1' when wr_bvalid='1' and S_AXI_BREADY='1' and wres_fifo_empty='0' else '0';

    -- S_AXI_BID の処理
    S_AXI_BID <= wres_fifo_dout(WRES_FIFO_AWID_HIGH downto WRES_FIFO_AWID_LOW);
    
    -- S_AXI_BRESP の処理
    -- S_AXI_AWBURSTがINCRの時はOKAYを返す。それ以外はSLVERRを返す。
    S_AXI_BRESP <= RESP_OKAY when wres_fifo_dout(WRES_FIFO_AWBURST_HIGH downto WRES_FIFO_AWBURST_LOW)=AxBURST_INCR else RESP_SLVERR;
    
    -- wr_bvalid の処理
    -- wr_bvalid のアサートは、Write Data Channelの完了より必ず1クロックは遅延する
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                wrres_cs <= idle_wres;
                wr_bvalid <= '0';
            else
                case( wrres_cs ) is
                    when idle_wres =>
                        if wres_fifo_empty='0' then -- Write Transaction 終了
                            if unsigned(m_seq16_wr_res) = 0 or RANDOM_BVALID_WAIT=0 then
                                wrres_cs <= bvalid_assert;
                                wr_bvalid <= '1';
                            else
                                wrres_cs <= wait_bvalid;
                            end if;
                        end if;
                    when wait_bvalid =>
                        if unsigned(wr_resp_cnt) = 0 then
                            wrres_cs <= bvalid_assert;
                            wr_bvalid <= '1';
                        end if;
                    when bvalid_assert =>
                        if (S_AXI_BREADY='1') then
                            wrres_cs <= idle_wres;
                            wr_bvalid <= '0';
                        end if;
                    when others =>
                
                end case ;
            end if;
        end if;
    end process;
    S_AXI_BVALID <= wr_bvalid;
    S_AXI_BUSER <= (others => '0');

    -- wr_resp_cnt
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                wr_resp_cnt <= (others => '0');
            else
                if wrres_cs=idle_wres and wres_fifo_empty='0' then
                    wr_resp_cnt <= m_seq16_wr_res(4 downto 0);
                elsif unsigned(wr_resp_cnt) /= 0 then
                    wr_resp_cnt <= std_logic_vector(unsigned(wr_resp_cnt) - 1);
                end if;
            end if;
        end if;
    end process;

    -- m_seq_wr_res、16ビットのM系列を計算する
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                m_seq16_wr_res <= (0 => '1', others => '0');
            else
                m_seq16_wr_res <= M_SEQ16_BFM_F(m_seq16_wr_res);
            end if;
        end if;
    end process;
    
    
    -- AXI4バス Read Address Transaction State Machine
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                rdadr_cs <= idle_rda;
                arready <= '0';
            else
                case (rdadr_cs) is
                    when idle_rda =>
                        if S_AXI_ARVALID='1' and rad_fifo_full='0' then -- Read Transaction 要求
                            rdadr_cs <= arr_accept;
                            arready <= '1';
                        end if;
                    when arr_accept => -- S_AXI_ARREADY をアサート
                        rdadr_cs <= idle_rda;
                        arready <= '0';
                end case;
            end if;
        end if;
    end process;
    S_AXI_ARREADY <= not rad_fifo_full when ARREADY_IS_USUALLY_HIGH=1 else arready;

    -- S_AXI_ARID & S_AXI_ARBURST & S_AXI_ARSIZE & S_AXI_ARLEN & S_AXI_ARADDR を保存しておく同期FIFO
    rad_fifo_din <= (S_AXI_ARID & S_AXI_ARBURST & S_AXI_ARSIZE & S_AXI_ARLEN & S_AXI_ARADDR);
    rad_fifo_wr_en <= (S_AXI_ARVALID and (not rad_fifo_full)) when ARREADY_IS_USUALLY_HIGH=1 else arready;

    rad_fifo : sync_fifo generic map (
        C_MEMORY_SIZE =>    AD_FIFO_DEPTH,
        DATA_BUS_WIDTH =>    RAD_FIFO_WIDTH
    ) port map (
        clk =>            ACLK,
        rst =>            reset,
        wr_en =>        rad_fifo_wr_en,
        din =>             rad_fifo_din,
        full =>            rad_fifo_full,
        almost_full =>    rad_fifo_almost_full,
        rd_en =>        rad_fifo_rd_en,
        dout =>            rad_fifo_dout,
        empty =>        rad_fifo_empty,
        almost_empty =>    rad_fifo_almost_empty
    );
    rad_fifo_rd_en <= '1' when rvalid='1' and S_AXI_RREADY='1' and rlast='1' else '0';

    -- AXI4バス Read Data Transaction State Machine
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                rddat_cs <= idle_rdd;
            else
                case (rddat_cs) is
                    when idle_rdd =>
                        if rad_fifo_empty='0' then -- AXI Read アドレス転送の残りが1個以上ある
                            rddat_cs <= rd_burst;
                        end if;
                    when rd_burst =>
                        if unsigned(rd_axi_count)=0 and rvalid='1' and S_AXI_RREADY='1' then -- Read Transaction 終了
                            rddat_cs <= idle_rdd;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- m_seq_rd、16ビットのM系列を計算する
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                m_seq16_rd <= (others => '1'); -- Writeとシードを変更する
            else
                if READ_RANDOM_WAIT=1 then -- Read Transaciton のデータ転送でランダムなWaitを挿入する場合
                    if rddat_cs=rd_burst then
                        m_seq16_rd <= M_SEQ16_BFM_F(m_seq16_rd);
                    end if;
                else -- Wati無し
                    m_seq16_rd <= (others => '0');
                end if;
            end if;
        end if;
    end process;
                
    -- rvalid の処理、M系列を計算して128以上だったらWaitする。
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                cs_rvalid <= idle_rvalid;
                rvalid <= '0';
            else
                case (cs_rvalid) is
                    when idle_rvalid =>
                        if rddat_cs=idle_rdd and rad_fifo_empty='0' then -- 次はrd_burst
                            if m_seq16_rd(7)='0' then -- rvalid='1'
                                cs_rvalid <= assert_rvalid;
                                rvalid <= '1';
                            else -- m_seq16_rd(7)='1' then -- rvalid='0'
                                cs_rvalid <= deassert_rvalid;
                                rvalid <= '0';
                            end if;
                        end if;
                    when assert_rvalid => -- 一度rvalidがアサートされたら、1つのトランザクションが終了するまでrvalid='1'
                        if rddat_cs=rd_burst and rlast='1' and S_AXI_RREADY='1' then -- 終了
                            cs_rvalid <= idle_rvalid;
                            rvalid <= '0';
                        elsif rddat_cs=rd_burst and S_AXI_RREADY='1' then -- 1つのトランザクション終了。
                            if m_seq16_rd(7)='1' then
                                cs_rvalid <= deassert_rvalid;
                                rvalid <= '0';
                            end if;
                        end if;
                    when deassert_rvalid =>
                        if m_seq16_rd(7)='0' then -- rvalid='1'
                            cs_rvalid <= assert_rvalid;
                            rvalid <= '1';
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    S_AXI_RVALID <= rvalid;
    
    -- addr_inc_step_rd の処理
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                addr_inc_step_rd <= 1;
            else
                if rddat_cs=idle_rdd and rad_fifo_empty='0' then
                    case (rad_fifo_dout(RAD_FIFO_ARSIZE_HIGH downto RAD_FIFO_ARSIZE_LOW)) is
                        when "000" => -- 8ビット転送
                            addr_inc_step_rd <= 1;
                        when "001" => -- 16ビット転送
                            addr_inc_step_rd <= 2;
                        when "010" => -- 32ビット転送
                            addr_inc_step_rd <= 4;
                        when "011" => -- 64ビット転送
                            addr_inc_step_rd <= 8;
                        when "100" => -- 128ビット転送
                            addr_inc_step_rd <= 16;
                        when "101" => -- 256ビット転送
                            addr_inc_step_rd <= 32;
                        when "110" => -- 512ビット転送
                            addr_inc_step_rd <= 64;
                        when others => -- "111" => -- 1024ビット転送
                            addr_inc_step_rd <= 128;
                    end case;
                end if;
            end if;
        end if;
    end process;
    
    -- rd_addr の処理
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                rd_addr <= (others => '0');
            else
                if rddat_cs=idle_rdd and rad_fifo_empty='0' then
                    rd_addr <= rad_fifo_dout(C_OFFSET_WIDTH-1 downto 0);
                elsif rddat_cs=rd_burst and S_AXI_RREADY='1' and rvalid='1' then
                    rd_addr <= std_logic_vector(unsigned(rd_addr) + addr_inc_step_rd);
                end if;
            end if;
        end if;
    end process;
    
    -- rd_axi_count の処理（AXIバス側のデータカウント）
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                rd_axi_count <= (others => '0');
            else
                if rddat_cs=idle_rdd and rad_fifo_empty='0' then -- rd_axi_count のロード
                    rd_axi_count <= rad_fifo_dout(RAD_FIFO_ARLEN_HIGH downto RAD_FIFO_ARLEN_LOW);
                elsif rddat_cs=rd_burst and rvalid='1' and S_AXI_RREADY='1' then -- Read Transaction が1つ終了
                    rd_axi_count <= std_logic_vector(unsigned(rd_axi_count) - 1);
                end if;
            end if;
        end if;
    end process;
    
    -- rdlast State Machine
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                rdlast <= idle_rlast;
                rlast <= '0';
            else
                case (rdlast) is
                    when idle_rlast =>
                        if unsigned(rd_axi_count)=1 and rvalid='1' and S_AXI_RREADY='1' then -- バーストする場合
                            rdlast <= rlast_assert;
                            rlast <= '1';
                        elsif rddat_cs=idle_rdd and rad_fifo_empty='0' and unsigned(rad_fifo_dout(RAD_FIFO_ARLEN_HIGH downto RAD_FIFO_ARLEN_LOW))=0 then -- 転送数が1の場合
                            rdlast <= rlast_assert;
                            rlast <= '1';
                        end if;
                    when rlast_assert => 
                        if rvalid='1' and S_AXI_RREADY='1' then -- Read Transaction 終了（rd_axi_count=0は決定）
                            rdlast <= idle_rlast;
                            rlast <= '0';
                        end if;
                end case;
            end if;
        end if;
    end process;
    S_AXI_RLAST <= rlast;
    
    -- S_AXI_RID, S_AXI_RUSER の処理
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                S_AXI_RID <= (others => '0');
            else
                if rddat_cs=idle_rdd and rad_fifo_empty='0' then
                    S_AXI_RID <= rad_fifo_dout(RAD_FIFO_ARID_HIGH downto RAD_FIFO_ARID_LOW);
                end if;
            end if;
        end if;
    end process;
    S_AXI_RUSER <= (others => '0');
    
    -- S_AXI_RRESP は、S_AXI_ARBURST がINCR の場合はOKAYを返す。それ以外はSLVERRを返す。
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                S_AXI_RRESP <= (others => '0');
            else
                if rddat_cs=idle_rdd and rad_fifo_empty='0' then
                    if rad_fifo_dout(RAD_FIFO_ARBURST_HIGH downto RAD_FIFO_ARBURST_LOW)=AxBURST_INCR then
                        S_AXI_RRESP <= RESP_OKAY;
                    else
                        S_AXI_RRESP <= RESP_SLVERR;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- RAM
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if cdc_we='1' then
                for i in 0 to C_S_AXI_DATA_WIDTH/8-1 loop
                    if S_AXI_WSTRB(i)='1' then -- Byte Enable
                        ram_array(TO_INTEGER(unsigned(wr_addr(C_OFFSET_WIDTH-1 downto ADD_INC_OFFSET))))(i*8+7 downto i*8) <= S_AXI_WDATA(i*8+7 downto i*8);
                    end if;
                end loop;
            end if;
        end if;
    end process;

    -- Read Transaciton の時に +1 されたReadデータを使用する（Read 毎に+1）
    process (ACLK) begin
        if ACLK'event and ACLK='1' then 
            if reset='1' then
                read_data_count <= (others => '0');
            else
                if rddat_cs=rd_burst and rvalid='1' and S_AXI_RREADY='1' then -- Read Transaction が1つ終了
                    read_data_count <= std_logic_vector(unsigned(read_data_count) + 1);
                end if;
            end if;
        end if;
    end process;
    
    S_AXI_RDATA <= ram_array(TO_INTEGER(unsigned(rd_addr(C_OFFSET_WIDTH-1 downto ADD_INC_OFFSET)))) when READ_DATA_IS_INCREMENT=0 else read_data_count;
    
end implementation;
