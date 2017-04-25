import CoreLocation

public enum UploadTarget {
    case user(id: String)
    case group(id: String)
    
    var decoded: (userId: String?, groupId: String?) {
        switch self {
        case .user(let id):
            return (userId: id, groupId: nil)
        case .group(let id):
            return (userId: nil, groupId: id)
        }
    }
}

extension VK.Api {
    //Metods to upload Mediafiles
    public struct Upload {
        ///Methods to upload photo
        public struct Photo {
            ///Upload photo to user album
            public static func toAlbum(
                _ media: [Media],
                to target: UploadTarget,
                albumId: String,
                caption: String = "",
                location: CLLocationCoordinate2D? = nil,
                config: Config = .default,
                uploadTimeout: TimeInterval = 30
                ) -> Request {
                
                return VK.Api.Photos.getUploadServer([
                    .albumId: albumId,
                    .userId: target.decoded.userId,
                    .groupId: target.decoded.groupId
                    ])
                    .request(with: config)
                    .next {
                        Request(
                            of: .upload(
                                url: $0["upload_url"].stringValue,
                                media: Array(media.prefix(5)
                                )
                            ),
                            config: config.mutated(timeout: uploadTimeout)
                        )
                    }
                    .next {
                        VK.Api.Photos.save([
                            .albumId: albumId,
                            .userId: target.decoded.userId,
                            .groupId: target.decoded.groupId,
                            .server: $0["server"].string,
                            .photosList: $0["photos_list"].string,
                            .aid: $0["aid"].string,
                            .hash: $0["hash"].string,
                            .caption: caption,
                            .latitude: location?.latitude.toString(),
                            .longitude: location?.longitude.toString()
                            ])
                            .request(with: config)
                }
            }
        }
        
        ///Upload photo to message
        public static func toMessage(
            _ media: Media,
            config: Config = .default,
            uploadTimeout: TimeInterval = 30
            ) -> Request {
            
            return VK.Api.Photos.getMessagesUploadServer(.empty)
                .request(with: config)
                .next {
                    VK.Api.Photos.saveMessagesPhoto([
                        .photo: $0["photo"].string,
                        .server: $0["server"].string,
                        .hash: $0["hash"].string
                        ])
                        .request(with: config.mutated(timeout: uploadTimeout))
            }
        }
        
        ///Upload photo to market
        public static func toMarket(
            _ media: Media,
            mainPhotoConfig: (cropX: String?, cropY: String?, cropW: String?)?,
            groupId: String,
            config: Config = .default,
            uploadTimeout: TimeInterval = 30
            ) -> Request {
            
            return VK.Api.Photos.getMarketUploadServer([.groupId: groupId])
                .request(with: config)
                .next {
                    VK.Api.Photos.saveMarketPhoto([
                        .groupId: groupId,
                        .photo: $0["photo"].string,
                        .server: $0["server"].string,
                        .hash: $0["hash"].string,
                        .cropData: $0["crop_data"].string,
                        .cropHash: $0["crop_hash"].string,
                        .mainPhoto: (mainPhotoConfig != nil ? "1" : "0"),
                        .cropX: mainPhotoConfig?.cropX,
                        .cropY: mainPhotoConfig?.cropY,
                        .cropWidth: mainPhotoConfig?.cropW
                        ])
                        .request(with: config.mutated(timeout: uploadTimeout))
            }
        }
        
        ///Upload photo to market album
        public static func toMarketAlbum(
            _ media: Media,
            groupId: String,
            config: Config = .default,
            uploadTimeout: TimeInterval = 30
            ) -> Request {
            
            return VK.Api.Photos.getMarketAlbumUploadServer([.groupId: groupId])
                .request(with: config)
                .next {
                    VK.Api.Photos.saveMarketAlbumPhoto([
                        .groupId: groupId,
                        .photo: $0["photo"].string,
                        .server: $0["server"].string,
                        .hash: $0["hash"].string
                        ])
                        .request(with: config.mutated(timeout: uploadTimeout))
            }
        }
        
        ///Upload photo to user or group wall
        public static func toWall(
            _ media: Media,
            to target: UploadTarget,
            config: Config = .default,
            uploadTimeout: TimeInterval = 30
            ) -> Request {
            return VK.Api.Photos.getWallUploadServer([
                .userId: target.decoded.userId,
                .groupId: target.decoded.groupId
                ])
                .request(with: config)
                .next {
                    VK.Api.Photos.saveWallPhoto([
                        .userId: target.decoded.userId,
                        .groupId: target.decoded.groupId,
                        .photo: $0["photo"].string,
                        .server: $0["server"].string,
                        .hash: $0["hash"].string
                        ])
                        .request(with: config.mutated(timeout: uploadTimeout))
            }
        }
        
        ///Upload video from file or url
        public struct Video {
            //Upload local video file
            public static func fromFile(
                _ media: Media,
                name: String = "No name",
                description: String = "",
                groupId: String = "",
                albumId: String = "",
                isPrivate: Bool = false,
                isWallPost: Bool = false,
                isRepeat: Bool = false,
                isNoComments: Bool = false,
                config: Config = .default,
                uploadTimeout: TimeInterval = 30
                ) -> Request {
                
                return VK.Api.Video.save([
                    .link: "",
                    .name: name,
                    .description: description,
                    .groupId: groupId,
                    .albumId: albumId,
                    .isPrivate: isPrivate ? "1" : "0",
                    .wallpost: isWallPost ? "1" : "0",
                    .`repeat`: isRepeat ? "1" : "0"
                    ])
                    .request(with: config)
                    .next {
                        Request(
                            of: .upload(url: $0["upload_url"].stringValue, media: [media]),
                            config: config.mutated(timeout: uploadTimeout)
                        )
                }
            }
            
            ///Upload local video from external resource
            public static func fromUrl(
                _ url: String,
                name: String = "No name",
                description: String = "",
                groupId: String = "",
                albumId: String = "",
                isPrivate: Bool = false,
                isWallPost: Bool = false,
                isRepeat: Bool = false,
                isNoComments: Bool = false,
                config: Config = .default
                ) -> Request {
                
                return VK.Api.Video.save([
                    .link: url,
                    .name: name,
                    .description: description,
                    .groupId: groupId,
                    .albumId: albumId,
                    .isPrivate: isPrivate ? "1" : "0",
                    .wallpost: isWallPost ? "1" : "0",
                    .`repeat`: isRepeat ? "1" : "0"
                    ])
                    .request(with: config)
            }
        }
//
//        ///Upload audio
//        public static func audio(_ media: Media, artist: String = "", title: String = "") -> RequestConfig {
//            var getServierReq = Api.Audio.getUploadServer()
//
//            getServierReq.next {response -> RequestConfig in
//                var uploadReq = RequestConfig(url: response["upload_url"].stringValue, media: [media])
//
//                uploadReq.next {response -> RequestConfig in
//                    return Api.Audio.save([
//                        .audio: response["audio"].stringValue,
//                        .server: response["server"].stringValue,
//                        .hash: response["hash"].stringValue,
//                        .artist: artist,
//                        .title: title
//                        ])
//                }
//                return uploadReq
//            }
//            return getServierReq
//        }
//
//        ///Upload document
//        public static func document(
//            _ media: Media,
//            groupId: String = "",
//            title: String = "",
//            tags: String = "") -> RequestConfig {
//            var getServierReq = Api.Docs.getUploadServer([.groupId: groupId])
//
//            getServierReq.next {response -> RequestConfig in
//                var uploadReq = RequestConfig(url: response["upload_url"].stringValue, media: [media])
//
//                uploadReq.next {response -> RequestConfig in
//                    return Api.Docs.save([
//                        .file: (response["file"].stringValue),
//                        .title: title,
//                        .tags: tags
//                        ])
//                }
//                return uploadReq
//            }
//            return getServierReq
//        }
    }
}
