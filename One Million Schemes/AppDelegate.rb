#
#  AppDelegate.rb
#  One Million Schemes
#
#  Created by Josh Kalderimis on 4/19/11.
#  Copyright 2011 Zwapp. All rights reserved.
#

class AppDelegate
  attr_accessor :window, :twitterPromptWindow
  
  attr_accessor :mainText, :secondaryText
  attr_accessor :progressIndicator, :startButton, :statusLabel
  attr_accessor :twitterName, :errorLabel
  
  attr_accessor :notificationCenter
  
  attr_accessor :submissionId
  
  NOTIFICATION_TYPES = ["appsFound", "processingFinished", "uploadingStarted", "uploadingFinished"]
  
  def applicationDidFinishLaunching(notification)
    setupNotificationsObservers
  end
  
  def setupNotificationsObservers
    @notificationCenter = NSNotificationCenter.defaultCenter
    
    NOTIFICATION_TYPES.each do |name|
      addNotificationObserver(name)
    end
  end
  
  def addNotificationObserver(name)
    titleized = name[0].capitalize + name[1..-1]
    @notificationCenter.addObserver(self, selector: "#{name}:", name: titleized, object: nil)
  end
  
  def startUpload(sender)
    increaseFrameSize
    
    toggleUIState
    
    IpaProcessor.updateApps do |appList|
      if appList.empty?
        showNoAppsFoundSheet
      else
        @recentAppList = appList
        promptForTwitterName
      end
    end
  end
  
  def openSubmissionResults(sender)
    NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString("http://schemes.zwapp.com/#{self.submissionId}"))
  end
  
  def promptForTwitterName
    NSApp.beginSheet(twitterPromptWindow, 
                     modalForWindow: window,
                     modalDelegate: self,
                     didEndSelector: "didEndSheet:returnCode:contextInfo:",
                     contextInfo: nil)
  end
  
  def uploadWithoutTwitterName(sender)
    NSApp.endSheet(twitterPromptWindow)
    uploadAppList(nil)
  end
  
  def uploadWithTwitterName(sender)
    NSApp.endSheet(twitterPromptWindow)
    twitterName = self.twitterName.stringValue
    TwitterNameChecker.start(twitterName) do |valid|
      if valid
        uploadAppList(twitterName)
      else
        self.errorLabel.stringValue = "can't seem to find it"
        promptForTwitterName
      end
    end
  end
  
  def didEndSheet(sheet, returnCode: returnCode, contextInfo: contextInfo)
    sheet.orderOut(self)
  end
  
  def uploadAppList(twitterName)
    PlistUploader.start(@recentAppList, twitterName) do |success, submissionId|
      if success
        self.submissionId = submissionId
        @notificationCenter.postNotificationName("UploadingFinished", object: self)
        toggleUIState
        reduceFrameSize
      else
        showUploadFailedSheet
      end
    end
  end
  
  def showNoAppsFoundSheet
    alert = NSAlert.alertWithMessageText("Sorry but we couldn't find any apps",
                                         defaultButton: nil,
                                         alternateButton: nil,
                                         otherButton: nil,
                                         informativeTextWithFormat: "Sadly we couldn't find any apps in the standard iTunes directory path, have your syncd your iOS device with this computer? If you have, please email contact@zwapp.com so we can improve the scanner.")
    
    alert.beginSheetModalForWindow(self.window, modalDelegate:self, didEndSelector:"noAppsFoundAlertDidEnd:returnCode:contextInfo:", contextInfo:nil)
  end
  
  def noAppsFoundAlertDidEnd(alert, returnCode: returnCode, contextInfo: contextInfo)
    resetUI
  end
  
  def showUploadFailedSheet
    alert = NSAlert.alertWithMessageText("Sorry but there was an error completing the scan",
                                         defaultButton: nil,
                                         alternateButton: nil,
                                         otherButton: nil,
                                         informativeTextWithFormat: "There was an error while uploading the app scheme data, if you continue to experience a problem please email contact@zwapp.com")
    
    alert.beginSheetModalForWindow(self.window, modalDelegate:self, didEndSelector:"uploadFailedAlertDidEnd:returnCode:contextInfo:", contextInfo:nil)
  end
  
  def uploadFailedAlertDidEnd(alert, returnCode: returnCode, contextInfo: contextInfo)
    resetUI
  end

  def increaseFrameSize
    changeFrameHeight(75)
  end
  
  def reduceFrameSize
    changeFrameHeight(-75)
  end
  
  def changeFrameHeight(heightDifference)
    newFrame = self.window.frame
    newFrame.size.height += heightDifference
    self.window.setFrame(newFrame, display: true, animate: true)    
  end
  
  def resetUI
    self.progressIndicator.stopAnimation(self)
    self.startButton.enabled = true
    self.statusLabel.stringValue = ""
    reduceFrameSize
  end
  
  def toggleUIState
    if startButton.isEnabled
      progressIndicator.startAnimation(self)
      startButton.enabled = false
    else
      progressIndicator.stopAnimation(self)
      startButton.enabled = true
    end
  end
  
  def appsFound(notification)
    self.statusLabel.stringValue = "#{notification.userInfo[:appsCount]} Apps Found"
  end
  
  def processingFinished(notification)
    self.statusLabel.stringValue = "Time to upload ..."
  end
  
  def uploadingStarted(notification)
    self.statusLabel.stringValue = "Uploading ..."
  end
  
  def uploadingFinished(notification)
    self.statusLabel.stringValue = ""
    self.mainText.stringValue = "Thanks for helping the developer community by uploading app data that will help improve and innovate inter-app communication."
    self.secondaryText.stringValue = "And don't forget to tell your friends to scan their iTunes data as well :)" 
    self.startButton.title = "View my results!"
    self.startButton.action = "openSubmissionResults:"
  end
  
  def windowWillClose(sender)
    NSApp.terminate(self)
  end
end

