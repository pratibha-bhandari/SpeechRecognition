//
//  ViewController.swift
//  SpeechRecognition
//
//  Created by Aleem on 23/05/18.
//  Copyright © 2018 DB. All rights reserved.
//

import UIKit
import Speech
import AVFoundation


@available(iOS 10.0, *)
class ViewController: UIViewController,SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var voiceMessage: UILabel!
    @IBOutlet weak var firstQuestionLabel: UILabel!
    @IBOutlet weak var FirstAnswerLabel: UILabel!
    @IBOutlet weak var secondQuestionLabel: UILabel!
    @IBOutlet weak var secondAnswerLabel: UILabel!
    @IBOutlet weak var thirdQuestionLabel: UILabel!
    @IBOutlet weak var thirdAnswerLabel: UILabel!
    @IBOutlet weak var fourthQuestionLabel: UILabel!
    @IBOutlet weak var fourthAnswerLabel: UILabel!
    @IBOutlet weak var fifthQuestionText: UILabel!
    @IBOutlet weak var fifthAnswerText: UILabel!
    @IBOutlet weak var profileCompleteMessage: UILabel!
    @IBOutlet weak var startSpeakButton: UIButton!
    //var conversationid :String = ""
    var bestString : String = ""
    var responseArray: NSArray = []
    var messageResponseDictionary : NSDictionary = [:]
    var messageTextValue : String = ""
    var status = false
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    let synthesizer = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")
    
    let apiService = APIService()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        
        
        print("voice message label text status",self.voiceMessage.text?.isEmpty as Any)
        
        if speechRecognizer == nil
        {
            print("Not supported")
        }
        let myRecognizer = SFSpeechRecognizer()
        if myRecognizer?.isAvailable == false
        {
            print("NOt available")
        }
        startSpeakButton.isEnabled = false
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
                self.startSpeakButton.isEnabled = isButtonEnabled
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
//                self.startSpeakButton.isEnabled = isButtonEnabled
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
                print("Voice message text status is",self.voiceMessage.text?.isEmpty as Any)
                
                if self.voiceMessage.text?.isEmpty == true && self.status == true
                {
                    self.voiceMessage.text = result?.bestTranscription.formattedString
                }
                
                if self.voiceMessage.text?.isEmpty == false && self.status == false
                {
                    self.FirstAnswerLabel.text = result?.bestTranscription.formattedString
                }
                if self.voiceMessage.text?.isEmpty == false && self.FirstAnswerLabel.text?.isEmpty == false  && self.secondAnswerLabel.text?.isEmpty == true && self.status == true
                {
                    self.secondAnswerLabel.text = result?.bestTranscription.formattedString
                }
                if self.voiceMessage.text?.isEmpty == false && self.FirstAnswerLabel.text?.isEmpty == false  && self.secondAnswerLabel.text?.isEmpty == false && self.thirdQuestionLabel.text?.isEmpty == false && self.fourthQuestionLabel.text?.isEmpty == true && self.status == true
                {
                    self.thirdAnswerLabel.text = result?.bestTranscription.formattedString
                }
                if self.voiceMessage.text?.isEmpty == false && self.FirstAnswerLabel.text?.isEmpty == false  && self.secondAnswerLabel.text?.isEmpty == false && self.thirdQuestionLabel.text?.isEmpty == false && self.fourthQuestionLabel.text?.isEmpty == false && self.fifthQuestionText.text?.isEmpty == true  && self.status == true
                {
                    self.fourthAnswerLabel.text = result?.bestTranscription.formattedString
                }
                if self.voiceMessage.text?.isEmpty == false && self.FirstAnswerLabel.text?.isEmpty == false  && self.secondAnswerLabel.text?.isEmpty == false && self.thirdQuestionLabel.text?.isEmpty == false && self.fourthQuestionLabel.text?.isEmpty == false && self.fifthQuestionText.text?.isEmpty == false  && self.status == true
                {
                    self.fifthAnswerText.text = result?.bestTranscription.formattedString
                }
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
                self.startSpeakButton.isEnabled = true
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
            startSpeakButton.isEnabled = true
        } else {
            startSpeakButton.isEnabled = false
        }
    }
    
    // Method for Start speech
    @IBAction func startNewSpeech(_ sender: Any)
    {
        print("User start to speak")
        
        if self.voiceMessage.text?.isEmpty == false
        {
            self.status = false
        }
        if self.voiceMessage.text?.isEmpty == true
        {
            self.status = true
        }
        
        if self.FirstAnswerLabel.text?.isEmpty == false
        {
            self.status = true
        }
        if self.secondAnswerLabel.text?.isEmpty == false
        {
            self.status = true
        }
        if self.thirdAnswerLabel.text?.isEmpty == false
        {
            self.status = true
        }
        
        self.bestString = ""
        startRecording()
        startSpeakButton.setTitle("Start", for: .normal)
        startSpeakButton.isEnabled = false
        
    }
    
    @IBAction func stoprecordedSpeech(_ sender: Any)
    {
        if audioEngine.isRunning {
            print("User stops to speak")
            audioEngine.stop()
            recognitionRequest?.endAudio()
            print("full speak message is",self.bestString)
            apiService.sendMessage(msgString: self.bestString, completionHandler: { (json) in
                print(json)
                self.responseArray = json.value(forKey:"activities") as! NSArray
                print("Outcome array is %@",self.responseArray)
                self.messageResponseDictionary = self.responseArray.lastObject as! NSDictionary
                print("Last message Dictionary is %@",self.messageResponseDictionary)
                self.messageTextValue = self.messageResponseDictionary.object(forKey:"text") as! String
                print("Last message is %@",self.messageTextValue)
                
                do {
                    try AVAudioSession.sharedInstance().setCategory(
                        AVAudioSessionCategoryPlayback,
                        with: AVAudioSessionCategoryOptions.mixWithOthers
                    )
                    self.myUtterance = AVSpeechUtterance(string: self.messageTextValue)
                    self.myUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
                    let lang = "en-US"
                    self.synthesizer.continueSpeaking()
                    self.myUtterance.voice = AVSpeechSynthesisVoice(language: lang)
                    self.synthesizer.continueSpeaking()
                    self.synthesizer.speak(self.myUtterance)
                } catch {
                    print(error)
                }
                
                DispatchQueue.main.async
                    {
                        if self.FirstAnswerLabel.text?.isEmpty == true && self.firstQuestionLabel.text?.isEmpty == true
                        {
                            self.firstQuestionLabel.text = self.messageTextValue
                            
                        }
                        
                        if self.FirstAnswerLabel.text?.isEmpty == false && self.firstQuestionLabel.text?.isEmpty == false && self.secondQuestionLabel.text?.isEmpty == true
                        {
                            self.secondQuestionLabel.text = self.messageTextValue
                        }
                        
                        if self.secondAnswerLabel.text?.isEmpty == false && self.secondQuestionLabel.text?.isEmpty == false &&
                            self.thirdQuestionLabel.text?.isEmpty == true
                        {
                            self.thirdQuestionLabel.text = "What is your gender?"
                        }
                        if self.fourthQuestionLabel.text?.isEmpty == true && self.thirdQuestionLabel.text?.isEmpty == false && self.thirdAnswerLabel.text?.isEmpty == false
                        {
                            
                            self.fourthQuestionLabel.text = self.messageTextValue
                            
                        }
                        if self.fifthQuestionText.text?.isEmpty == true && self.fourthQuestionLabel.text?.isEmpty == false && self.fourthAnswerLabel.text?.isEmpty == false
                        {
                            
                            self.fifthQuestionText.text = self.messageTextValue
                            
                        }
                        if self.fifthAnswerText.text == "Yes"
                        {
                            self.profileCompleteMessage.text = self.messageTextValue
                        }
                        if self.fifthAnswerText.text == "No"
                        {
                            self.profileCompleteMessage.text = "What do you want to change?"
                        }
                }
            })
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        
    }
}

