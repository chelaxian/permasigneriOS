//
//  SignView.swift
//  permasigneriOS
//
//  Created by 蕭博文 on 2022/7/5.
//

import SwiftUI
import UniformTypeIdentifiers
import AuxiliaryExecute
import ZipArchive

struct SignView: View {
    @StateObject var progress: Progress = .shared
    @StateObject var checkapp: CheckApp = .shared
    
    @State var isImporting: Bool = false
    @State var showAlert:Bool = false
    @State var alertTitle:String = ""
    @State var alertMeaasge:String = ""
    
    @State var showInFilzaAlert:Bool = false
    @State var canShowinFilza:Bool = false
    
    @State var IamProgressing = false
    
    func signFailedAlert(title:String, message:String) {
        checkapp.fileName = ""
        alertTitle = title
        alertMeaasge = message
        showAlert.toggle()
    }
    
    var body: some View {
//        NavigationView {
            VStack {
                Text(checkapp.fileName != "" ? "\(checkapp.fileName)" : "No ipa file selected")
                Button(action: {isImporting.toggle()}, label: {Text("Select File")})
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text(alertTitle), message: Text(alertMeaasge), dismissButton: .default(Text("OK")))
                    }
                    .fileImporter(
                        isPresented: $isImporting,
                        allowedContentTypes: [UTType(filenameExtension: "ipa")!],
                        allowsMultipleSelection: false
                    ) { result in
                        do {
                            let fileUrl = try result.get()
                            checkapp.fileName = fileUrl.first!.lastPathComponent
                            checkapp.filePath = fileUrl.first!.path
                            
                            checkapp.extractIpa()
                            
                            if checkapp.checkIsIpaPayloadValid() {
                                checkapp.InfoPlistPath = checkapp.payloadPath.appendingPathComponent("\(checkapp.appNameInPayload)/Info.plist")
                                if checkapp.checkInfoPlist() {
                                    checkapp.getInfoPlistValue()
                                    if checkapp.validInfoPlist {
                                        print("valid InfoPlist")
                                    } else {
                                        checkapp.app_executable = nil
                                        signFailedAlert(title: "No executable found.", message: "Missing executable in Info.plist")
                                    }
                                }
                            } else {
                                signFailedAlert(title: "IPA is not valid!", message: "The file might have missing parts\nor invalid contents")
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                    .padding()
                
                Button(action: {
                    IamProgressing = true
                    progress.permanentSignButtonFunc()
                    if progress.CheckDebBuild() {
                        if checkFilza() {
                            canShowinFilza = true
                        } else { canShowinFilza = false }
                        showInFilzaAlert.toggle()
                        
                    } else {
                        signFailedAlert(title: "Sign Failed", message: "Please try others iPA files")
                    }
                }, label: {Text("Permanent sign")})
                .alert(isPresented: $showInFilzaAlert ){
                    Alert(
                        title: Text(canShowinFilza ? "Done" : "Ohh no"),
                        message: Text(canShowinFilza ? "View the file now ?" : "You need Filza to view the file"),
                        primaryButton: .default(Text("Okay")) {
                            if canShowinFilza {
                                UIApplication.shared.open(URL(string: "filza://\(progress.OutputDebFilePath)")!)
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
                .disabled(checkapp.fileName == "")
                .opacity(checkapp.fileName == "" ? 0.6 : 1.0)
                .buttonStyle(SignButtonStyle())
            }
            .padding()
//            .navigationBarTitle("")
//            .navigationBarHidden(true)
//            .padding()
//        }
    }
}

struct SignView_Previews: PreviewProvider {
    static var previews: some View {
        SignView()
    }
}
