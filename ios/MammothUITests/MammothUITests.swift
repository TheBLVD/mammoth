//
//  MammothUITests.swift
//  MammothUITests
//
//  Created by Riley Howard on 4/1/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import XCTest

final class MammothUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }


    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    
    func testAccountCreationInputErrors() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Make sure there are no accounts
        logOutOfAllAccounts()
        
        // Navigate to the Create Account view
        app.staticTexts["Create an Account"].tap()
        
        // Check for the Username error message
        XCTAssert(app.staticTexts["Your username will be unique to moth.social"].exists)
        var elementsQuery = app.scrollViews.otherElements
        let usernameTextField = elementsQuery.textFields["Username…"]
        usernameTextField.tap()
        usernameTextField.typeText("username.")
        XCTAssert(app.staticTexts["Username can only contain letters, numbers, and underscores"].exists)
        usernameTextField.typeText(XCUIKeyboardKey.delete.rawValue)
        XCTAssert(app.staticTexts["Your username will be unique to moth.social"].exists)

        // Check for the Email error message
        XCTAssert(app.staticTexts["You will be sent a confirmation email"].exists)
        elementsQuery = app.scrollViews.otherElements
        let emailTextField = elementsQuery.textFields["Email…"]
        emailTextField.tap()
        emailTextField.typeText("foo@bar")
        XCTAssert(app.staticTexts["Please enter a valid email address"].exists)
        emailTextField.typeText(".com")
        XCTAssert(app.staticTexts["You will be sent a confirmation email"].exists)
        
        // Verify the Sign Up button only enables with 8 character password
        XCTAssert(app.staticTexts["You will be sent a confirmation email"].exists)
        elementsQuery = app.scrollViews.otherElements
        let signUpButton = elementsQuery.buttons["Sign Up"]
        XCTAssert(!signUpButton.isEnabled)
        let passwordField = elementsQuery.secureTextFields["Password…"]
        passwordField.tap()
        passwordField.typeText("1234567")
        XCTAssert(!signUpButton.isEnabled)
        passwordField.typeText("8")
        XCTAssert(signUpButton.isEnabled)
        passwordField.typeText(XCUIKeyboardKey.delete.rawValue)
        XCTAssert(!signUpButton.isEnabled)
    }

    
    // Utilities
    func logOutOfAllAccounts() {
        let app = XCUIApplication()
        let profileButton = app.tabBars["Tab Bar"].buttons["Profile"]
        if profileButton.exists {
            profileButton.tap()
            app.navigationBars["Profile"].buttons["Settings"].tap()
            app.tables.staticTexts[" Accounts"].tap()
            
            var done = false
            repeat {
                // Tap and hold, then drag down and release on the "Log Out" button
                let topCell = app.tables.element(boundBy: 0).cells.element(boundBy: 0)
                if topCell.exists {
                    // Tap and hold to show the Log Out contextual menu
                    topCell.press(forDuration: 2)
                                        
                    // Find the Log Out button and tap on it
                    let logoutButton = app.descendants(matching: .button).matching(NSPredicate(format: "label == 'Log Out'")).firstMatch
                    logoutButton.tap()
                } else {
                    done = true
                }
            } while !done
        }
    }

    
}
