//
//  TWLoginViewController.swift
//  OneDayTwitter
//
//  Created by HIroki Taniguti on 2016/10/14.
//  Copyright © 2016年 HIroki Taniguti. All rights reserved.
//

import UIKit
import TwitterKit
import SwiftyJSON
import SwiftDate

class TWLoginViewController: UIViewController {

    @IBOutlet weak var goToTimeLineButton: UIButton!
    var client = TWTRAPIClient()
//    var tweetedDayDic = [String: [String]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setLoginButton()
    }


    func setLoginButton() {
        let logInButton = TWTRLogInButton { (session, error) in
            if let unwrappedSession = session {
                print("unwrappedSession", unwrappedSession)
                self.client = TWTRAPIClient(userID: unwrappedSession.userID)
                let alert = UIAlertController(title: "Logged In",
                    message: "User \(unwrappedSession.userName) has logged in",
                    preferredStyle: UIAlertControllerStyle.Alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                NSLog("Login error: %@", error!.localizedDescription);
            }
        }

        // TODO: Change where the log in button is positioned in your view
        logInButton.center = self.view.center
        self.view.addSubview(logInButton)

    }

    func loopGetTweetData(tweetID: NSNumber) {
        let lastTweetID = String(tweetID)
        getTweetData(lastTweetID)
    }

    func getTweetData(lastTweetID : String?) {
        var clientError : NSError?
        var params = [String : String]()
        if let lastTweetID = lastTweetID {
            params = ["count": "200", "max_id": lastTweetID]
        }else {
            params = ["count": "200"]
        }
//        let statusesShowEndpoint = "https://api.twitter.com/1.1/statuses/show.json"
        let statusesShowEndpoint = "https://api.twitter.com/1.1/statuses/user_timeline.json"
//        let statusesShowEndpoint = "https://api.twitter.com/1.1/search/tweets.json"

        let request = client.URLRequestWithMethod("GET", URL: statusesShowEndpoint, parameters: params, error: &clientError)
        var parseError : NSError?
        client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
            if connectionError != nil {
                print("Error: \(connectionError)")
            }
            if let JSONObject: JSON = JSON(data: data!, options: .AllowFragments, error: &parseError){
                let countString = String(JSONObject.count - 1)
                if countString != "0" {
                    print("countString", countString)
                    //print("これはなに？", JSONObject)
                    for (key,subJson):(String, JSON) in JSONObject {
                        //                    print("key:subJson", key, ":", subJson)
                        print("key: ", key)
                        if let userID = subJson["user"]["id"].number {
                            print("userID", userID)
                        }
                        if let lang = subJson["lang"].string {
                            print("lang", lang)
                        }
                        if let created_at = subJson["created_at"].string {
                            print("created_at", created_at)
                            //                        let dayString = created_at.substringToIndex(created_at.startIndex.advancedBy(3))
                            let convertClass = convertStringToDate()
                            let convertedDayArray = convertClass.convertStringToDate(created_at)
                            let convertedKey = convertedDayArray[0]
                            let convertedObject = convertedDayArray[1]



                            if TWDayArrayData.sharedSingleton.TWDayDic[convertedKey]?.isEmpty == false { //keyがあるか？ value = [String]のはず
                                //keyがあった時
                                if (TWDayArrayData.sharedSingleton.TWDayDic[convertedKey]! as [String]).last != convertedObject { //valuesの中の最後が追加するStringと同じか？
                                    //Stringが違う時
                                    let newValues = TWDayArrayData.sharedSingleton.TWDayDic[convertedKey]! as [String] + [convertedObject]
                                    print("oldValues : ", TWDayArrayData.sharedSingleton.TWDayDic[convertedKey]! as [String])
                                    print("newValues : ", newValues)
                                    print("前の tweetedDayDic", TWDayArrayData.sharedSingleton.TWDayDic[convertedKey])
                                    TWDayArrayData.sharedSingleton.TWDayDic.updateValue(newValues, forKey: convertedKey)
                                    print("後の tweetedDayDic", TWDayArrayData.sharedSingleton.TWDayDic[convertedKey])
                                    print("後の tweetedDayDic All ver", TWDayArrayData.sharedSingleton.TWDayDic)
                                }else {
                                    //Stringが同じ時
                                    print("もうこのオブジェクトは追加されている")
                                }
                            } else {
                                //keyがなかった時
                                TWDayArrayData.sharedSingleton.TWDayDic.updateValue([convertedObject], forKey: convertedKey)
                            }

//                            if let monthAndYear = self.tweetedDayDic.updateValue(self.tweetedDayDic[convertedKey]?.append(convertedObject), forKey: convertedKey) {
//                                print("update monthAndYear", monthAndYear)
//                            }else {
//                                print("inseart monthAndYear", monthAndYear)
//                            }
//                            if self.tweetedDayArray.last != convertedDay {
//                                print("前の tweetedDayArray : convertedDay", self.tweetedDayArray, convertedDay)
//                                self.tweetedDayArray.append(convertedDay)
//                                print("後の tweetedDayArray", self.tweetedDayArray)
//                            }
                        }
                        if let userName = subJson["user"]["name"].string {
                            print("userName: ", userName)
                        }
                        if let text = subJson["text"].string {
                            print("text: ", text)
                        }
                        //keyが最後の時、TweetIDを登録
                        if key == countString {
                            if let tweetID = subJson["id"].number {
                                print("tweetID", tweetID)
//                                self.loopGetTweetData(tweetID)
                            }
                        }
                    }
                } else {
                    print("Twitter読み込み終了")
                }
            }
        }
    }

    func showTimeline() {
        // Create an API client and data source to fetch Tweets for the timeline
        let client = TWTRAPIClient()
        //TODO: Replace with your collection id or a different data source
        let dataSource = TWTRCollectionTimelineDataSource(collectionID: "539487832448843776", APIClient: client)
        // Create the timeline view controller
        let timelineViewControlller = TWTRTimelineViewController(dataSource: dataSource)
        // Create done button to dismiss the view controller
        let button = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(dismissTimeline))
        timelineViewControlller.navigationItem.leftBarButtonItem = button
        // Create a navigation controller to hold the
        let navigationController = UINavigationController(rootViewController: timelineViewControlller)
        showDetailViewController(navigationController, sender: self)
    }

    func dismissTimeline() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func tapGoToTimeLineButton(sender: AnyObject) {
//        self.showTimeline()
        self.getTweetData(nil)
    }


}




class convertStringToDate: NSObject {
    //dayString ex)
    //Tue May 13 15:29:12 +0000 2014
    func convertStringToDate(dayString: String) -> [String]{
        print("dayString", dayString)
//        let dateFormater = NSDateFormatter()
//        let local = NSLocale(localeIdentifier: "en_US")
////        let timeZone = NSTimeZone(forSecondsFromGMT: 0)
//        dateFormater.locale = local
////        dateFormater.timeZone = timeZone
//        dateFormater.setLocalizedDateFormatFromTemplate("EEE MMM dd HH:mm:ss Z yyyy")
////        let date = dateFormater.dateFromString(dayString)
        let date = dayString.toDate(DateFormat.Custom("EEE MMM dd HH:mm:ss Z yyyy"))!
        print("date : ", date)
        let convertedObject = date.toString(DateFormat.Custom("yyyyMMdd"))! + "&t"
        let convertedKey = date.toString(DateFormat.Custom("yyyy/MM"))!
         print("convertedKey, convertedObject : ", convertedKey, convertedObject)
        let convertedArray = [convertedKey, convertedObject]

        return convertedArray
    }

    func convertMonthTitle() {

    }
}

