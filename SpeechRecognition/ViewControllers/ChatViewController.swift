//
//  ChatViewController.swift
//  SpeechRecognition
//
//  Created by Admin on 06/06/18.
//  Copyright © 2018 DB. All rights reserved.
//

import UIKit
import Speech
import AVFoundation

class ChatViewController: UIViewController, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate {
    
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var msgsArray = [Activity]()
    
    var bestString : String = ""
    var status = false
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var synthesizer = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")
    
    let apiService = APIService()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0
        
        synthesizer.delegate = self
        
//        let appDelegate  = UIApplication.shared.delegate as! AppDelegate
//        let userActivityDict1 = NSDictionary(dictionary: ["text": "Hello", "from": ["id": appDelegate.user?.userID]])
//        let userActivity1 = Activity(dictionary: userActivityDict1)
//        self.msgsArray.append(userActivity1!)
//
//        let userActivityDict2 = NSDictionary(dictionary: ["text": "What is your first name?", "from": ["id": appDelegate.user?.userID]])
//        let userActivity2 = Activity(dictionary: userActivityDict2)
//        self.msgsArray.append(userActivity2!)
//        self.msgsArray.append(userActivity2!)
//        self.msgsArray.append(userActivity2!)
//        self.msgsArray.append(userActivity2!)
//        self.msgsArray.append(userActivity2!)
//        self.msgsArray.append(userActivity2!)
//        self.msgsArray.append(userActivity2!)
//        self.msgsArray.append(userActivity2!)
//        self.msgsArray.append(userActivity2!)
//        self.msgsArray.append(userActivity2!)
//        self.msgsArray.append(userActivity2!)
//        self.msgsArray.append(userActivity2!)
//        self.msgsArray.append(userActivity2!)
//        self.msgsArray.append(userActivity2!)
//        self.msgsArray.append(userActivity2!)
        
        //msgsArray.append("Hello")
        //msgsArray.append("What is your first name?")
        
        //print("voice message label text status",self.voiceMessage.text?.isEmpty as Any)
        
        if speechRecognizer == nil
        {
            print("Not supported")
        }
        let myRecognizer = SFSpeechRecognizer()
        if myRecognizer?.isAvailable == false
        {
            print("NOt available")
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
        do {
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSessionCategoryPlayback,
                with: AVAudioSessionCategoryOptions.mixWithOthers
            )
            self.myUtterance = AVSpeechUtterance(string: "Welcome to the ChatBot")
            self.myUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
            let lang = "en-US"
            self.synthesizer.continueSpeaking()
            self.myUtterance.voice = AVSpeechSynthesisVoice(language: lang)
            self.synthesizer.continueSpeaking()
            self.synthesizer.speak(self.myUtterance)
        } catch {
            print(error)
        }
        apiService.getConversationIdFromService { (response) in
            //            OperationQueue.main.addOperation() {
            //                self.startStopButton.isEnabled = isButtonEnabled
            //            }
        }
    }
    
    
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
        } catch
        {
            print("audioEngine couldn't start because of an error.")
        }
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool)
    {
        if available {
            startStopButton.isEnabled = true
        } else {
            startStopButton.isEnabled = false
        }
    }
    
    // Method for Start speech
    @IBAction func startNewSpeech(_ sender: UIButton){
        if sender.titleLabel?.text == "Start" {
            self.startStopButton.setTitle("Stop", for: .normal)
            self.bestString = ""
            startRecording()
            print("User start to speak")
        } else {
            if audioEngine.isRunning {
                print("User stops to speak")
                audioEngine.stop()
                recognitionRequest?.endAudio()
                print("full speak message is",self.bestString)
                
                if self.bestString == "" {
                    
                    self.textToSpeech(text: "We have not received any input")
                    
                }else {
                    let appDelegate  = UIApplication.shared.delegate as! AppDelegate
                    let userActivityDict = NSDictionary(dictionary: ["text": self.bestString, "from": ["id": appDelegate.user?.userID]])
                    let userActivity = Activity(dictionary: userActivityDict)
                    self.msgsArray.append(userActivity!)
                    DispatchQueue.main.async
                        {
                            self.tableView.reloadData()
                            self.startStopButton.isEnabled = false
                            self.tableView.scrollToRow(at: IndexPath(item: self.msgsArray.count-1, section: 0),at: .bottom, animated: true)

                    }
                    apiService.sendMessage(msgString: self.bestString, completionHandler: { (json) in
                        print(json)
                        let responseArray = json.value(forKey:"activities") as! NSArray
                        print("Outcome array is %@",responseArray)

                        self.msgsArray.removeAll()
                        for activityDict in responseArray {
                            let activity = Activity(dictionary: activityDict as! NSDictionary)
                            self.msgsArray.append(activity!)
                        }
                        
                        self.textToSpeech(text: (self.msgsArray.last?.text)!)
                        
                        DispatchQueue.main.async
                            {
                                self.tableView.reloadData()
                                self.startStopButton.isEnabled = true
                                
                                self.tableView.scrollToRow(at: IndexPath(item: self.msgsArray.count-1, section: 0),at: .bottom, animated: true)
                                
                        }
                    })

                }            }
            self.startStopButton.setTitle("Start", for: .normal)
        }
    }
    
    @IBAction func stoprecordedSpeech(_ sender: Any)
    {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            let lang = "en-US"
            self.synthesizer.continueSpeaking()
            utterance.voice = AVSpeechSynthesisVoice(language: lang)
            self.synthesizer.continueSpeaking()
            self.synthesizer.speak(utterance)
        } catch {
            print(error)
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance){
        print("speechSynthesizer - didStart")
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance){
        print("speechSynthesizer - didFinish")
        if (self.synthesizer != nil && self.synthesizer.isSpeaking) {
            
            self.synthesizer.stopSpeaking(at: .immediate);
            print("synthesizer -- stop")
            
        }
        
        //self.synthesizer = nil;
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance){
        print("speechSynthesizer - didPause")
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance){
        print("speechSynthesizer - didContinue")
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance){
        print("speechSynthesizer - didCancel")
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance){
        print("speechSynthesizer - willSpeakRangeOfSpeechString -- \(utterance.speechString)")
    }
}
extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return msgsArray.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath) as! MsgTableViewCell
        let appDelegate  = UIApplication.shared.delegate as! AppDelegate
        
        //Get activity for the cell
        let activity = msgsArray[indexPath.row] as Activity
        cell.msgLabel?.text = activity.text
        let fromUserID = activity.from!["id"] as! String
        
        //Customizing cell by checking msgs of current 
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
