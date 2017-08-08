class CreateWeights < ActiveRecord::Migration[5.1]
  def change
    create_table :weights do |t|
      t.date :date
      t.decimal :mcap_btc
      t.decimal :mcap_eth
      t.decimal :mcap_ltc
      t.decimal :total_mcap
      t.decimal :btc_pct
      t.decimal :eth_pct
      t.decimal :ltc_pct
      t.decimal :btc_wgt
      t.decimal :eth_wgt
      t.decimal :ltc_wgt
      t.decimal :total_wgt

      t.timestamps
    end
  end
end
