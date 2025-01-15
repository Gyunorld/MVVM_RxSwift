//
//  CoreDataError.swift
//  MyCleanProject
//
//  Created by paytalab on 8/20/24.
//

import Foundation

public enum CoreDataError: Error {
    case entityNotFound(String)
    case saveError(String)
    case readError(String)
    case deleteError(String)
    
    public var description: String {
        switch self {
        case .entityNotFound(let objectName):
            "객체를 찾을수 없습니다 \(objectName)"
        case .saveError(let message):
            "객체 저장 에러 \(message)"
        case .readError(let message):
            "객제 조회 에러 \(message)"
        case .deleteError(let message):
            "객체 삭제 에러 \(message)"
        }
    }
}
