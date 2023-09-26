//
//  FroopTasksView.swift
//  FroopProof
//
//  Created by David Reed on 6/22/23.
//


import SwiftUI
import Firebase
import FirebaseFirestore
import Kingfisher


struct FroopTasksView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var myData = MyData.shared
    @ObservedObject var froopManager = FroopManager.shared
    @State private var editMode = EditMode.inactive
    @State var tasks: [FroopTask] = []
    @Binding var taskOn: Bool
    @State private var isEditing = false
    var uid = FirebaseServices.shared.uid
    var db = FirebaseServices.shared.db
    
    var body: some View {
        NavigationView {
            ZStack {
                Rectangle()
                    .foregroundColor(.white)
                    .ignoresSafeArea()
                    .onTapGesture {
                        taskOn = false
                    }
                
                List {
                    ForEach(tasks.indices, id: \.self) { index in
                        TaskRow(task: $tasks[index], isEditing: $isEditing, assignTask: {
                            withAnimation {
                                tasks[index].isAccepted.toggle()
                                if tasks[index].isAccepted {
                                    tasks[index].assignedUser = uid
                                    tasks[index].imageUrl = myData.profileImageUrl
                                } else {
                                    tasks[index].assignedUser = nil
                                    tasks[index].imageUrl = nil
                                }
                                assignTask(tasks[index])
                            }
                        })
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .onDelete(perform: delete)
                    .onMove(perform: move)
                }
                .environment(\.editMode, $editMode)
                .navigationBarTitle("Tasks")
                .navigationBarItems(leading: isEditing ? Button(action: {
                    withAnimation {
                        tasks.append(FroopTask(description: "New Task", isAccepted: false, assignedUser: nil, imageUrl: nil))
                    }
                }) {
                    Image(systemName: "plus")
                } : nil, trailing: (uid == froopManager.selectedFroop.froopHost) ? Button(action: {
                    withAnimation {
                        isEditing.toggle()
                        if isEditing {
                            editMode = .active
                        } else {
                            editMode = .inactive
                            saveList()
                        }
                    }
                }) {
                    Text(isEditing ? "Save" : "Edit")
                } : nil)
                
                
                VStack{
                    Spacer()
                    Text("Close")
                        .font(.system(size: 20))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .onTapGesture {
                            taskOn = false
                        }
                        .padding(.bottom, 100)
                }
                
            }
            
        }
        .onAppear {
            let froopId = froopManager.selectedFroop.froopId
            let tasksRef = db.collection("users").document(uid).collection("myFroops").document(froopId).collection("froopTasks")
            
            tasksRef.getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    tasks = querySnapshot?.documents.compactMap { document in
                        let data = document.data()
                        return FroopTask(id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                                         description: data["description"] as? String ?? "",
                                         isAccepted: data["isAccepted"] as? Bool ?? false,
                                         assignedUser: data["assignedUser"] as? String,
                                         imageUrl: data["imageUrl"] as? String)
                    } ?? []
                }
            }
        }
    }
        
    
    func loadTasks() {
        // Assuming froopList is an array of dictionaries
        if let froopList = froopManager.selectedFroop.froopList as? [[String: Any]] {
            tasks = froopList.map { item in
                FroopTask(description: item["description"] as? String ?? "",
                          isAccepted: item["isAccepted"] as? Bool ?? false,
                          assignedUser: item["assignedUser"] as? String,
                          imageUrl: item["imageUrl"] as? String)
            }
            print("Print Count of Tasks:  \(tasks.count)")
        }
        
    }
    
    private func delete(at offsets: IndexSet) {
        let uid = Auth.auth().currentUser?.uid ?? ""
        let froopId = froopManager.selectedFroop.froopId
        let tasksRef = db.collection("users").document(uid).collection("myFroops").document(froopId).collection("froopTasks")

        for index in offsets {
            let task = tasks[index]
            tasksRef.document(task.id.uuidString).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Document successfully removed!")
                }
            }
            tasks.remove(at: index)
        }
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
    }
    
    func saveList() {
        let uid = Auth.auth().currentUser?.uid ?? ""
        let froopId = froopManager.selectedFroop.froopId
        let tasksRef = db.collection("users").document(uid).collection("myFroops").document(froopId).collection("froopTasks")

        tasks.forEach { task in
            let taskDoc = tasksRef.document(task.id.uuidString)
            let taskData = ["id": task.id.uuidString,
                            "description": task.description,
                            "isAccepted": task.isAccepted,
                            "assignedUser": task.assignedUser ?? "",
                            "imageUrl": task.imageUrl ?? ""]
            
            taskDoc.setData(taskData) { err in
                if let err = err {
                    print("Error setting document: \(err)")
                } else {
                    print("Document successfully set")
                }
            }
        }
    }
    
   
    
    func assignTask(_ task: FroopTask) {
        let uid = Auth.auth().currentUser?.uid ?? ""
        let froopId = froopManager.selectedFroop.froopId
        let taskRef = db.collection("users").document(uid).collection("myFroops").document(froopId).collection("froopTasks").document(task.id.uuidString)
        
        let updatedTask = ["description": task.description,
                           "isAccepted": task.isAccepted,
                           "assignedUser": task.assignedUser ?? "",
                           "imageUrl": task.imageUrl ?? ""] as [String : Any]
        
        taskRef.updateData(updatedTask) { err in
            if let err = err {
                print("Error updating task: \(err)")
            } else {
                print("Task successfully updated")
            }
        }
    }
}

struct FroopTask: Identifiable {
    var id: UUID
    var description: String
    var isAccepted: Bool
    var assignedUser: String?
    var imageUrl: String?

    // Add this initializer
    init(id: UUID = UUID(), description: String, isAccepted: Bool, assignedUser: String?, imageUrl: String?) {
        self.id = id
        self.description = description
        self.isAccepted = isAccepted
        self.assignedUser = assignedUser
        self.imageUrl = imageUrl
    }
}

struct TaskRow: View {
    @Binding var task: FroopTask
    @Binding var isEditing: Bool
    var assignTask: () -> Void // New closure for task assignment
    
    var body: some View {
        HStack {
            TextField("Task description", text: $task.description)
                .disabled(!isEditing)
            Spacer()
            if task.isAccepted { // Check if task is accepted
                if let imageUrl = task.imageUrl {
                    KFImage(URL(string: imageUrl))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
            } else {
                Button(action: assignTask) { // Use the new closure
                    Image(systemName: "square")
                }
            }
        }
    }
}
