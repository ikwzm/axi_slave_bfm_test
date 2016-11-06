axi_slave_bfm test
------------------

###概要###

このプロジェクトは FPGAの部屋(http://marsee101.blog19.fc2.com )で活躍されている marsee さんが作った axi_slave_BFM.vhd(http://marsee101.blog19.fc2.com/blog-entry-3510.html) または axi_slave_BFM.v(http://marsee101.blog19.fc2.com/blog-entry-3509.html)を Vivado でシミュレーションするためのものです。

###シミュレーション方法###

####1. github からリポジトリをダウンロードする####

git clone git://github.com/ikwzm/axi_slave_bfm_test.git axi_slave_bfm_test

####2. github から Dummy_Plug サブモジュールをダウンロードする####

cd axi_slave_bfm_test

git submodule init

git submodule update

####3. Vivado プロジェクトを作る ####

#####3.1 シナリオ１実行用プロジェクトを作る#####

cd sim/vivado/axi_slave_bfm_test

Vivado > Tools > Run Tcl Script > create_axi_slave_bfm_test_1.tcl

#####3.2 axi_slave_BFM.v の Post-Synthesis シミュレーション実行用プロジェクトを作る#####

cd sim/vivado/axi_slave_bfm_test

Vivado > Tools > Run Tcl Script > create_axi_slave_bfm_v_post_synth_test_1.tcl

####4. Vivado でシミュレーションを実行する####

#####4.1 シナリオ１を実行する#####

Vivado > Open Project > axi_slave_bfm_test_1.xpr

Flow Navigator > Run Simulation > Run Behavioral Simulation      

#####4.2 axi_slave_BFM.v の Post-Synthesis シミュレーションを実行する#####

Vivado > Open Project > axi_slave_bfm_v_post_synth_test_1.xpr

Flow Navigator > Run Synthesis

Flow Navigator > Run Implementation

Flow Navigator > Run Simulation > Run Post-Implementation Functional Simulation

###シミュレーションシナリオ###

axi_slave_bfm_test.snr にテスト用シナリオが記述されています。   

~~現時点では axi_slave_BFM がマスターからのBREADY信号をチェックしていない事を突いた意地悪なシナリオを仕込んでいます。~~
2014年7月17日時点では marsee さんによりこの不具合は修正されています。

###ライセンス###

axi_slave_BFM.vhd および sync_fifo.vhd の使用に関しては、FPGAの部屋(http://marsee101.blog19.fc2.com/blog-entry-2862.html )で確認してください。

Dummy_Plug および axi_slave_bfm_test_bench.vhd に関しては、二条項BSDライセンス (2-clause BSD license) で公開しています。
