//
//  MovieDetailViewController.swift
//  MovieApp
//
//  Created by Arthur Alvarez on 03/11/16.
//  Copyright © 2016 Arthur Alvarez. All rights reserved.
//

import UIKit

class MovieDetailViewController: UIViewController {
    
    // MARK: - Storyboard Outlets
    @IBOutlet weak var moviePosterImageView: UIImageView!
    @IBOutlet weak var posterActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var genresLabel: UILabel!
    @IBOutlet weak var synopsisTextView: UITextView!
    
    // MARK: - Class Properties
    var movieData: MovieData!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set data
        self.navigationItem.title = "Movie Detail"
        titleLabel.text = movieData.title
        releaseDateLabel.text = "Release: " + movieData.release_date
        genresLabel.text = "Genres: " + movieData.getGenres()
        synopsisTextView.text = movieData.synopsis
        
        // Request movie poster
        if(movieData.poster_path != nil){
            MovieAPI.getPosterImageForMovie(movie: movieData, onComplete: {(status : Int, image : UIImage?) -> Void in
                DispatchQueue.main.async {
                    self.posterActivityIndicator.stopAnimating()
                    if(status == 0){
                        self.moviePosterImageView.image = image!
                    }
                }
            })
        }
        else{
            self.posterActivityIndicator.stopAnimating()
            self.moviePosterImageView.image = UIImage(named: "no_image_poster")
        }
    }
}
