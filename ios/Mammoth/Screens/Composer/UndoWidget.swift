//
//  UndoWidget.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 30/09/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import SwiftUI
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
struct UndoWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: UndoStruct.self) { context in
            LockScreenUndo(context: context)
                .activityBackgroundTint(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Posting in")
                        .multilineTextAlignment(.leading)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.deliveryTimer, countsDown: true)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 50, alignment: .center)
                        .monospacedDigit()
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                }
                DynamicIslandExpandedRegion(.center) {
                    
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack {
                        Text(context.state.text)
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .font(.body)
                            .padding(EdgeInsets(top: 2, leading: 0, bottom: 10, trailing: 0))
                        Link(destination: URL(string: "aviary://undo000")!) {
                            Text("Undo Post")
                                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .background(.red)
                                .padding(EdgeInsets(top: 0, leading: 10, bottom: 25, trailing: 10))
                                .cornerRadius(12)
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
                }
            } compactLeading: {
                Image("OpenIn")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20, alignment: .bottom)
            } compactTrailing: {
                Text(timerInterval: context.state.deliveryTimer, countsDown: true)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                    .monospacedDigit()
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            } minimal: {
                Image("OpenIn")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20, alignment: .bottom)
            }
            .keylineTint(.blue)
        }
    }
}

@available(iOS 16.1, *)
struct LockScreenUndo: View {
    var context: ActivityViewContext<UndoStruct>
    var body: some View {
        HStack {
            Text("Posting in")
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .font(.body)
                .foregroundColor(.white.opacity(0.5))
                .padding(EdgeInsets(top: 22, leading: 20, bottom: 0, trailing: 0))
            
            Text(timerInterval: context.state.deliveryTimer, countsDown: true)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .font(.body)
                .foregroundColor(.white.opacity(0.5))
                .padding(EdgeInsets(top: 22, leading: 0, bottom: 0, trailing: 20))
        }
        
        Text(context.state.text)
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .font(.body)
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 2, leading: 0, bottom: 10, trailing: 0))
        
        ZStack {
            Link(destination: URL(string: "aviary://undo000")!) {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(.red)
                Text("Undo Post")
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .padding(EdgeInsets(top: 0, leading: 20, bottom: 25, trailing: 20))
    }
}
#endif
