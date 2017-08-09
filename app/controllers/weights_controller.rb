# encoding: UTF-8
require 'rubygems'
require 'nokogiri'
require 'open-uri'

require 'bundler/setup'
require 'to_xls'

require 'date'


#Module to calculate Standard Deviation
module Enumerable
    def sum
      self.inject(0){|accum, i| accum + i }
    end

    def mean
      self.sum/self.length.to_f
    end

    def sample_variance
      m = self.mean
      sum = self.inject(0){|accum, i| accum +(i-m)**2 }
      sum/(self.length - 1).to_f
    end

    def standard_deviation
      return Math.sqrt(self.sample_variance)
    end
end 


class WeightsController < ApplicationController
  before_action :set_weight, only: [:show, :edit, :update, :destroy]

  # GET /weights
  # GET /weights.json
  def index

    ### Global Variables ###
   

    ######################### Part 1) Scrape BTC Data ############################
    #Initialize Variables
    btc_cnt = 0
    btc_date_arr = []
    btc_mcap_arr = []
    btc_hash = {}
    start_date = 0
    end_date = 0      #specify what the end date for the scraping is. This will be set to today's current date

    #Dynamically store today's end date => use this in the URL to scrap
    start_date = params[:start_date] #value from the index view link

    # start_date = 20170101
    end_date = Time.now.strftime("%Y%m%d")
    # end_date = 20170801


    #Use Nokogiri Webscraper to filter website table via xpath
    doc = Nokogiri::HTML(open("https://coinmarketcap.com/currencies/bitcoin/historical-data/?start=#{start_date}&end=#{end_date}"))   

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
    


    ######################### Part 2) Scrape ETH Data ############################
    #Initialize Variables
    eth_cnt = 0
    eth_date_arr = []
    eth_mcap_arr = []
    eth_hash = {}

    #Use Nokogiri Webscraper to filter website table via xpath
    doc = Nokogiri::HTML(open("https://coinmarketcap.com/currencies/ethereum/historical-data/?start=#{start_date}&end=#{end_date}"))   

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
  


    ######################### Part 3) Scrap LTC Data ############################
    
    #Initialize Variables
    ltc_cnt = 0
    ltc_date_arr = []
    ltc_mcap_arr = []
    ltc_hash = {}

    #Use Nokogiri Webscraper to filter website table via xpath
    doc = Nokogiri::HTML(open("https://coinmarketcap.com/currencies/litecoin/historical-data/?start=#{start_date}&end=#{end_date}"))   

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

      # Normalize the Index so that in day 1 it equals 100; 
      # To Normalize divide all index price values by 1/100 of the day 1 index price
      normalization_factor = index_price_arr[0].to_i / 100   # find day 1 index price (use this as normalization factor)
      puts "normalization factor: "
      puts normalization_factor
      index_price_arr.map! { |x| x / normalization_factor} 

      #Create Hash with date and index total weight
      @index_date_price_hash = Hash[date_arr.zip(index_price_arr)] 

      #Calc % change in Index Price
      return_arr[0] = 0.0           # the first day does NOT HAVE a 1 day return value so set it to 0
      for i in 1..index_price_arr.size-1
        return_arr[i] = ((index_price_arr[i] / index_price_arr[i-1])-1)*100
      end

      #Calculate Avg. Daily Change
      #strip out the first value of return_arr (which is a 0/NIL and should not be used in the calc)
      @avg_daily_chg = 0
      total = return_arr.drop(1).inject(:+)
      length = return_arr.drop(1).length
      puts "total: #{total}"
      puts "length: #{length}"
      @avg_daily_chg = total.to_f / length      #0.6105%

      #Calculate Standard Deviation of % Change (in index price)
      @std_dev_of_pct_chg = 0
      @std_dev_of_pct_chg = return_arr.drop(1).standard_deviation  #4.498%
      

      # In Hash of {date, index_value} replace index value with [index value, 1 day return]
      # So final @index_date_price_hash ==> {date, [index value, 1 day return]}
      counter = 0
      tmp = 0
      @index_date_price_hash.each do |key, value|
        tmp = @index_date_price_hash[key] 
        @index_date_price_hash[key] = []                                  # clear the index_value 
        @index_date_price_hash[key].push([value,return_arr[counter]])     # and replace it w/ [index_value, 1 day return]
        counter = counter + 1
      end
# byebug

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
