//
//  FoodlyWidgetBundle.swift
//  FoodlyWidget
//
//  Created by 하태훈 on 9/24/26.
//

import WidgetKit
import SwiftUI

@main
struct FoodlyWidgetBundle: WidgetBundle {
    var body: some Widget {
        FoodlyWidget()
        ShoppingWidget()
    }
}
