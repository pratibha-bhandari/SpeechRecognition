//
//  FormViewController.swift
//  SpeechRecognition
//
//  Created by Admin on 12/06/18.
//  Copyright © 2018 DB. All rights reserved.
//

import UIKit
import Speech
import AVFoundation

class FormViewController: UIViewController, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate {
    
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var firstNameTxtFld: UITextField!
    @IBOutlet weak var lastNameTxtFld: UITextField!
    @IBOutlet weak var genderTxtFld: UITextField!
    @IBOutlet weak var companyTxtFld: UITextField!
    @IBOutlet weak var selectionTxtFld: UITextField!
    
    @IBOutlet weak var msgLabel: UILabel!
    var activitiesArray = [Activity]()
    
    var bestString : String = ""
    var status = false
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    //private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "de-CH"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var synthesizer = AVSpeechSynthesizer()
    
    let apiService = APIService()
    
    var timer:Timer?
    
    var utteranceArray = [String]()
    
    //MARK: - View LifeCycle Methods
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        synthesizer.delegate = self
        
        if speechRecognizer == nil
        {
            print("Not supported")
        }
        let myRecognizer = SFSpeechRecognizer()
        if myRecognizer?.isAvailable == false
        {
            print("Not available")
        }
        startStopButton.isEnabled = false
        speechRecognizer?.delegate = self
        var isButtonEnabled = false
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            OperationQueue.main.addOperation() {
                self.startStopButton.isEnabled = isButtonEnabled
            }
            
        }
        
        apiService.getConversationIdFromService { (response) in
            //            OperationQueue.main.addOperation() {
            //                self.startStopButton.isEnabled = isButtonEnabled
            //            }
        }
        //Getting data from UserDefaults
//                if (UserDefaults.standard.value(forKey: "activities") != nil) {
//                    let decoded  = UserDefaults.standard.value(forKey: "activities") as! Data
//                    self.activitiesArray = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Activity]
//                }
        //Getting data from document directory
        //self.activitiesArray = DataService.sharedInstance.activities
        //self.displayAnswers(lastOnly: false)
        startNewSpeech(self.startStopButton)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - SFSpeechRecognizerDelegate
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool)
    {
        if available {
            startStopButton.isEnabled = true
        } else {
            startStopButton.isEnabled = false
        }
    }
    
    //MARK: - IBActions
    /*
    Method for Start speech
     */
    @IBAction func startNewSpeech(_ sender: UIButton){
        if sender.titleLabel?.text == "Start" {
            
            speechStarted()
            print("User start to speak")
        } else {
            speechEnded()
            
        }
    }
    //MARK: - Other Methods
    
    /*
     Method to start audioEngine
     */
    func startRecording()
    {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        #if swift(>=4)
            guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
            }
        #else
            let inputNode = audioEngine.inputNode
        #endif
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            
            if result != nil
            {
                isFinal = (result?.isFinal)!
                self.bestString = (result?.bestTranscription.formattedString)!
                if (self.bestString == "Mail")
                {
                    self.bestString = "Male"
                    print(self.bestString)
                }
            }
            if error != nil || isFinal
            {
                self.audioEngine.stop()
                inputNode?.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.startStopButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode?.outputFormat(forBus: 0)
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat)
        { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do
        {
            try audioEngine.start()
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(ChatViewController.speechEnded), userInfo: nil, repeats: false)
        } catch
        {
            print("audioEngine couldn't start because of an error.")
        }
    }
    /*
     Method to start Recording for user speech
     */
    func speechStarted(){
        self.startStopButton.setTitle("Stop", for: .normal)
        self.bestString = ""
        startRecording()
    }
    
    /*
     Method to get speak message and send to the API
     */
    func speechEnded(){
        print("User finished talking")
        self.startStopButton.setTitle("Start", for: .normal)
        if audioEngine.isRunning {
            print("User stops to speak")
            audioEngine.stop()
            recognitionRequest?.endAudio()
            audioEngine.inputNode?.removeTap(onBus: 0)
            print("full speak message is",self.bestString)
            
            if self.bestString == "" {
                
                self.textToSpeech(text: MSG.noInputMsg)
                
            }else {
                let appDelegate  = UIApplication.shared.delegate as! AppDelegate
                let userActivity = Activity(type: "message", id: "", timestamp: "", serviceUrl: "", channelId: (appDelegate.user?.conversationID)!, from: ["id": appDelegate.user?.userID ?? ""], conversation: [:], text: self.bestString)
                self.activitiesArray.append(userActivity)
                for msg in self.activitiesArray {
                    print("msg -- \(String(describing: msg.text))")
                }
                DispatchQueue.main.async
                {
                        self.displayAnswers(lastOnly: true)
                        self.startStopButton.isEnabled = false
                }
                apiService.sendMessage(msgString: self.bestString, completionHandler: { (json) in
                    //print(json)
                    if (json.value(forKey:"error") != nil) {
                        print("Error -- \(String(describing: json.value(forKey:"error")))")
                    } else {
                        let responseArray = json.value(forKey:"activities") as! NSArray
                        print("Outcome array is %@",responseArray)
                        
                        self.activitiesArray.removeAll()
                        
                        for activityDict in responseArray {
                            let dict = activityDict as? NSDictionary
                            if let type = dict!["type"] as? String,
                                let id = dict!["id"] as? String,
                                let timestamp = dict!["timestamp"] as? String,
                                //let serviceUrl = dict!["serviceUrl"] as? String,
                                let channelId = dict!["channelId"] as? String,
                                let from = dict!["from"] as? Dictionary<String, Any>,
                                let conversation = dict!["conversation"] as? Dictionary<String, Any>{
                                var text = ""
                                if dict!["text"] as? String == "" {
                                    
                                    let attachmentsArray = dict!.object(forKey:"attachments") as! NSArray
                                    let attachmentDict = attachmentsArray.firstObject as! NSDictionary
                                    let contentDict = attachmentDict["content"] as! NSDictionary
                                    text = (contentDict["text"] as? String)!
                                    
                                } else {
                                    text = (dict!["text"] as? String)!
                                }
                                let activity = Activity(type: type, id: id, timestamp: timestamp, serviceUrl: "", channelId: channelId, from: from, conversation: conversation, text: text)
                                self.activitiesArray.append(activity)
                            }
                        }
                        
                        //Saving activities in user defaults
                        let encodedData = NSKeyedArchiver.archivedData(withRootObject: self.activitiesArray)
                        let userDefaults = UserDefaults.standard
                        userDefaults.set(encodedData, forKey: "activities")
                        
                        //Saving activities in a file in documents directory
                        //DataService.sharedInstance.saveData(item: self.activitiesArray)
                        var utterArray = [String]();
                        for activity in self.activitiesArray.reversed() {
                            let fromUserID = activity.from!["id"] as! String
                            
                            //Check is the msg is from server
                            if fromUserID != appDelegate.user?.userID {
                                utterArray.append(activity.text!)
                            } else {
                                  break
                            }
                        }
                        self.setupTextToSpeech(stringArray: utterArray.reversed())
                        //self.textToSpeech(text: (self.activitiesArray.last?.text)!)
                        
                        DispatchQueue.main.async
                            {
                                if self.activitiesArray.last?.text?.lowercased().range(of:"profile is complete") != nil{
                                    self.msgLabel.text = self.activitiesArray.last?.text
                                    self.audioEngine.stop()
                                    self.recognitionRequest?.endAudio()
                                    self.audioEngine.inputNode?.removeTap(onBus: 0)
                                }
                                self.startStopButton.isEnabled = true
                        }
                    }
                })
            }
        }
    }
    
    /*
     Method to update answers on UI
     */
    func displayAnswers(lastOnly:Bool) {
        let appDelegate  = UIApplication.shared.delegate as! AppDelegate
        if self.activitiesArray.count > 1 {
            
            var lastQuestionActivity: Activity?
            for activity in self.activitiesArray.reversed() {
                let fromUserID = activity.from!["id"] as! String
                print("activity -- \(String(describing: activity.text))")
                
                //Check is the msg is from server
                if fromUserID != appDelegate.user?.userID {
                    lastQuestionActivity = activity
                    if lastQuestionActivity?.text?.lowercased().range(of:"first name?") != nil {
                        self.firstNameTxtFld.text = self.activitiesArray.next(item: lastQuestionActivity!)?.text//self.activitiesArray.last?.text
                    }
                    else if lastQuestionActivity?.text?.lowercased().range(of:"last name?") != nil {
                        self.lastNameTxtFld.text = self.activitiesArray.next(item: lastQuestionActivity!)?.text//self.activitiesArray.last?.text
                    }
                    else if (lastQuestionActivity?.text?.lowercased().range(of:"gender?") != nil) || lastQuestionActivity?.text?.lowercased().range(of:"gender option.") != nil {
                        self.genderTxtFld.text = self.activitiesArray.next(item: lastQuestionActivity!)?.text//self.activitiesArray.last?.text
                    }
                    else if lastQuestionActivity?.text?.lowercased().range(of:"company?") != nil {
                        self.companyTxtFld.text = self.activitiesArray.next(item: lastQuestionActivity!)?.text//self.activitiesArray.last?.text
                    }
                    else if lastQuestionActivity?.text?.lowercased().range(of:"selection?") != nil {
                        self.selectionTxtFld.text = self.activitiesArray.next(item: lastQuestionActivity!)?.text//self.activitiesArray.last?.text
                    } else if lastQuestionActivity?.text?.lowercased().range(of:"profile is complete") != nil{
                        //self.msgLabel.text = self.activitiesArray.last?.text
                        //self.msgLabel.text = "Hello"
                        print("Else")
                    }
                    if lastOnly {
                        break
                    }
                }
            }
        }
    }
    /*
     Method to setup multiline text for speech
     */
    func setupTextToSpeech(stringArray: [String]){
        for string in stringArray {
            let stringsArray = string.components(separatedBy: NSCharacterSet.newlines)
            let filteredStringsArray = stringsArray.filter{ !$0.isEmpty }
            utteranceArray.append(contentsOf: filteredStringsArray)
        }
        if utteranceArray.count > 0 {
            textToSpeech(text: utteranceArray.first!)
            utteranceArray.removeFirst()
        }
    }
    /*
     Method to convert text to speech
     */
    func textToSpeech(text: String) {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSessionCategoryPlayback,
                with: AVAudioSessionCategoryOptions.mixWithOthers
            )
            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            utterance.postUtteranceDelay = 1.0
            //utterance.postUtteranceDelay = 0.005
            
            let lang = "en-US"
            self.synthesizer.continueSpeaking()
            utterance.voice = AVSpeechSynthesisVoice(language: lang)
            self.synthesizer.continueSpeaking()
            self.synthesizer.speak(utterance)
        } catch {
            print(error)
        }
    }
    
    /*// MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    //MARK: - AVSpeechSynthesizer Delegate
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance){
        print("speechSynthesizer - didFinish")
        if (self.synthesizer.isSpeaking) {
            self.synthesizer.stopSpeaking(at: .immediate);
        }
        print("utteranceArray -- \(utteranceArray)")
        if utteranceArray.count > 0{
            textToSpeech(text: utteranceArray.first!)
            utteranceArray.removeFirst()
        } else if utterance.speechString != MSG.noInputMsg {
            startNewSpeech(self.startStopButton)
        } else {
            print("No input received")
        }
    }
}
extension FormViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activitiesArray.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath) as! MsgTableViewCell
        let appDelegate  = UIApplication.shared.delegate as! AppDelegate
        
        //Get activity for the cell
        let activity = activitiesArray[indexPath.row] as Activity
        cell.msgLabel?.text = activity.text
        let fromUserID = activity.from!["id"] as! String
        
        //Customizing cell by checking msgs of current user
        if fromUserID == appDelegate.user?.userID {
            cell.msgLabel.textAlignment = .right
            cell.msgLabel.textColor = UIColor.white
            cell.contentView.backgroundColor = UIColor(red: 85.0/255.0, green: 85.0/255.0, blue: 85.0/255.0, alpha: 1.0)
        } else {
            cell.msgLabel.textAlignment = .left
            cell.msgLabel.textColor = UIColor.black
            cell.contentView.backgroundColor = UIColor(red: 213.0/255.0, green: 213.0/255.0, blue: 213.0/255.0, alpha: 1.0)
        }
        
        return cell
    }
}


