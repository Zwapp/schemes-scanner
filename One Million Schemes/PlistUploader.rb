#
#  PlistUploader.rb
#  One Million Schemes
#
#  Created by Josh Kalderimis on 4/19/11.
#  Copyright 2011 Zwapp. All rights reserved.
#
require 'json'

class PlistUploader
  attr_reader :response, :responseBody
  
  def self.start(plistData, twitterName, &block)
    uploader = self.new(&block)
    uploader.start(plistData, twitterName)
  end

  def initialize(&block)
    url = NSURL.URLWithString("http://schemes.zwapp.com/")
    @request = NSMutableURLRequest.requestWithURL(url)
    
    @request.setHTTPMethod("POST")
    
    @request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    @request.addValue("application/json", forHTTPHeaderField: "Accepts")
    
    @callback = block
  end
  
  def start(plistData, twitterName)
    hash = { 
      :plist_submission => {
        :data => plistData
      }
    }
    
    hash[:plist_submission][:twitter_name] = twitterName if twitterName && !twitterName.empty?
    
    json = hash.to_json

    @request.setHTTPBody(json.dataUsingEncoding(NSUTF8StringEncoding))
    
    NSNotificationCenter.defaultCenter.
      postNotificationName("UploadingStarted", object: self, userInfo: {})
    
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
    @callback.call(false, nil) if @callback.respond_to?(:call)
  end
  
  def connectionDidFinishLoading(connection)
    case @response.statusCode
    when 200...300
      NSLog("#{@response.statusCode} - All good in the hood")
      @responseBody = NSString.alloc.initWithData(@downloadData, encoding:NSUTF8StringEncoding)
      parsedBody = JSON.parse(@responseBody)
      submissionId = parsedBody["submission"]["id"]
      @callback.call(true, submissionId) if @callback.respond_to?(:call)
    when 300...400
      NSLog("#{@response.statusCode} - Got a redirect :(") # need to handle it better
    else
      NSLog("#{@response.statusCode} - Uploading the Plist data failed :(")
      @callback.call(false, nil) if @callback.respond_to?(:call)
    end
  end
end
