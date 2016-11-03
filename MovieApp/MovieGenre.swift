//
//  MovieGenre.swift
//  MovieApp
//
//  Created by Arthur Alvarez on 03/11/16.
//  Copyright © 2016 Arthur Alvarez. All rights reserved.
//

import UIKit

/*
    Contains information about a specific movie genre
 */
class MovieGenre: NSObject {
    
    static var genres : [MovieGenre]!
    
    var genreID : Int!
    var name : String!
}
