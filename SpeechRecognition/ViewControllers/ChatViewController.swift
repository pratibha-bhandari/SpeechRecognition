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
    
    let apiService = APIService()
    
    var timer:Timer?
    
    var utteranceArray = [String]()
    
    //MARK: - View LifeCycle Methods
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0
        
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
    // Method for Start speech
    @IBAction func startNewSpeech(_ sender: UIButton){
        if sender.titleLabel?.text == "Start" {
            
            speechStarted()
            print("User start to speak")
        } else {
            speechEnded()
            
        }
    }
    //MARK: - Other Methods
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
                //print("error -- \(error.)")
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
            self.timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(ChatViewController.speechEnded), userInfo: nil, repeats: false)
        } catch
        {
            print("audioEngine couldn't start because of an error.")
        }
    }

    func speechStarted(){
        self.startStopButton.setTitle("Stop", for: .normal)
        self.bestString = ""
        startRecording()
    }
    func speechEnded(){
        print("User finished talking")
        self.startStopButton.setTitle("Start", for: .normal)
        if audioEngine.isRunning {
            print("User stops to speak")
            audioEngine.stop()
            recognitionRequest?.endAudio()
            print("full speak message is",self.bestString)
            
            if self.bestString == "" {
                
                self.textToSpeech(text: MSG.noInputMsg)
                
            }else {
                let appDelegate  = UIApplication.shared.delegate as! AppDelegate
                let userActivityDict = NSDictionary(dictionary: ["text": self.bestString, "from": ["id": appDelegate.user?.userID]])
                let userActivity = Activity(dictionary: userActivityDict)
                self.msgsArray.append(userActivity!)
                DispatchQueue.main.async
                    {
                        self.tableView.reloadData()
                        self.startStopButton.isEnabled = false
                        self.tableView.scrollToRow(at: IndexPath(item: self.msgsArray.count-1, section: 0),at: .bottom, animated: false)
                        
                }
                apiService.sendMessage(msgString: self.bestString, completionHandler: { (json) in
                    //print(json)
                    let responseArray = json.value(forKey:"activities") as! NSArray
                    print("Outcome array is %@",responseArray)
                    
                    self.msgsArray.removeAll()
                    for activityDict in responseArray {
                        let activity = Activity(dictionary: activityDict as! NSDictionary)
                        self.msgsArray.append(activity!)
                    }
                    var utterArray = [String]();
                    for activity in self.msgsArray.reversed() {
                        let fromUserID = activity.from!["id"] as! String
                        
                        //Check is the msg is from server
                        if fromUserID != appDelegate.user?.userID {
                            utterArray.append(activity.text!)
                        } else {
                            break
                        }
                    }
                    self.setupTextToSpeech(stringArray: utterArray.reversed())
                    //self.textToSpeech(text: (self.msgsArray.last?.text)!)
                    
                    DispatchQueue.main.async
                        {
                            self.tableView.reloadData()
                            self.startStopButton.isEnabled = true
                            
                            self.tableView.scrollToRow(at: IndexPath(item: self.msgsArray.count-1, section: 0),at: .bottom, animated: true)
                    }
                })
            }
        }
    }
    func setupTextToSpeech(stringArray: [String]){
        for string in stringArray {
            let stringsArray = string.components(separatedBy: NSCharacterSet.newlines)
            let filteredStringsArray = stringsArray.filter{ !$0.isEmpty }
            utteranceArray.append(contentsOf: filteredStringsArray)
        }
        textToSpeech(text: utteranceArray.first!)
        utteranceArray.removeFirst()
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
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance){
        print("speechSynthesizer - didStart")
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance){
        print("speechSynthesizer - didFinish")
        if (self.synthesizer.isSpeaking) {
            
            self.synthesizer.stopSpeaking(at: .immediate);
            print("synthesizer -- stop")
            
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
