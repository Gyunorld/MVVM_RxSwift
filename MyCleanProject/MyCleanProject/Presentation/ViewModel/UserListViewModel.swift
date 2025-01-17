//
//  UserListViewModel.swift
//  MyCleanProject
//
//  Created by 김민규 on 1/16/25.
//

import Foundation
import RxSwift
import RxCocoa

protocol UserListViewModelProtocol {
    func transform(input: UserListViewModel.Input) -> UserListViewModel.Output
}

public final class UserListViewModel: UserListViewModelProtocol {
    private let usecase: UserListUsecaseProtocol
    private let disposeBag = DisposeBag()
    private let error = PublishRelay<String>()
    private let fetchUserList = BehaviorRelay<[UserListItem]>(value: [])    // 내부적으로 접근해야하는 경우 Behavior사용
    private let allFavoriteUserList = BehaviorRelay<[UserListItem]>(value: [])    // fetchUser 즐겨찾기 여부를 위한 전체목록
    private let favoriteUserList = BehaviorRelay<[UserListItem]>(value: [])   // 목록에 보여줄 리스트
    private var page: Int = 1
    
    public init(usecase: UserListUsecaseProtocol) {
        self.usecase = usecase
    }
    
    // 이벤트(VC) -> 가공 or 외부에서 데이터 호출 or 뷰 데이터를 전달 (VM) -> VC
    public struct Input {   // VM에게 전달 되어야 할 이벤트
        // 탭, 텍스트필드, 즐겨찾기 추가 or 삭제, 페이지네이션 Observable
        let tabButtonType: Observable<TabButtonType>
        let query: Observable<String>
        let saveFavorite: Observable<UserListItem>
        let deleteFavorite: Observable<Int>
        let fetchMore: Observable<Void>
    }
    public struct Output {  // VC에게 전달할 뷰 데이터
        // cell data (유저 리스트)
        let cellData: Observable<[UserListCellData]>
        // error
        let error: Observable<String>
    }
    
    
    
    public func transform(input: Input) -> Output {   // VC이벤트 -> VM데이터
        input.query.bind { [weak self] query in
            // TODO: user Fetch and get favorite Users
            guard let self = self, validateQuery(query: query) else {
                self?.getFavoriteUsers(query: "")
                return
            }
            page = 1
            fetchUser(query: query, page: page)
            getFavoriteUsers(query: query)
        }.disposed(by: disposeBag)
        
        input.saveFavorite
            .withLatestFrom(input.query, resultSelector: { users, query in
                return (users, query)
            })  // RxSwift에서 사용함 -> 이벤트가 발생했을 때 필요한 값을 가져와서 활용가능함
            .bind { [weak self] user, query in
            // TODO: 즐겨찾기 추가
                self?.saveFavoriteUser(user: user, query: query)
        }.disposed(by: disposeBag)
        
        input.deleteFavorite
            .withLatestFrom(input.query, resultSelector: { ($0, $1)}) // 위와 동일한 내용을 간단하게 (closure 사용)
            .bind { [weak self] userID, query in
            // TODO: 즐겨찾기 삭제
                self?.deleteFavoriteUser(userID: userID, query: query)
        }.disposed(by: disposeBag)
        
        input.fetchMore
            .withLatestFrom(input.query)
            .bind { [weak self] query in
            // TODO: 다음 페이지 검색
                guard let self = self else { return }
                page += 1
                fetchUser(query: query, page: page)
        }.disposed(by: disposeBag)
        
        // 탭 -> api 유저 or 즐겨찾기 유저
        let cellData: Observable<[UserListCellData]> = Observable.combineLatest(input.tabButtonType, fetchUserList, favoriteUserList, allFavoriteUserList).map { [weak self]tabButtonType, fetchUserList, favoriteUserList, allFavoriteUserList in
            var cellData: [UserListCellData] = []
            guard let self = self else { return cellData }
            // TODO: celldata 생성
            switch tabButtonType {
            case .api:
                // Tab 타입에 따라 fetchUser List
                let tuple = usecase.checkFavoriteState(fetchUsers: fetchUserList, favoriteUsers: allFavoriteUserList)
                let userCellList = tuple.map { user, isFavorite in
                    UserListCellData.user(user: user, isFavorite: isFavorite)
                }
                return userCellList
            case .favorite:
                // Tab 타입에 따라 favoriteUser List
                let dict = usecase.convertListToDictionary(favoriteUsers: favoriteUserList)
                let keys = dict.keys.sorted() // key : [user list]
                keys.forEach { key in
                    cellData.append(.header(key))
                    if let users = dict[key] {
                        cellData += users.map { UserListCellData.user(user: $0, isFavorite: true) }
                    }
                }
            }
            return cellData
            
        }
        return Output(cellData: cellData, error: error.asObservable())
    }
    
    private func fetchUser(query: String, page: Int) {
        guard let urlAllowedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return } // 한국어 입력시 변환 작업
        // 비동기적으로 백그라운드에서 작동
        Task {
            let result = await usecase.fetchUser(query: urlAllowedQuery, page: page)
            switch result {
            case .success(let users):
                if page == 0 {
                    // 첫번째 페이지
                    fetchUserList.accept(users.items)
                } else {
                    // 두번째 이상의 페이지
                    fetchUserList.accept(fetchUserList.value + users.items)
                }
            case .failure(let error):
                self.error.accept(error.description)
                
            }
        }
    }
    
    private func getFavoriteUsers(query: String) {
        let result = usecase.getFavoriteUsers()
        switch result {
        case.success(let users):
            if query.isEmpty {
                // 전체 리스트
                favoriteUserList.accept(users)
            } else {
                // 검색어가 있을 경우
                let filteredUser = users.filter { user in
                    user.login.contains(query.lowercased())
                }
                favoriteUserList.accept(filteredUser)
            }
            allFavoriteUserList.accept(users)
        case.failure(let error):
            self.error.accept(error.description)
        }
    }
    
    private func saveFavoriteUser(user: UserListItem, query: String) { // 검색어가 있을 수도 없을 수도 있기 때문에 query를 받아와야함
        let result = usecase.saveFavoriteUser(user: user)
        switch result {
        case.success:
            getFavoriteUsers(query: query)
        case let .failure(error):
            self.error.accept(error.description)
        }
    }
    
    private func deleteFavoriteUser(userID: Int, query: String) {
        let result = usecase.deleteFavoriteUser(userID: userID)
        switch result {
        case.success:
            getFavoriteUsers(query: query)
        case let .failure(error):
            self.error.accept(error.description)
        }
    }
    
    private func validateQuery(query: String) -> Bool { // query에 대한 유효성 검사
        if query.isEmpty {
            return false
        } else {
            return true
        }
    }
    
}

public enum TabButtonType: String {
    case api = "API"
    case favorite = "Favorite"
}

public enum UserListCellData {
    case user(user: UserListItem, isFavorite: Bool)
    case header(String)
    
    var id: String {
        switch self {
        case .header: HeaderTableViewCell.id
        case .user: UserTableViewCell.id
        }
    }
}

protocol UserListCellProtocol {
    func apply(cellData: UserListCellData)
}
