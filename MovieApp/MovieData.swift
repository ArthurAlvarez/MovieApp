//
//  MovieData.swift
//  MovieApp
//
//  Created by Arthur Alvarez on 03/11/16.
//  Copyright © 2016 Arthur Alvarez. All rights reserved.
//

import UIKit

/*
 Contains information about a specific movie
 */
class MovieData: NSObject {
    
    // MARK: - Class properties
    var id : Int!
    var title : String!
    var genres : [String]!
    var release_date : String!
    var backdrop_path : String!
    var backdrop_image : UIImage?
    var poster_path : String!
    var synopsis : String!
    
    // MARK: - Class Methods
    
    /**
     Get the genres of a movie
     - returns: String containing the genres of a movie separated by coma.
     */
    func getGenres()->String{
        var str = ""
        
        for a in 0..<genres.count{
            str = str + genres[a]
            
            if(a != genres.count - 1){
                str = str + ", "
            }
        }
        
        return str
    }
}
