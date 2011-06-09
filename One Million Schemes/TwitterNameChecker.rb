#
#  TwitterNameChecker.rb
#  One Million Schemes
#
#  Created by Josh Kalderimis on 4/27/11.
#  Copyright 2011 Zwapp. All rights reserved.
#
require 'json'

class TwitterNameChecker
  attr_reader :response, :responseBody
  
  def self.start(twitterName, &block)
    uploader = self.new(twitterName, &block)
    uploader.start
  end

  def initialize(twitterName, &block)
    url = NSURL.URLWithString("https://api.twitter.com/1/users/show.json?screen_name=#{twitterName}")
    @request = NSMutableURLRequest.requestWithURL(url)
  
    @request.setHTTPMethod("GET")
  
    @request.addValue("application/json", forHTTPHeaderField: "Accepts")
  
    @callback = block
  end

  def start
    NSURLConnection.connectionWithRequest(@request, delegate:self)
  end

  def connection(connection, didReceiveResponse:response)
    @response = response
    @downloadData = NSMutableData.data
  end

  def connection(connection, didReceiveData:data)
    @downloadData.appendData(data)
  end

  def connection(connection, didFailWithError: error)
    NSLog("oh no! we gotz an error!")
    NSLog(error.userInfo.inspect)
  end

  def connectionDidFinishLoading(connection)
    case @response.statusCode
    when 200...300
      NSLog("#{@response.statusCode} - All good in the hood")
      @responseBody = NSString.alloc.initWithData(@downloadData, encoding:NSUTF8StringEncoding)
      @callback.call(true) if @callback.respond_to?(:call)
    when 404
      @callback.call(false) if @callback.respond_to?(:call)
    when 300...400
      NSLog("#{@response.statusCode} - Got a redirect :(") # need to handle it better
    else
      NSLog("#{@response.statusCode} - Uploading the Plist data failed :(")
    end
  end
end
