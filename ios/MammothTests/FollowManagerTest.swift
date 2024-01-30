//
//  FollowManagerTest.swift
//  MammothTests
//
//  Created by Riley Howard on 2/25/23.
//


// IMPORTANT:
//
// Initial setup before running tests:
//      - have all three TestBert accounts logged in
//      - have all three accounts followed at least once (to store their profile on disk)
//        (feel free to unfollow once they've been followed, but it doesn't mattter)
//      - TestBert3's account should be locked (Profile > Edit Profile > Edit Details > Locked)
//
//  [eventually, the above may be automated out...]
//



import XCTest
@testable import Mammoth


final class FollowManagerTest: XCTestCase {

    var testBert1Account: Account!
    var testBert2Account: Account!
    var testBert3Account: Account!


    //
    // Put setup code here. This method is called before the invocation of each test method in the class.
    //
    override func setUpWithError() throws {
        
        // For now, just assert that the app is logged into all three accounts,
        let accounts = Account.getAccounts()
        testBert1Account = accounts.first(where: { account in
            account.fullAcct == "testbert1@moth.social"
        })
        testBert2Account = accounts.first(where: { account in
            account.fullAcct == "TestBertTwo@moth.social"
        })
        testBert3Account = accounts.first(where: { account in
            account.fullAcct == "TestBertThree@moth.social"
        })
        
        XCTAssertTrue(accounts.contains(testBert1Account), "TestBert1 must be logged in")
        XCTAssertTrue(accounts.contains(testBert2Account), "TestBert2 must be logged in")
        XCTAssertTrue(accounts.contains(testBert3Account), "TestBert3 must be logged in")
        
        self.switchToAccount(testBert1Account)
        self.unfollowAllAccounts()
        self.switchToAccount(testBert2Account)
        self.unfollowAllAccounts()
        
        // End up in the TestBert1 account
        self.switchToAccount(testBert1Account)
    }

    
    //
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    //
    override func tearDownWithError() throws {
    }

    
    //
    // These expectations are fulfilled when there has been a change
    // in the Follow state (and a notification has been posted)
    //
    var followDidChangeExpectation: XCTestExpectation?  // Fulfilled on *any* change
    var followingExpectation: XCTestExpectation?
    var notFollowingExpectation: XCTestExpectation?
    var followAwatingApprovalExpectation: XCTestExpectation?
    
    @objc func followDidChangeNotification(notification: Notification) {
        let userInfo = notification.userInfo!
        let followStatusRawValue = userInfo["followStatus"] as! String
        let followStatus = FollowManager.FollowStatus(rawValue: followStatusRawValue)
        
        log.debug(#function + " updated follow status: " + followStatusRawValue)
        
        if followDidChangeExpectation != nil {
            followDidChangeExpectation!.fulfill()
        }
        
        if followingExpectation != nil && followStatus == .following {
            followingExpectation!.fulfill()
        }

        if notFollowingExpectation != nil && followStatus == .notFollowing {
            notFollowingExpectation!.fulfill()
        }
        
        if followAwatingApprovalExpectation != nil && followStatus == .followAwaitingApproval {
            followAwatingApprovalExpectation!.fulfill()
        }
    }

    
    func unfollowAllAccounts() {
        let networkCallsCompleteExpectation = XCTestExpectation(description: "Waiting to for all accounts to be unfollowed")

        // Get the list of accounts being followed by the current user, and unfollow them one by one
        let request = Accounts.following(id: AccountsManager.shared.currentUser()!.id)
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let error = statuses.error {
                log.error("Error getting list of followers: \(error)")
            }
            if let accounts = (statuses.value), accounts.count > 0 {
                NotificationCenter.default.addObserver(self, selector: #selector(self.followDidChangeNotification), name: didChangeFollowStatusNotification, object: nil)
                for account in accounts {
                    self.notFollowingExpectation = XCTestExpectation(description: "Waiting to for account to be unfollowed")
                    FollowManager.shared.unfollowAccount(account)
                    let result = XCTWaiter.wait(for: [self.notFollowingExpectation!],  timeout: 30.0)
                    if result == XCTWaiter.Result.timedOut {
                        XCTAssert(false, "Timed out waiting to remove a follower")
                    }
                }
                // Done waiting for all unfollows to happen
                NotificationCenter.default.removeObserver(self, name: didChangeFollowStatusNotification, object: nil)
            }
            networkCallsCompleteExpectation.fulfill()
        }
        
        
        let result = XCTWaiter.wait(for: [networkCallsCompleteExpectation],  timeout: 200.0)
        if result == XCTWaiter.Result.timedOut {
            XCTAssert(false, "Timed out waiting to remove all followers")
        }
    }

    
    func testFollowLocal() throws {
        //
        // TestBert1 tries to follow TestBert2
        //
        
        NotificationCenter.default.addObserver(self, selector: #selector(followDidChangeNotification), name: didChangeFollowStatusNotification, object: nil)
        followingExpectation = XCTestExpectation(description: "Waiting for follow status update")

        FollowManager.shared.followAccount(testBert2Account)

        let result = XCTWaiter.wait(for: [followingExpectation!],  timeout: 30.0)
        if result == XCTWaiter.Result.timedOut {
            XCTAssert(false, "Timed out waiting for the follow")
        } else {
            // The follow happened. Make sure the follow status is good
            let currentFollowStatus = FollowManager.shared.followStatusForAccount(testBert2Account)
            XCTAssertTrue(currentFollowStatus == .following, "Expected status to be in following")
        }

        NotificationCenter.default.removeObserver(self, name: didChangeFollowStatusNotification, object: nil)
    }
    
    
    func testUnfollowLocal() throws {
        //
        // TestBert1 tries to follow, then unfollow TestBert2
        //
        
        try testFollowLocal()
        
        NotificationCenter.default.addObserver(self, selector: #selector(followDidChangeNotification), name: didChangeFollowStatusNotification, object: nil)
        notFollowingExpectation = XCTestExpectation(description: "Waiting for follow status update")

        FollowManager.shared.unfollowAccount(testBert2Account)

        let result = XCTWaiter.wait(for: [notFollowingExpectation!],  timeout: 30.0)
        if result == XCTWaiter.Result.timedOut {
            XCTAssert(false, "Timed out waiting for the unfollow")
        } else {
            // The follow happened. Make sure the follow status is good
            let currentFollowStatus = FollowManager.shared.followStatusForAccount(testBert2Account)
            XCTAssertTrue(currentFollowStatus == .notFollowing, "Expected status to no longer be followed")
        }

        NotificationCenter.default.removeObserver(self, name: didChangeFollowStatusNotification, object: nil)
    }
    

    func testFollowRemote() throws {
    }
    
    
    func testUnfollowRemote() throws {
    }

    
    func testFollowRequiresApproval() {
        //
        // TestBert1 tries to follow TestBert3, but that account is locked and requires approval.
        // The result should be "request pending".
        //
        
        NotificationCenter.default.addObserver(self, selector: #selector(followDidChangeNotification), name: didChangeFollowStatusNotification, object: nil)
        followAwatingApprovalExpectation = XCTestExpectation(description: "Waiting for pending follow status update")

        FollowManager.shared.followAccount(testBert3Account)
        
        // We request an update so that the check for .followAwaitingApproval will happen
        let _ = FollowManager.shared.followStatusForAccount(testBert3Account, requestUpdate: .none)

        let result = XCTWaiter.wait(for: [followAwatingApprovalExpectation!],  timeout: 30.0)
        if result == XCTWaiter.Result.timedOut {
            XCTAssert(false, "Timed out waiting for the follow to show that it was pending")
        } else {
            // The follow happened. Make sure the follow status is as expected (pending)
            let currentFollowStatus = FollowManager.shared.followStatusForAccount(testBert3Account)
            XCTAssertTrue(currentFollowStatus == .followAwaitingApproval, "Expected status to be pending; instead it's \(currentFollowStatus)")
        }

        NotificationCenter.default.removeObserver(self, name: didChangeFollowStatusNotification, object: nil)
    }


    func testFollowRequiresApprovalApproved() {
    }

    
    func testFollowRequiresApprovalDenied() {
    }

    
    func testFollowRemoteOldInstance() throws {
    }
    
    
    func testUnfollowRemoteOldInstance() throws {
    }
    
    
    func testToggleFollowing() throws {
        
        self.switchToAccount(testBert1Account)

        // Setup around expecting status to change -> un/followRequested
        NotificationCenter.default.addObserver(self, selector: #selector(followDidChangeNotification), name: didChangeFollowStatusNotification, object: nil)
        followDidChangeExpectation = XCTestExpectation(description: "Waiting for follow status update")

        // Setup around expecting status to change to final un/followed
        followingExpectation = XCTestExpectation(description: "Waiting for follow status to be 'following'")
        notFollowingExpectation = XCTestExpectation(description: "Waiting for follow status  to be 'unfollowed'")
        
        // Follow or Unfollow the account based on the previous state
        let initialFollowStatus = FollowManager.shared.followStatusForAccount(testBert2Account)
        if initialFollowStatus == .following {
            FollowManager.shared.unfollowAccount(testBert2Account)
        } else {
            FollowManager.shared.followAccount(testBert2Account)
        }
        
        // The status should change to "trying to follow", or "trying to unfollow"
        var result = XCTWaiter.wait(for: [followDidChangeExpectation!],  timeout: 20.0)
        if result == XCTWaiter.Result.timedOut {
            XCTAssert(false, "Timed out waiting for the un/follow")
        } else {
            // The status should be 'in progress' right now
            let updatedFollowStatus = FollowManager.shared.followStatusForAccount(testBert2Account)
            XCTAssertTrue(updatedFollowStatus == .followRequested || updatedFollowStatus == .unfollowRequested,
                          "Expected status to be in progress")
        }

        // Now, the status should change to "followed" or "unfollowed"
        
        if initialFollowStatus == .following {
            result = XCTWaiter.wait(for: [notFollowingExpectation!],  timeout: 20.0)
        } else {
            result = XCTWaiter.wait(for: [followingExpectation!],  timeout: 20.0)
        }
        if result == XCTWaiter.Result.timedOut {
            XCTAssert(false, "Timed out waiting for the follow")
        } else {
            // The follow happened. Make sure the follow status is good
            let updatedFollowStatus = FollowManager.shared.followStatusForAccount(testBert2Account)
            XCTAssertTrue(updatedFollowStatus == .following || updatedFollowStatus == .notFollowing,
                          "Expected status to be in followed or unfollowed")
        }

        NotificationCenter.default.removeObserver(self, name: didChangeFollowStatusNotification, object: nil)
    }
    

    
    
    
    
    // ============================================================================================================
    // ============================================================================================================
    // ============================================================================================================
    // ACCOUNT STUFF; move to account manager calls


    private func accountForFullAcct(_ fullAcct: String) -> Account {
        // Do a search, then return the Account
        var accountForAcct: Account? = nil
        
        let networkComplete = XCTestExpectation(description: "Waiting for network to complete")
        let request = Accounts.lookup(acct: fullAcct)
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let error = statuses.error {
                log.error("error in lookup for \(fullAcct)")
                log.error("error :\(error)")
            }
            if let account = (statuses.value) {
                DispatchQueue.main.async {
                    accountForAcct = account
                }
            }
            networkComplete.fulfill()
        }
        
        let result = XCTWaiter.wait(for: [networkComplete],  timeout: 60.0)
        if result == XCTWaiter.Result.timedOut {
            XCTAssert(false, "Timed out waiting for the network")
        }
        return accountForAcct!
    }
    
    
    private func accountForLocalID(_ localID: String) -> Account {
        var account: Account?
        do {
            account = try Disk.retrieve("profiles/\(localID)/otherUserPro.json", from: .documents, as: Account.self)
        } catch {
            XCTAssertTrue(false, "error fetching account from Disk - \(error)")
        }
        return account!
    }

    
    private func switchToAccount(_ account: Account) {
/*
    // PLACEHOLDER
    // Use new accountsManager to switch accounts
 
 
    if GlobalStruct.isCompact || UIDevice.current.userInterfaceIdiom == .phone {
            UIApplication.shared.keyWindow?.rootViewController = TabBarViewController()
        } else {
            NotificationCenter.default.post(name: shouldChangeRootViewController, object: nil)
        }
        NotificationCenter.default.post(name: didSwitchCurrentAccount, object: nil)

        // Sit here and wait until currentUser is valid
        repeat {
            RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 1))
        } while AccountsManager.shared.currentUser() == nil
 */
    }
    
    
}
