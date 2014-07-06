axi_slave_bfm test
------------------

###概要###

このプロジェクトは FPGAの部屋(http://marsee101.blog19.fc2.com )で活躍されている marsee さんが作った axi_slave_BFM.vhd(http://marsee101.blog19.fc2.com/blog-entry-2644.html) を Vivado 2014.2 でシミュレーションするためのものです。

###シミュレーション方法###

####1. github からリポジトリをダウンロードする####

git clone git://github.com/ikwzm/axi_slave_bfm_test.git axi_slave_bfm_test

####2. github から Dummy_Plug サブモジュールをダウンロードする####

cd axi_slave_bfm_test

git submodule init

git submodule update

####3. Vivado でプロジェクトを開く####

Vivado > Open Project > axi_slave_bfm_test/sim/vivado/axi_slave_bfm_test/axi_slave_bfm_test.xpr

####4. Vivado でシミュレーションを実行する####

Run Simulation > Run Behavioral Simulation


###シミュレーションシナリオ###

axi_slave_bfm_test.snr にテスト用シナリオが記述されています。   

現時点では axi_slave_BFM がマスターからのBREADY信号をチェックしていない事を突いた意地悪なシナリオを仕込んでいます。

###ライセンス###

axi_slave_BFM.vhd および sync_fifo.vhd の使用に関しては、FPGAの部屋(http://marsee101.blog19.fc2.com/blog-entry-2862.html )で確認してください。

Dummy_Plug および axi_slave_bfm_test_bench.vhd に関しては、二条項BSDライセンス (2-clause BSD license) で公開しています。
