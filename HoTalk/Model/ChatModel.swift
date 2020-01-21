//
//  ChatModel.swift
//  HowlTalk
//
//  Created by 김호중 on 2019/05/26.
//  Copyright © 2019 hojung. All rights reserved.
//

import ObjectMapper

class ChatModel: Mappable {
    
    public var users: Dictionary<String, Bool> = [:] // 채팅방에 참여한 사람들
    public var comments: Dictionary<String, Comment> = [:] // 채팅방의 대화내용
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        users <- map["users"]
        comments <- map["comments"]
    }
    
    public class Comment: Mappable {
        public var uid: String?
        public var messege: String?
        public var timestamp: Int?
        
        public required init?(map: Map) {
            
        }
        public func mapping(map: Map) {
            uid <- map["uid"]
            messege <- map["messege"]
            timestamp <- map["timestamp"]
        }
    }
}
