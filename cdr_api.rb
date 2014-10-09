require 'sinatra'
require 'data_mapper'
require 'json'
require 'net/telnet'

db_user = ENV['asterisk_stats_db_user']
db_pass = ENV['asterisk_stats_db_pass']
db_host = 'localhost'
db_name = 'asteriskcdrdb'

ami_host = 'localhost'
ami_user = 'mark'
ami_pass = '123456'

DataMapper.setup(:default, "mysql://#{db_user}:#{db_pass}@#{db_host}/#{db_name}")

class Cdr
  include DataMapper::Resource
	
  storage_names[:default] = 'cdr'

  property :id,         Serial
  property :calldate, DateTime
  property :clid,  Text
  property :src,  Text
  property :dst,  Text
  property :dcontext,  Text
  property :channel,  Text
  property :dstchannel,  Text
  property :lastapp,  Text
  property :lastdata,  Text
  property :duration,   Integer
  property :billsec,   Integer
  property :disposition,  String
  property :amaflags,   Integer
  property :accountcode,   String
  property :uniqueid,   String
  property :userfield, Text
  property :peeraccount, String
  property :linkedid,  String
  property :sequence,   Integer
end

DataMapper.finalize

class Stat
  attr_accessor :src, :outbound_count, :outbound_total, :outbound_avg, :inbound_count, :inbound_total, :useful_calls, :unnecessary_calls

  def initialize(src, outbound_count = 0, outbound_total = 0, inbound_count = 0, inbound_total = 0, useful_calls = 0, unnecessary_calls = 0)
    self.src = src
    self.outbound_count = outbound_count
    self.outbound_total = outbound_total
    self.outbound_avg = outbound_total / outbound_count if outbound_total
    self.inbound_count = inbound_count
    self.inbound_total = inbound_total
    self.useful_calls = useful_calls
    self.unnecessary_calls = unnecessary_calls
  end
end


get '/' do
  erb :index
end

get '/:ext/?:start?/?:end_time?' do
  content_type :json

  ext = params[:ext]

  if params[:start] && params[:end_time]
    start = params[:start]
    end_time = params[:end_time]
    outbound_total = Cdr.sum(:billsec, src: ext, calldate: (start..end_time))
    outbound_count = Cdr.count(src: ext, calldate: (start..end_time))
    inbound_total = Cdr.sum(:billsec, dst: ext, calldate: (start..end_time))
    inbound_count = Cdr.count(dst: ext, calldate: (start..end_time))
    useful_calls = Cdr.count(:billsec.gt => 30, calldate: (start..end_time))
    unnecessary_calls = Cdr.count(:billsec.lt => 30, calldate: (start..end_time))
  else
    outbound_total = Cdr.sum(:billsec, src: ext)
    outbound_count = Cdr.count(src: ext)
    inbound_total = Cdr.sum(:billsec, dst: ext)
    inbound_count = Cdr.count(dst: ext)
    useful_calls = Cdr.count(:billsec.gt => 30)
    unnecessary_calls = Cdr.count(:billsec.lt => 30)
  end
  stat = Stat.new(ext, outbound_count, outbound_total, inbound_count, inbound_total, useful_calls, unnecessary_calls)

  { src: stat.src,
    outbound_count: stat.outbound_count,
    outbound_total: stat.outbound_total,
    inbound_count: stat.inbound_count,
    inbound_total: stat.inbound_total,
    useful_calls: stat.useful_calls,
    unnecessary_calls: stat.unnecessary_calls }.to_json
end

get '/call/:extension/:destination' do
  host = Net::Telnet::new("Host" => ami_host,
                          "Telnetmode" => false,
                          "Port" => 5038,
                          "Output_log" => "output_log", # default: nil (no output)
                          "Dump_log"   => "dump_log",   # default: nil (no output)
                          )

  host.puts login(ami_user, ami_pass)
  host.puts call(params[:extension],params[:destination])
  host.close
end



private
def login(username,password)
  request = "Action: login\n"
  request += "Username: #{username}\n"
  request += "Secret: #{password}\n"
end

def call(extension,destination)
  request = "Action: originate\n"
  request += "Channel: SIP/#{extension}\n"
  request += "CallerId: #{extension}\n"
  request += "Exten: #{destination}\n"
  request += "Context: from-internal\n"
  request += "Priority: 1\n"
end
