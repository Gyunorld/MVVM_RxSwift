//
//  UserListItem.swift
//  MyCleanProject
//
//  Created by paytalab on 8/20/24.
//

import Foundation

public struct UserListResult: Decodable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [UserListItem]
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.totalCount = try container.decode(Int.self, forKey: .totalCount)
        self.incompleteResults = try container.decode(Bool.self, forKey: .incompleteResults)
        self.items = try container.decode([UserListItem].self, forKey: .items)
    }
}

public struct UserListItem: Decodable, Hashable {
    let id: Int
    let login: String
    let imageURL: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case login
        case imageURL = "avatar_url"
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.login = try container.decode(String.self, forKey: .login)
        self.imageURL = try container.decode(String.self, forKey: .imageURL)
    }
    
    public init(id: Int, login: String, imageURL: String) {
        self.id = id
        self.login = login
        self.imageURL = imageURL
    }
}
