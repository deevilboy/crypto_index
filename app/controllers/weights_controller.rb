# encoding: UTF-8
require 'rubygems'
require 'nokogiri'
require 'open-uri'

require 'bundler/setup'
require 'to_xls'


class WeightsController < ApplicationController
  before_action :set_weight, only: [:show, :edit, :update, :destroy]

  # GET /weights
  # GET /weights.json
  def index

    ### Global Variables ###
   

    ######################### Part 1) BTC ############################
    #Initialize Variables
    btc_cnt = 0
    btc_date_arr = []
    btc_mcap_arr = []
    btc_hash = {}

    #Use Nokogiri Webscraper to filter website table via xpath
    doc = Nokogiri::HTML(open("https://coinmarketcap.com/currencies/bitcoin/historical-data/?start=20170101&end=20170807"))   

    # Store Date and Mcap in seperate arrays, then merge these two arrays into a hash
    doc.xpath('//*/table/tbody/tr[@class=\'text-right\']').each do |tr_child|
        btc_date_arr[btc_cnt] = tr_child.xpath('td[@class=\'text-left\']').text
        btc_mcap_arr [btc_cnt] = tr_child.xpath('td')[6].text.delete(',').to_i
        btc_cnt = btc_cnt + 1
    end
      #reverse arrays since dates/data is downloaded newest to oldest
      btc_date_arr = btc_date_arr.reverse
      btc_mcap_arr = btc_mcap_arr.reverse

    #create hash of date and mcap arrays
    btc_hash = Hash[btc_date_arr.zip(btc_mcap_arr)] 
    


    ######################### Part 2) ETH ############################
    #Initialize Variables
    eth_cnt = 0
    eth_date_arr = []
    eth_mcap_arr = []
    eth_hash = {}

    #Use Nokogiri Webscraper to filter website table via xpath
    doc = Nokogiri::HTML(open("https://coinmarketcap.com/currencies/ethereum/historical-data/?start=20170101&end=20170807"))   

    # Store Date and Mcap in seperate arrays, then merge these two arrays into a hash
    doc.xpath('//*/table/tbody/tr[@class=\'text-right\']').each do |tr_child|
        eth_date_arr[eth_cnt] = tr_child.xpath('td[@class=\'text-left\']').text
        eth_mcap_arr [eth_cnt] = tr_child.xpath('td')[6].text.delete(',').to_i
        eth_cnt = eth_cnt + 1
    end
    
      #reverse arrays since dates/data is downloaded newest to oldest
      eth_date_arr = eth_date_arr.reverse
      eth_mcap_arr = eth_mcap_arr.reverse

    #create hash of date and mcap arrays
    eth_hash = Hash[eth_date_arr.zip(eth_mcap_arr)] 
  


    ######################### Part 3) LTC ############################
    
    #Initialize Variables
    ltc_cnt = 0
    ltc_date_arr = []
    ltc_mcap_arr = []
    ltc_hash = {}

    #Use Nokogiri Webscraper to filter website table via xpath
    doc = Nokogiri::HTML(open("https://coinmarketcap.com/currencies/litecoin/historical-data/?start=20170101&end=20170807"))   

    # Store Date and Mcap in seperate arrays, then merge these two arrays into a hash
    doc.xpath('//*/table/tbody/tr[@class=\'text-right\']').each do |tr_child|
        ltc_date_arr[ltc_cnt] = tr_child.xpath('td[@class=\'text-left\']').text
        ltc_mcap_arr [ltc_cnt] = tr_child.xpath('td')[6].text.delete(',').to_i
        ltc_cnt = ltc_cnt + 1
    end
    
      #reverse arrays since dates/data is downloaded newest to oldest
      ltc_date_arr = ltc_date_arr.reverse
      ltc_mcap_arr = ltc_mcap_arr.reverse

    #create hash of date and mcap arrays
    ltc_hash = Hash[ltc_date_arr.zip(ltc_mcap_arr)] 
    

    
    ############### Section A) Calculate MCap Weighted Index #################
    date_arr = []    
    total_mcap_arr = []
    hash_size = btc_date_arr.size
    date_arr = btc_date_arr
    return_arr = []      #note: returns will lag by one day as you can't calculate return for the 1st index price

      # Calc total coin mcap - sum the integers in each array (weird ruby syntax)
      total_mcap_arr = [btc_mcap_arr, eth_mcap_arr, ltc_mcap_arr].transpose.map {|x| x.reduce(:+)}
      
      # Calc percent contribution to mcap weight for each coin
      btc_pct_arr = btc_mcap_arr.zip(total_mcap_arr).map{|x, y| (x.to_f / y) }
      eth_pct_arr = eth_mcap_arr.zip(total_mcap_arr).map{|x, y| (x.to_f / y) }
      ltc_pct_arr = ltc_mcap_arr.zip(total_mcap_arr).map{|x, y| (x.to_f / y) }

      # Calc "weight" of each coin to index
      btc_wgt_arr = btc_pct_arr.zip(btc_mcap_arr).map{|x, y| (x.to_f * y) }
      eth_wgt_arr = eth_pct_arr.zip(eth_mcap_arr).map{|x, y| (x.to_f * y) }
      ltc_wgt_arr = ltc_pct_arr.zip(ltc_mcap_arr).map{|x, y| (x.to_f * y) }

      # Calc Index Price (sum of "weights" of all coins)
      index_price_arr = [btc_wgt_arr, eth_wgt_arr, ltc_wgt_arr].transpose.map {|x| x.reduce(:+)}

      #Create Hash with date and index total weight
      @index_date_price_hash = Hash[date_arr.zip(index_price_arr)] 

      #Calc % change in Index Price
      # return_arr[0] = 0      # first index price has no return associated w/it (hard code this)
      for i in 1..index_price_arr.size-1
        return_arr[i] = ((index_price_arr[i] / index_price_arr[i-1])-1)*100
      end


      #Append Index Hash with percent change calculation
      # index_date_price_hash.each { |x| 
      #   x << 

      # }

      counter = 0

      tmp_hash = {}
      tmp = 0
      @index_date_price_hash.each do |key, value|
        tmp = @index_date_price_hash[key] 
        @index_date_price_hash[key] = []
        @index_date_price_hash[key].push([value,return_arr[counter]])
        counter = counter + 1

      end
        

# byebug







  # @index_date_price_hash.each do |id, sub_hash|
  #   puts "id:"
  #   puts id
  #   sub_hash.each do |key, value|
  #   puts key
  #   puts value
  #   end
  # end


# byebug





#Testing
# puts "tmp_date_arr: "
# puts tmp_date_arr
# puts "tmp_mcap_arr: "
# puts tmp_mcap_arr
# puts "master_hash"
# puts master_hash

# tmp_date_arr.map {|i| i.include?(',') ? (i.split /, //) : i}
# Hash[tmp_date_arr.zip(tmp_mcap_arr.map {|i| i.include?(',') ? (i.split /, //) : i})]

# Get 3rd node 
#****(/table[@class='attributes']//td[@class='value'])[2] *****
# arry_dates = []
# doc.xpath('/*/table[@class='table']//tbody/tr[@class='text-right']').each do |tr_node|
# end

    @weights = Weight.all
  end

  # GET /weights/1
  # GET /weights/1.json
  def show
  end

  # GET /weights/new
  def new
    @weight = Weight.new
  end

  # GET /weights/1/edit
  def edit
  end

  # POST /weights
  # POST /weights.json
  def create
    @weight = Weight.new(weight_params)

    respond_to do |format|
      if @weight.save
        format.html { redirect_to @weight, notice: 'Weight was successfully created.' }
        format.json { render :show, status: :created, location: @weight }
      else
        format.html { render :new }
        format.json { render json: @weight.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /weights/1
  # PATCH/PUT /weights/1.json
  def update
    respond_to do |format|
      if @weight.update(weight_params)
        format.html { redirect_to @weight, notice: 'Weight was successfully updated.' }
        format.json { render :show, status: :ok, location: @weight }
      else
        format.html { render :edit }
        format.json { render json: @weight.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /weights/1
  # DELETE /weights/1.json
  def destroy
    @weight.destroy
    respond_to do |format|
      format.html { redirect_to weights_url, notice: 'Weight was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_weight
      @weight = Weight.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def weight_params
      params.require(:weight).permit(:date, :mcap_btc, :mcap_eth, :mcap_ltc, :total_mcap, :btc_pct, :eth_pct, :ltc_pct, :btc_wgt, :eth_wgt, :ltc_wgt, :total_wgt)
    end
end
