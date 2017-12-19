import Foundation
import XCTest
import CoreLocation
@testable import SwiftyVK

final class UploadTests: XCTestCase {
    
    override func tearDown() {
        VKStack.removeAllMocks()
    }
    
    func test_photo_toWall() {
        // Given
        let exp = expectation(description: "")
        let media = Media.image(data: Data(), type: .jpg)
        var response: JSON?
        
        VKStack.mock(
            VK.API.Photos.getWallUploadServer([.userId: "1"]),
            fileName: "upload.getServer.success"
        )
        
        VKStack.mock(
            .upload(url: "https://test.vk.com", media: [media], partType: .photo),
            fileName: "upload.photos.toWall.success"
        )
        
        VKStack.mock(
            VK.API.Photos.saveWallPhoto([.userId: "1", .hash: "testHash", .server: "999", .photo: "testPhoto"]),
            fileName: "upload.save.success"
        )
        
        // When
        VK.API.Upload.Photo.toWall(media, to: .user(id: "1"))
            .onSuccess {
                response = try? JSON(data: $0)
                exp.fulfill()
            }
            .send()
        
        // Then
        waitForExpectations(timeout: 5)
        
        XCTAssertTrue(response?.bool("result") ?? false)
    }
    
    func test_photo_toMain() {
        // Given
        let exp = expectation(description: "")
        let media = Media.image(data: Data(), type: .jpg)
        var response: JSON?
        
        VKStack.mock(
            VK.API.Photos.getOwnerPhotoUploadServer([.ownerId: "1"]),
            fileName: "upload.getServer.success"
        )
        
        VKStack.mock(
            .upload(url: "https://test.vk.com&_square_crop=10,20,30", media: [media], partType: .photo),
            fileName: "upload.photos.ownerPhoto.success"
        )
        
        VKStack.mock(
            VK.API.Photos.saveOwnerPhoto([.server: "999", .photo: "testPhoto", .hash: "testHash"]),
            fileName: "upload.save.success"
        )
        
        // When
        VK.API.Upload.Photo.toMain(media, to: .user(id: "1"), crop: (x: "10", y: "20", w: "30"))
            .onSuccess {
                response = try? JSON(data: $0)
                exp.fulfill()
            }
            .send()
        
        // Then
        waitForExpectations(timeout: 5)
        
        XCTAssertTrue(response?.bool("result") ?? false)
    }
    
    func test_photo_toAlbum() {
        // Given
        let exp = expectation(description: "")
        let media = Media.image(data: Data(), type: .jpg)
        var response: JSON?
        
        VKStack.mock(
            VK.API.Photos.getUploadServer([.albumId: "testAlbumId", .groupId: "1"]),
            fileName: "upload.getServer.success"
        )
        
        VKStack.mock(
            .upload(
                url: "https://test.vk.com",
                media: [media],
                partType: .indexedFile
            ),
            fileName: "upload.photos.toAlbum.success"
        )
        
        VKStack.mock(
            VK.API.Photos.save([
                .groupId: "1",
                .albumId: "testAlbumId",
                .server: "999",
                .photosList: "testPhotosList",
                .hash: "testHash",
                .aid: "888",
                .latitude: "1.0",
                .longitude: "2.0",
                .caption: "testCaption"
                ]),
            fileName: "upload.save.success"
        )
        
        // When
        VK.API.Upload.Photo.toAlbum(
            [media],
            to: .group(id: "1"),
            albumId: "testAlbumId",
            caption: "testCaption",
            location: CLLocationCoordinate2D(latitude: 1, longitude: 2)
            )
            .onSuccess {
                response = try? JSON(data: $0)
                exp.fulfill()
            }
            .send()
        
        // Then
        waitForExpectations(timeout: 5)
        
        XCTAssertTrue(response?.bool("result") ?? false)
    }
}
