-----------------------------------------------------------------------------------
--!     @file    axi_slave_bfm_test_benc.vhd
--!     @brief   TEST BENCH axi_slave_BFM
--!     @version 0.0.3
--!     @date    2014/7/20
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2012,2013 Ichiro Kawazome
--      All rights reserved.
--
--      Redistribution and use in source and binary forms, with or without
--      modification, are permitted provided that the following conditions
--      are met:
--
--        1. Redistributions of source code must retain the above copyright
--           notice, this list of conditions and the following disclaimer.
--
--        2. Redistributions in binary form must reproduce the above copyright
--           notice, this list of conditions and the following disclaimer in
--           the documentation and/or other materials provided with the
--           distribution.
--
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
--      A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
--      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
--      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     std.textio.all;
library DUMMY_PLUG;
use     DUMMY_PLUG.AXI4_TYPES.all;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_MASTER_PLAYER;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_SLAVE_PLAYER;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_SIGNAL_PRINTER;
use     DUMMY_PLUG.SYNC.all;
use     DUMMY_PLUG.CORE.MARCHAL;
use     DUMMY_PLUG.CORE.REPORT_STATUS_TYPE;
entity  axi_slave_bfm_test_bench is
    generic (
        NAME            : --! @brief テストベンチの識別名.
                          STRING  := string'("axi_slave_bfm_test");
        SCENARIO_FILE   : --! @brief シナリオファイルの名前.
                          STRING  := string'("axi_slave_bfm_test.snr");
        RAM_INIT_FILE   : --! @brief axi_slave_BFM RAM初期化ファイルの名前.
                          STRING  := string'("axi_slave_bfm_test.dat");
        DATA_WIDTH      : --! @brief データチャネルのビット幅.
                          integer := 32
    );
end     axi_slave_bfm_test_bench;
architecture MODEL of axi_slave_bfm_test_bench is
    -------------------------------------------------------------------------------
    -- 各種定数
    -------------------------------------------------------------------------------
    constant PERIOD          : time    := 10 ns;
    constant DELAY           : time    :=  1 ns;
    constant WIDTH           : AXI4_SIGNAL_WIDTH_TYPE := (
                                 ID          =>  1,
                                 AWADDR      => 32,
                                 ARADDR      => 32,
                                 ALEN        =>  8,
                                 ALOCK       =>  2,
                                 WDATA       => DATA_WIDTH,
                                 RDATA       => DATA_WIDTH,
                                 ARUSER      =>  1,
                                 AWUSER      =>  1,
                                 WUSER       =>  1,
                                 RUSER       =>  1,
                                 BUSER       =>  1);
    constant SYNC_WIDTH      : integer :=  2;
    constant GPO_WIDTH       : integer :=  8;
    constant GPI_WIDTH       : integer :=  8;
    -------------------------------------------------------------------------------
    -- グローバルシグナル.
    -------------------------------------------------------------------------------
    signal   ACLK            : std_logic;
    signal   ARESETn         : std_logic;
    signal   RESET           : std_logic;
    ------------------------------------------------------------------------------
    -- リードアドレスチャネルシグナル.
    ------------------------------------------------------------------------------
    signal   S_AXI_ARADDR    : std_logic_vector(WIDTH.ARADDR -1 downto 0);
    signal   S_AXI_ARLEN     : std_logic_vector(WIDTH.ALEN   -1 downto 0);
    signal   S_AXI_ARSIZE    : AXI4_ASIZE_TYPE;
    signal   S_AXI_ARBURST   : AXI4_ABURST_TYPE;
    signal   S_AXI_ARLOCK    : std_logic_vector(WIDTH.ALOCK  -1 downto 0);
    signal   S_AXI_ARCACHE   : AXI4_ACACHE_TYPE;
    signal   S_AXI_ARPROT    : AXI4_APROT_TYPE;
    signal   S_AXI_ARQOS     : AXI4_AQOS_TYPE;
    signal   S_AXI_ARREGION  : AXI4_AREGION_TYPE;
    signal   S_AXI_ARUSER    : std_logic_vector(WIDTH.ARUSER -1 downto 0);
    signal   S_AXI_ARID      : std_logic_vector(WIDTH.ID     -1 downto 0);
    signal   S_AXI_ARVALID   : std_logic;
    signal   S_AXI_ARREADY   : std_logic;
    -------------------------------------------------------------------------------
    -- リードデータチャネルシグナル.
    -------------------------------------------------------------------------------
    signal   S_AXI_RVALID    : std_logic;
    signal   S_AXI_RLAST     : std_logic;
    signal   S_AXI_RDATA     : std_logic_vector(WIDTH.RDATA  -1 downto 0);
    signal   S_AXI_RRESP     : AXI4_RESP_TYPE;
    signal   S_AXI_RUSER     : std_logic_vector(WIDTH.RUSER  -1 downto 0);
    signal   S_AXI_RID       : std_logic_vector(WIDTH.ID     -1 downto 0);
    signal   S_AXI_RREADY    : std_logic;
    -------------------------------------------------------------------------------
    -- ライトアドレスチャネルシグナル.
    -------------------------------------------------------------------------------
    signal   S_AXI_AWADDR    : std_logic_vector(WIDTH.AWADDR -1 downto 0);
    signal   S_AXI_AWLEN     : std_logic_vector(WIDTH.ALEN   -1 downto 0);
    signal   S_AXI_AWSIZE    : AXI4_ASIZE_TYPE;
    signal   S_AXI_AWBURST   : AXI4_ABURST_TYPE;
    signal   S_AXI_AWLOCK    : std_logic_vector(WIDTH.ALOCK  -1 downto 0);
    signal   S_AXI_AWCACHE   : AXI4_ACACHE_TYPE;
    signal   S_AXI_AWPROT    : AXI4_APROT_TYPE;
    signal   S_AXI_AWQOS     : AXI4_AQOS_TYPE;
    signal   S_AXI_AWREGION  : AXI4_AREGION_TYPE;
    signal   S_AXI_AWUSER    : std_logic_vector(WIDTH.AWUSER -1 downto 0);
    signal   S_AXI_AWID      : std_logic_vector(WIDTH.ID     -1 downto 0);
    signal   S_AXI_AWVALID   : std_logic;
    signal   S_AXI_AWREADY   : std_logic;
    -------------------------------------------------------------------------------
    -- ライトデータチャネルシグナル.
    -------------------------------------------------------------------------------
    signal   S_AXI_WLAST     : std_logic;
    signal   S_AXI_WDATA     : std_logic_vector(WIDTH.WDATA  -1 downto 0);
    signal   S_AXI_WSTRB     : std_logic_vector(WIDTH.WDATA/8-1 downto 0);
    signal   S_AXI_WUSER     : std_logic_vector(WIDTH.WUSER  -1 downto 0);
    signal   S_AXI_WID       : std_logic_vector(WIDTH.ID     -1 downto 0);
    signal   S_AXI_WVALID    : std_logic;
    signal   S_AXI_WREADY    : std_logic;
    -------------------------------------------------------------------------------
    -- ライト応答チャネルシグナル.
    -------------------------------------------------------------------------------
    signal   S_AXI_BRESP     : AXI4_RESP_TYPE;
    signal   S_AXI_BUSER     : std_logic_vector(WIDTH.BUSER  -1 downto 0);
    signal   S_AXI_BID       : std_logic_vector(WIDTH.ID     -1 downto 0);
    signal   S_AXI_BVALID    : std_logic;
    signal   S_AXI_BREADY    : std_logic;
    -------------------------------------------------------------------------------
    -- シンクロ用信号
    -------------------------------------------------------------------------------
    signal   SYNC            : SYNC_SIG_VECTOR (SYNC_WIDTH   -1 downto 0);
    -------------------------------------------------------------------------------
    -- GPIO(General Purpose Input/Output)
    -------------------------------------------------------------------------------
    signal   M_GPI           : std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal   M_GPO           : std_logic_vector(GPO_WIDTH    -1 downto 0);
    -------------------------------------------------------------------------------
    -- 各種状態出力.
    -------------------------------------------------------------------------------
    signal   N_REPORT        : REPORT_STATUS_TYPE;
    signal   M_REPORT        : REPORT_STATUS_TYPE;
    signal   N_FINISH        : std_logic;
    signal   M_FINISH        : std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    component axi_slave_bfm
        generic (
            C_S_AXI_ID_WIDTH         : integer := 1;
            C_S_AXI_ADDR_WIDTH       : integer := 32;
            C_S_AXI_DATA_WIDTH       : integer := 32;
            C_S_AXI_AWUSER_WIDTH     : integer := 1;
            C_S_AXI_ARUSER_WIDTH     : integer := 1;
            C_S_AXI_WUSER_WIDTH      : integer := 1;
            C_S_AXI_RUSER_WIDTH      : integer := 1;
            C_S_AXI_BUSER_WIDTH      : integer := 1;
            C_S_AXI_TARGET           : integer := 0;
            C_OFFSET_WIDTH           : integer := 10;
            C_S_AXI_BURST_LEN        : integer := 256;
            WRITE_RANDOM_WAIT        : integer := 1;
            READ_RANDOM_WAIT         : integer := 0;
            READ_DATA_IS_INCREMENT   : integer := 0;
            RANDOM_BVALID_WAIT       : integer := 0;
            RAM_INIT_FILE            : string  ;
            LOAD_RAM_INIT_FILE       : integer := 0 
        );
        port(
            -- System Signals
            ACLK           : in  std_logic;
            ARESETN        : in  std_logic;

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
            S_AXI_WDATA    : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_WSTRB    : in  std_logic_vector(C_S_AXI_DATA_WIDTH/8-1 downto 0);
            S_AXI_WLAST    : in  std_logic;
            S_AXI_WUSER    : in  std_logic_vector(C_S_AXI_WUSER_WIDTH-1 downto 0);
            S_AXI_WVALID   : in  std_logic;
            S_AXI_WREADY   : out std_logic;
        
            -- Master Interface Write Response Ports
            S_AXI_BID      : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
            S_AXI_BRESP    : out std_logic_vector(2-1 downto 0);
            S_AXI_BUSER    : out std_logic_vector(C_S_AXI_BUSER_WIDTH-1 downto 0);
            S_AXI_BVALID   : out std_logic;
            S_AXI_BREADY   : in  std_logic;

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
            S_AXI_RID      : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
            S_AXI_RDATA    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_RRESP    : out std_logic_vector(2-1 downto 0);
            S_AXI_RLAST    : out std_logic;
            S_AXI_RUSER    : out std_logic_vector(C_S_AXI_RUSER_WIDTH-1 downto 0);
            S_AXI_RVALID   : out std_logic;
            S_AXI_RREADY   : in  std_logic
            );
    end component;
begin    
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    N: MARCHAL
        generic map(
            SCENARIO_FILE   => SCENARIO_FILE,
            NAME            => "MARCHAL",
            SYNC_PLUG_NUM   => 1,
            SYNC_WIDTH      => SYNC_WIDTH,
            FINISH_ABORT    => FALSE
        )
        port map(
            CLK             => ACLK            , -- In  :
            RESET           => RESET           , -- In  :
            SYNC(0)         => SYNC(0)         , -- I/O :
            SYNC(1)         => SYNC(1)         , -- I/O :
            REPORT_STATUS   => N_REPORT        , -- Out :
            FINISH          => N_FINISH          -- Out :
        );
    ------------------------------------------------------------------------------
    -- 
    ------------------------------------------------------------------------------
    M: AXI4_MASTER_PLAYER
        generic map (
            SCENARIO_FILE   => SCENARIO_FILE   ,
            NAME            => "MASTER"        ,
            READ_ENABLE     => TRUE            ,
            WRITE_ENABLE    => TRUE            ,
            OUTPUT_DELAY    => DELAY           ,
            WIDTH           => WIDTH           ,
            SYNC_PLUG_NUM   => 2               ,
            SYNC_WIDTH      => SYNC_WIDTH      ,
            GPI_WIDTH       => GPI_WIDTH       ,
            GPO_WIDTH       => GPO_WIDTH       ,
            FINISH_ABORT    => FALSE
        )
        port map(
        ---------------------------------------------------------------------------
        -- グローバルシグナル.
        ---------------------------------------------------------------------------
            ACLK            => ACLK            , -- In  :
            ARESETn         => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- リードアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            ARADDR          => S_AXI_ARADDR    , -- I/O : 
            ARLEN           => S_AXI_ARLEN     , -- I/O : 
            ARSIZE          => S_AXI_ARSIZE    , -- I/O : 
            ARBURST         => S_AXI_ARBURST   , -- I/O : 
            ARLOCK          => S_AXI_ARLOCK    , -- I/O : 
            ARCACHE         => S_AXI_ARCACHE   , -- I/O : 
            ARPROT          => S_AXI_ARPROT    , -- I/O : 
            ARQOS           => S_AXI_ARQOS     , -- I/O : 
            ARREGION        => S_AXI_ARREGION  , -- I/O : 
            ARUSER          => S_AXI_ARUSER    , -- I/O : 
            ARID            => S_AXI_ARID      , -- I/O : 
            ARVALID         => S_AXI_ARVALID   , -- I/O : 
            ARREADY         => S_AXI_ARREADY   , -- In  :    
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST           => S_AXI_RLAST     , -- In  :    
            RDATA           => S_AXI_RDATA     , -- In  :    
            RRESP           => S_AXI_RRESP     , -- In  :    
            RUSER           => S_AXI_RUSER     , -- In  :    
            RID             => S_AXI_RID       , -- In  :    
            RVALID          => S_AXI_RVALID    , -- In  :    
            RREADY          => S_AXI_RREADY    , -- I/O : 
        --------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        --------------------------------------------------------------------------
            AWADDR          => S_AXI_AWADDR    , -- I/O : 
            AWLEN           => S_AXI_AWLEN     , -- I/O : 
            AWSIZE          => S_AXI_AWSIZE    , -- I/O : 
            AWBURST         => S_AXI_AWBURST   , -- I/O : 
            AWLOCK          => S_AXI_AWLOCK    , -- I/O : 
            AWCACHE         => S_AXI_AWCACHE   , -- I/O : 
            AWPROT          => S_AXI_AWPROT    , -- I/O : 
            AWQOS           => S_AXI_AWQOS     , -- I/O : 
            AWREGION        => S_AXI_AWREGION  , -- I/O : 
            AWUSER          => S_AXI_AWUSER    , -- I/O : 
            AWID            => S_AXI_AWID      , -- I/O : 
            AWVALID         => S_AXI_AWVALID   , -- I/O : 
            AWREADY         => S_AXI_AWREADY   , -- In  :    
        --------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        --------------------------------------------------------------------------
            WLAST           => S_AXI_WLAST     , -- I/O : 
            WDATA           => S_AXI_WDATA     , -- I/O : 
            WSTRB           => S_AXI_WSTRB     , -- I/O : 
            WUSER           => S_AXI_WUSER     , -- I/O : 
            WID             => S_AXI_WID       , -- I/O : 
            WVALID          => S_AXI_WVALID    , -- I/O : 
            WREADY          => S_AXI_WREADY    , -- In  :    
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP           => S_AXI_BRESP     , -- In  :    
            BUSER           => S_AXI_BUSER     , -- In  :    
            BID             => S_AXI_BID       , -- In  :    
            BVALID          => S_AXI_BVALID    , -- In  :    
            BREADY          => S_AXI_BREADY    , -- I/O : 
        --------------------------------------------------------------------------
        -- シンクロ用信号
        --------------------------------------------------------------------------
            SYNC(0)         => SYNC(0)         , -- I/O :
            SYNC(1)         => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI             => M_GPI           , -- In  :
            GPO             => M_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS   => M_REPORT        , -- Out :
            FINISH          => M_FINISH          -- Out :
        );
    ------------------------------------------------------------------------------
    -- 
    ------------------------------------------------------------------------------
    DUT: axi_slave_bfm
        generic map (
            C_S_AXI_ID_WIDTH         => WIDTH.ID,
            C_S_AXI_ADDR_WIDTH       => WIDTH.ARADDR,
            C_S_AXI_DATA_WIDTH       => WIDTH.RDATA,
            C_S_AXI_AWUSER_WIDTH     => WIDTH.AWUSER,
            C_S_AXI_ARUSER_WIDTH     => WIDTH.ARUSER,
            C_S_AXI_WUSER_WIDTH      => WIDTH.WUSER,
            C_S_AXI_RUSER_WIDTH      => WIDTH.RUSER,
            C_S_AXI_BUSER_WIDTH      => WIDTH.BUSER,
            C_S_AXI_TARGET           => 0,
            C_OFFSET_WIDTH           => 10,
            C_S_AXI_BURST_LEN        => 256,
            WRITE_RANDOM_WAIT        => 1,
            READ_RANDOM_WAIT         => 1,
            READ_DATA_IS_INCREMENT   => 0,
            RANDOM_BVALID_WAIT       => 0,
            RAM_INIT_FILE            => RAM_INIT_FILE,
            LOAD_RAM_INIT_FILE       => 1
        ) 
        port map(
            -- System Signals
            ACLK           => ACLK           , -- In  :
            ARESETN        => ARESETN        , -- In  :

            -- Master Interface Write Address Ports
            S_AXI_AWID     => S_AXI_AWID     , -- In  :
            S_AXI_AWADDR   => S_AXI_AWADDR   , -- In  :
            S_AXI_AWLEN    => S_AXI_AWLEN    , -- In  :
            S_AXI_AWSIZE   => S_AXI_AWSIZE   , -- In  :
            S_AXI_AWBURST  => S_AXI_AWBURST  , -- In  :
            -- S_AXI_AWLOCK   : in  std_logic_vector(2-1 downto 0);
            S_AXI_AWLOCK   => S_AXI_AWLOCK   , -- In  :
            S_AXI_AWCACHE  => S_AXI_AWCACHE  , -- In  :
            S_AXI_AWPROT   => S_AXI_AWPROT   , -- In  :
            S_AXI_AWQOS    => S_AXI_AWQOS    , -- In  :
            S_AXI_AWUSER   => S_AXI_AWUSER   , -- In  :
            S_AXI_AWVALID  => S_AXI_AWVALID  , -- In  :
            S_AXI_AWREADY  => S_AXI_AWREADY  , -- Out :

            -- Master Interface Write Data Ports
            S_AXI_WDATA    => S_AXI_WDATA    , -- In  :
            S_AXI_WSTRB    => S_AXI_WSTRB    , -- In  :
            S_AXI_WLAST    => S_AXI_WLAST    , -- In  :
            S_AXI_WUSER    => S_AXI_WUSER    , -- In  :
            S_AXI_WVALID   => S_AXI_WVALID   , -- In  :
            S_AXI_WREADY   => S_AXI_WREADY   , -- Out :
        
            -- Master Interface Write Response Ports
            S_AXI_BID      => S_AXI_BID      , -- Out :
            S_AXI_BRESP    => S_AXI_BRESP    , -- Out :
            S_AXI_BUSER    => S_AXI_BUSER    , -- Out :
            S_AXI_BVALID   => S_AXI_BVALID   , -- Out :
            S_AXI_BREADY   => S_AXI_BREADY   , -- In  :

            -- Master Interface Read Address Ports
            S_AXI_ARID     => S_AXI_ARID     , -- In  :
            S_AXI_ARADDR   => S_AXI_ARADDR   , -- In  :
            S_AXI_ARLEN    => S_AXI_ARLEN    , -- In  :
            S_AXI_ARSIZE   => S_AXI_ARSIZE   , -- In  :
            S_AXI_ARBURST  => S_AXI_ARBURST  , -- In  :
            S_AXI_ARLOCK   => S_AXI_ARLOCK   , -- In  :
            S_AXI_ARCACHE  => S_AXI_ARCACHE  , -- In  :
            S_AXI_ARPROT   => S_AXI_ARPROT   , -- In  :
            S_AXI_ARQOS    => S_AXI_ARQOS    , -- In  :
            S_AXI_ARUSER   => S_AXI_ARUSER   , -- In  :
            S_AXI_ARVALID  => S_AXI_ARVALID  , -- In  :
            S_AXI_ARREADY  => S_AXI_ARREADY  , -- Out :

            -- Master Interface Read Data Ports
            S_AXI_RID      => S_AXI_RID      , -- Out :
            S_AXI_RDATA    => S_AXI_RDATA    , -- Out :
            S_AXI_RRESP    => S_AXI_RRESP    , -- Out :
            S_AXI_RLAST    => S_AXI_RLAST    , -- Out :
            S_AXI_RUSER    => S_AXI_RUSER    , -- Out :
            S_AXI_RVALID   => S_AXI_RVALID   , -- Out :
            S_AXI_RREADY   => S_AXI_RREADY     -- In  :
        );
    -------------------------------------------------------------------------------
    -- AXI4_SIGNAL_PRINTER
    -------------------------------------------------------------------------------
    PRINT: AXI4_SIGNAL_PRINTER
        generic map (
            NAME            => NAME,
            TAG             => NAME,
            TAG_WIDTH       => 0,
            TIME_WIDTH      => 13,
            WIDTH           => WIDTH,
            READ_ENABLE     => TRUE,
            WRITE_ENABLE    => TRUE
        )
        port map (
        ---------------------------------------------------------------------------
        -- グローバルシグナル.
        ---------------------------------------------------------------------------
            ACLK            => ACLK            , -- In  :
            ARESETn         => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- リードアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            ARADDR          => S_AXI_ARADDR    , -- In  :
            ARLEN           => S_AXI_ARLEN     , -- In  :
            ARSIZE          => S_AXI_ARSIZE    , -- In  :
            ARBURST         => S_AXI_ARBURST   , -- In  :
            ARLOCK          => S_AXI_ARLOCK    , -- In  :
            ARCACHE         => S_AXI_ARCACHE   , -- In  :
            ARPROT          => S_AXI_ARPROT    , -- In  :
            ARQOS           => S_AXI_ARQOS     , -- In  :
            ARREGION        => S_AXI_ARREGION  , -- In  :
            ARUSER          => S_AXI_ARUSER    , -- In  :
            ARID            => S_AXI_ARID      , -- In  :
            ARVALID         => S_AXI_ARVALID   , -- In  :
            ARREADY         => S_AXI_ARREADY   , -- In  :
        ---------------------------------------------------------------------------
        -- リードチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST           => S_AXI_RLAST     , -- In  :
            RDATA           => S_AXI_RDATA     , -- In  :
            RRESP           => S_AXI_RRESP     , -- In  :
            RUSER           => S_AXI_RUSER     , -- In  :
            RID             => S_AXI_RID       , -- In  :
            RVALID          => S_AXI_RVALID    , -- In  :
            RREADY          => S_AXI_RREADY    , -- In  :
        ---------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            AWADDR          => S_AXI_AWADDR    , -- In  :
            AWLEN           => S_AXI_AWLEN     , -- In  :
            AWSIZE          => S_AXI_AWSIZE    , -- In  :
            AWBURST         => S_AXI_AWBURST   , -- In  :
            AWLOCK          => S_AXI_AWLOCK    , -- In  :
            AWCACHE         => S_AXI_AWCACHE   , -- In  :
            AWPROT          => S_AXI_AWPROT    , -- In  :
            AWQOS           => S_AXI_AWQOS     , -- In  :
            AWREGION        => S_AXI_AWREGION  , -- In  :
            AWUSER          => S_AXI_AWUSER    , -- In  :
            AWID            => S_AXI_AWID      , -- In  :
            AWVALID         => S_AXI_AWVALID   , -- In  :
            AWREADY         => S_AXI_AWREADY   , -- In  :
        ---------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        ---------------------------------------------------------------------------
            WLAST           => S_AXI_WLAST     , -- In  :
            WDATA           => S_AXI_WDATA     , -- In  :
            WSTRB           => S_AXI_WSTRB     , -- In  :
            WUSER           => S_AXI_WUSER     , -- In  :
            WID             => S_AXI_WID       , -- In  :
            WVALID          => S_AXI_WVALID    , -- In  :
            WREADY          => S_AXI_WREADY    , -- In  :
        ---------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        ---------------------------------------------------------------------------
            BRESP           => S_AXI_BRESP     , -- In  :
            BUSER           => S_AXI_BUSER     , -- In  :
            BID             => S_AXI_BID       , -- In  :
            BVALID          => S_AXI_BVALID    , -- In  :
            BREADY          => S_AXI_BREADY      -- In  :
    );

    process begin
        ACLK <= '1';
        wait for PERIOD / 2;
        ACLK <= '0';
        wait for PERIOD / 2;
    end process;

    ARESETn <= '1' when (RESET = '0') else '0';
    M_GPI   <= M_GPO;

    process
        variable L   : LINE;
        constant T   : STRING(1 to 7) := "  ***  ";
    begin
        wait until (N_FINISH'event and N_FINISH = '1');
        wait for DELAY;
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "ERROR REPORT " & NAME);                          WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ MASTER ]");                                    WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,M_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,M_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,M_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        assert FALSE report "Simulation complete." severity FAILURE;
        wait;
    end process;
end MODEL;
