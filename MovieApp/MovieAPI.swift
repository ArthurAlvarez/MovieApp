//
//  MovieAPI.swift
//  MovieApp
//
//  Created by Arthur Alvarez on 03/11/16.
//  Copyright © 2016 Arthur Alvarez. All rights reserved.
//

import UIKit

protocol MovieAPIDelegate {
    func APIDownloadedImageForMovie(movie : MovieData)
}

/*
 Provides methods to fetch data from The Movie Database
 */
class MovieAPI: NSObject {
    
    // MARK: - Class Properties
    
    private static let API_KEY = "1f54bd990f1cdfb230adb312546d765d​"
    private static let BASE_URL = "http://api.themoviedb.org/3/"
    private static var genres : [MovieGenre]!
    private static var delegate : MovieAPIDelegate?
    
    // MARK: - General Methods
    
    /**
     Formats URL for a designed request.
     - parameter path: The path of the API service.
     - parameter arguments: The arguments to be passed through the URL query string.
     - returns: Formated URL with path and parameters.
     */
    private class func formatURL(path : String, arguments : [String : String])->String{
        // Add Path
        var resultURL = BASE_URL + path + "?"
        
        // Add arguments
        for arg in arguments{
            let substring = arg.key + "=" + arg.value + "&"
            resultURL = resultURL + substring
        }
        
        // Add API key
        resultURL = resultURL + "api_key=" + API_KEY
        
        return resultURL
    }
    
    // MARK: - Movie Genre Methods
    
    /**
     Fetch list of movie genres
     - parameter path: The path of the API service.
     - parameter arguments: The arguments to be passed through the URL query string.
     - parameter onComplete: Callback method with Boolean parameter indicating the success of the operation.
     */
    class func fetchMovieGenres(path : String, arguments : [String : String], onComplete : @escaping (Bool)->Void){
        
        // Configure URL Session
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        config.httpAdditionalHeaders = ["Accept" : "application/json"]
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let url =  URL(string: formatURL(path: path, arguments: arguments))
        
        // Set data task
        let dataTask = session.dataTask(with: url!, completionHandler: {(data : Data?, response : URLResponse?, error : Error?) -> Void in
            
            if error == nil{
                // Successful Request
                let httpResponse = response as! HTTPURLResponse
                
                if(httpResponse.statusCode == 200){
                    // API Responded with success
                    parseMovieGenres(data: data!, onComplete: onComplete)
                }
                else{
                    // There was a problem on the request
                    onComplete(false)
                }
            }
            else{
                // Could not fetch data
                onComplete(false)
            }
        })
        
        // Run data task
        dataTask.resume()
    }
    
    /**
     Parse the json result from the fetchMovieGenres request.
     - parameter data: The server response data.
     - parameter onComplete: Callback method with Boolean parameter indicating the success of the operation.
     */
    private class func parseMovieGenres(data : Data, onComplete : (Bool)->Void){
        genres = []
        
        let json = (try! JSONSerialization.jsonObject(with: data, options: []) as! [String : Any])
        let items = json["genres"] as! [[String : Any]]
        
        let noGenre = MovieGenre()
        noGenre.genreID = -1
        noGenre.name = "Undefined"
        
        genres.append(noGenre)
        
        for item in items{
            let newGenre = MovieGenre()
            newGenre.genreID = item["id"] as! Int
            newGenre.name = item["name"] as! String
            
            genres.append(newGenre)
        }
        
        onComplete(true)
    }
    
    /**
     Fetch a movie genre name.
     - parameter id: Movie Genre ID.
     - returns: String containing genre name.
     */
    private class func getMovieGenreBy(id : Int)->String{
        for g in genres{
            if(g.genreID == id){
                return g.name
            }
        }
        return "Undefined"
    }
    
    // MARK: - Movie Data Methods
    
    /**
     Fetch a list of movies.
     - parameter path: The path of the API service.
     - parameter arguments: The arguments to be passed through the URL query string.
     - parameter onComplete: Callback  method. Params: Bool indicating success, Touple indicating current page and number of pages, Array of MovieData containing the fetched data.
     */
    class func fetchListOfMovies(path : String, arguments : [String : String], onComplete : @escaping ( Bool, (Int, Int), [MovieData])->Void){
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        config.httpAdditionalHeaders = ["Accept" : "application/json"]
        
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let url =  URL(string: formatURL(path: path, arguments: arguments))
        
        let dataTask = session.dataTask(with: url!, completionHandler: {(data : Data?, response : URLResponse?, error : Error?) -> Void in
            
            if error == nil{
                // Successful Request
                
                let httpResponse = response as! HTTPURLResponse
                
                if(httpResponse.statusCode == 200){
                    // API Responded with success
                    parseListOfMovies(data: data!, onComplete: onComplete)
                }
                else{
                    // There was a problem on the request
                    onComplete(false, (1,1), [])
                }
            }
            else{
                // Could not fetch data
                onComplete(false, (1,1), [])
            }
        })
        
        dataTask.resume()
    }
    
    /**
     Parse the json result from fetchListOfMovies request.
     - parameter data: The server response data.
     - parameter onComplete: Callback  method. Params: Bool indicating success, Touple indicating current page and number of pages, Array of MovieData containing the fetched data.
     */
    private class func parseListOfMovies(data : Data, onComplete : (Bool, (Int, Int), [MovieData])->Void){
        var resultData : [MovieData] = []
        let json = (try! JSONSerialization.jsonObject(with: data, options: []) as! [String : Any])
        
        let items = json["results"] as! [[String : Any]]
        
        let page = json["page"] as! Int
        let totalPages = json["total_pages"] as! Int
        
        for movie in items{
            let newMovie = MovieData()
            newMovie.id = movie["id"] as! Int
            newMovie.title = movie["title"] as! String
            newMovie.synopsis = movie["overview"] as! String
            newMovie.release_date = movie["release_date"] as! String
            newMovie.backdrop_path = movie["backdrop_path"] as? String
            newMovie.poster_path = movie["poster_path"] as? String
            newMovie.genres = []
            
            let movieGenres = movie["genre_ids"] as! [Int]
            
            if(movieGenres.count == 0){
                newMovie.genres.append(getMovieGenreBy(id: -1))
            }
            else{
                for g in movieGenres{
                    newMovie.genres.append(getMovieGenreBy(id: g))
                }
            }
            
            if(newMovie.backdrop_path != nil){
                getBackdropImageForMovie(movie: newMovie)
            }
            
            resultData.append(newMovie)
        }
        
        onComplete(true, (page, totalPages), resultData)
    }
    
    /**
     Fetch backdrop image for specific movie and invoke the delegate method on completion.
     - parameter movie: The correspondent movie
     */
    private class func getBackdropImageForMovie(movie : MovieData){
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = NSURLRequest.CachePolicy.returnCacheDataElseLoad
        
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let url =  URL(string: "http://image.tmdb.org/t/p/w780/" + movie.backdrop_path)
        
        let dataTask = session.dataTask(with: url!, completionHandler: {(data : Data?, response : URLResponse?, error : Error?) -> Void in
            
            if error == nil{
                // Successful Request
                
                let httpResponse = response as! HTTPURLResponse
                
                if(httpResponse.statusCode == 200){
                    // API Responded with success
                    if let image = UIImage(data: data!){
                        movie.backdrop_image = image
                        delegate?.APIDownloadedImageForMovie(movie: movie)
                    }
                }
                else{
                    // There was a problem on the request
                    movie.backdrop_image = nil
                    delegate?.APIDownloadedImageForMovie(movie: movie)
                }
            }
            else{
                // Could not fetch data
                movie.backdrop_image = nil
                delegate?.APIDownloadedImageForMovie(movie: movie)
            }
        })
        dataTask.resume()
    }
    
    /**
     Fetch poster image for specific movie.
     - parameter movie: The correspondent movie.
     - parameter onComplete: Callback function containing the success of operation and fetched image
    */
    class func getPosterImageForMovie(movie : MovieData, onComplete : @escaping (Int, UIImage?)->Void){
        let config = URLSessionConfiguration.default
        
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let url =  URL(string: "https://image.tmdb.org/t/p/w500/" + movie.poster_path)
        
        let dataTask = session.dataTask(with: url!, completionHandler: {(data : Data?, response : URLResponse?, error : Error?) -> Void in
            
            if error == nil{
                // Successful Request
                
                let httpResponse = response as! HTTPURLResponse
                
                if(httpResponse.statusCode == 200){
                    // API Responded with success
                    if let image = UIImage(data: data!){
                        onComplete(0, image)
                    }
                }
                else{
                    // There was a problem on the request
                    onComplete(-1, nil)
                }
            }
            else{
                // Could not fetch data
                onComplete(-1, nil)
            }
        })
        dataTask.resume()
    }
    
}
