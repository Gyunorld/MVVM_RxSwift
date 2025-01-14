//
//  UserListRepositoryProtocol.swift
//  MyCleanProject
//
//  Created by 김민규 on 1/14/25.
//

import Foundation

public protocol UserRepositoryProtocol {
    func fetchUser(query: String, page: Int) async -> Result<UserListResult,NetWorkError>
    func getFavoriteUsers() -> Result<[UserListItem],CoreDataError> 
    func saveFavoriteUser(user: UserListItem) -> Result<Bool,CoreDataError>
    func deleteFavoriteUser(userID: Int) -> Result<Bool,CoreDataError>
}
