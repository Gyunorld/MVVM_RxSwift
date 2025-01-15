//
//  MockUserRepository.swift
//  MyCleanProjectTests
//
//  Created by paytalab on 8/27/24.
//

import Foundation
@testable import MyCleanProject

public struct MockUserRepository: UserRepositoryProtocol {
    public func fetchUser(query: String, page: Int) async -> Result<MyCleanProject.UserListResult, MyCleanProject.NetworkError> {
        .failure(.dataNil)
    }
    
    public func getFavoriteUsers() -> Result<[MyCleanProject.UserListItem], MyCleanProject.CoreDataError> {
        .failure(.entityNotFound(""))
    }
    
    public func saveFavoriteUser(user: MyCleanProject.UserListItem) -> Result<Bool, MyCleanProject.CoreDataError> {
        .failure(.entityNotFound(""))
    }
    
    public func deleteFavoriteUser(userID: Int) -> Result<Bool, MyCleanProject.CoreDataError> {
        .failure(.entityNotFound(""))
    }
    
    
}
