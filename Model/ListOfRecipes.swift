//
//  RecepiesList.swift
//  FreshRecepies
//
//  Created by Alexander Carlsson on 2023-01-31.
//

import SwiftUI
import Foundation
import Firebase
import FirebaseCore
import FirebaseFirestoreSwift
import FirebaseAuth

class ListOfRecipes : ObservableObject {
    
    @Published var allRecipes = [Recipe]()
    @Published var addedRecipeID = [String]()
    @Published var userItems = [Item]()
    @Published var boughtItems = [Item]()
    @Published var favoriteItems = [String]()
    
    var db = Firestore.firestore()
    var currentUser = Auth.auth().currentUser
    
    init () {
        fetchData()
        listenToFirestore()
        listenToUserRecipes()
        listenToUserFavorites()
    }
    
    func listenToUserRecipes()  {
        if let currentUser  {
            
            db.collection("users").document(currentUser.uid).collection("userItems").addSnapshotListener{snapshot, err in
                guard let snapshot = snapshot else {return}
                
                if let err = err {
                    print ("error getting documents \(err)")
                    
                } else {
                    
                    if !self.userItems.isEmpty {
                        self.userItems.removeAll()
                    }
                    
                    for document in snapshot.documents {
                        let result = Result {
                            try document.data(as: Item.self)
                        }
                        
                        switch result {
                        case .success(let item) :
                            self.userItems.append(item)
                            
                        case .failure(let err) :
                            print("Error decoding item \(err)")
                        }
                    }
                }
            }
        }
        print("function listenToUserRecipes finished")
    }
    
    func fetchData() {
        
        let dispatchGroup = DispatchGroup()
        
        db.collection("recepies").getDocuments() { (snapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                return
            }
            
            guard let snapshot = snapshot else {
                print("snapshot is nil")
                return
            }
            
            for document in snapshot.documents {
                let recipeResult = Result {
                    try document.data(as: Recipe.self)
                }
                
                switch recipeResult {
                case .success(var newRecipe):
                    dispatchGroup.enter() // Enter the dispatch group before fetching ingredients data
                    
                    let ingredientsCollectionRef = document.reference.collection("ingredientsAsItem")
                    ingredientsCollectionRef.getDocuments { (ingredientsSnapshot, ingredientsErr) in
                        if let ingredientsErr = ingredientsErr {
                            print("Error getting ingredients documents: \(ingredientsErr)")
                            return
                        }
                        
                        guard let ingredientsSnapshot = ingredientsSnapshot else {
                            print("ingredients snapshot is nil")
                            return
                        }
                        
                        var newIngredientsAsItem = [Item]() // Create a new array for the ingredients
                        
                        for ingredientDocument in ingredientsSnapshot.documents {
                            let ingredientResult = Result {
                                try ingredientDocument.data(as: Item.self)
                            }
                            
                            switch ingredientResult {
                            case .success(let newIngredient):
                                newIngredientsAsItem.append(newIngredient)
                            case .failure(let err):
                                print("IngredientResult fail: \(err)")
                            }
                        }
                        
                        newRecipe.ingredientsAsItem = newIngredientsAsItem // Update the recepie with the new ingredients
                        self.allRecipes.append(newRecipe) // Append the recepie to the array
                        
                        dispatchGroup.leave() // Leave the dispatch group after fetching ingredients data
                    }
                    
                case .failure(let err):
                    print("\(err)")
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                print("Function FetchData finished")
            }
        }
    }
    
    func listenToFirestore() {
        guard let currentUser = currentUser else {
            print("Current user is nil")
            return
        }
        
        db.collection("users").document(currentUser.uid).collection("addedRecepieID").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            
            guard let snapshot = snapshot else {
                print("Snapshot is nil")
                return
            }
            
            if !self.addedRecipeID.isEmpty {
                self.addedRecipeID.removeAll()
            }
            
            if !snapshot.isEmpty {
                for document in snapshot.documents {
                    self.addedRecipeID.append(document.documentID)
                }
            }
        }
        print("Function listenToFirestore finished")
    }
    
    func listenToUserFavorites() {
        
        guard let currentUser = currentUser else {
            print("Current user is nil")
            return
        }
        
        db.collection("users").document(currentUser.uid).collection("favorites").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error getting favorites: \(error)")
                return
            }
            
            guard let snapshot = snapshot else {
                print("Snapshot is nil")
                return
            }
            
            if !self.favoriteItems.isEmpty {
                self.favoriteItems.removeAll()
            }
            
            if !snapshot.isEmpty {
                for document in snapshot.documents {
                    self.favoriteItems.append(document.documentID)
                }
            }
        }
        print("Function listenToFavoritesList finished")
    }
    
    func checkIfItemIsAdded(searchWord : String) -> Bool {
        for recipe in self.userItems {
            if recipe.name == searchWord {
                return true
            }
        }
        return false
    }
}


    
        

        
    
    

