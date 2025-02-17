//
//  Flow.swift
//  auto-clicker
//
//  Created by Rudy on 2025/2/10.
//

import Foundation

var shopIsOpen = false
var bagIsOpen = false
var detailSearchIsOpen = false

func openShop() {
    if !bagIsOpen {
        openBag()
    }
    leftClick(key: "shop")
}

func createOrder() {
    if !shopIsOpen {
        openShop()
    }
}

func openBag() {
    keydown(key: "B")
}

func findGoodInBag(key: String) {
    
}

func keydown(key: String) {
    
}

func leftClick(key: String) {
    
}
