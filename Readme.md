axi_slave_bfm test
------------------

このプロジェクトは FPGAの部屋(http://marsee101.blog19.fc2.com )で活躍されている marsee さんが作った axi_slave_BFM.vhd(http://marsee101.blog19.fc2.com/blog-entry-2644.html) を Vivado 2014.2 でシミュレーションするためのものです。

## シミュレーション方法

### github からリポジトリをダウンロードする.

git clone git://github.com/ikwzm/axi_slave_bfm_test.git axi_slave_bfm_test

### github から Dummy_Plug サブモジュールをダウンロードする.

cd axi_slave_bfm_test

git submodule init

git submodule update

### Vivado でプロジェクトを開く.

Vivado > Open Project > axi_slave_bfm_test/sim/vivado/axi_slave_bfm_test/axi_slave_bfm_test.xpr

### Vivado でシミュレーションを実行する.

Run Simulation > Run Behavioral Simulation

