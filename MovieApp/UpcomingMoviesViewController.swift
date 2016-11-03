//
//  UpcomingMoviesViewController.swift
//  MovieApp
//
//  Created by Arthur Alvarez on 03/11/16.
//  Copyright © 2016 Arthur Alvarez. All rights reserved.
//

import UIKit
import MBProgressHUD

class UpcomingMoviesViewController: UIViewController, MovieAPIDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // MARK: - Storyboard Outlets
    @IBOutlet weak var movieSearchBar: UISearchBar!
    @IBOutlet weak var upcomingMoviesTableView: UITableView!
    
    // MARK: - Class Properties
    private var moviesList : [MovieData] = []
    private var numberOfPages : Int = 1
    private var currentPage : Int = 1
    private var selectedIndex : Int = 0
    private var searchQuery : String = ""
    private var tapGestureRecognizer : UITapGestureRecognizer!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set properties
        MovieAPI.delegate = self
        upcomingMoviesTableView.dataSource = self
        upcomingMoviesTableView.delegate = self
        movieSearchBar.delegate = self
        
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UpcomingMoviesViewController.dismissKeyboard))
        self.tapGestureRecognizer.cancelsTouchesInView = true
        
        // Start API communication
        startAPI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.title = "Upcoming Movies"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.navigationItem.title = ""
        self.view.endEditing(true)
        
        if(segue.identifier == "showMovieDetail"){
            let controller = segue.destination as! MovieDetailViewController
            controller.movieData = moviesList[selectedIndex]
        }
        else if(segue.identifier == "startSearch"){
            let controller = segue.destination as! MovieSearchViewController
            controller.searchQuery = self.searchQuery
        }
    }
    
    // MARK: - API Methods
    
    /**
     Starts the API fetching movie genres and first page of upcoming movies
     */
    func startAPI(){
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "Connecting"
        MovieAPI.fetchMovieGenres(onComplete: {(success : Bool) -> Void in
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                if(success){
                    print("Genres parsed with success. Fetching movie data.")
                    self.requestMoviePage(page: 1)
                }
                else{
                    // Show alert message and try again
                    self.showAlertWith(message: "Could not fetch server data. Try Again.", onComplete: {()->Void in
                        self.startAPI()
                    })
                }
            }
        })
    }
    
    /**
     Request a list of movies and display on the table view
     */
    func requestMoviePage(page : Int){
        print("requesting page \(page)")
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "Loading movies"
        MovieAPI.fetchListOfMovies(path: "movie/upcoming", arguments: [:], page: page, onComplete: {(status : Bool, pages : (Int, Int),  movies : [MovieData]) -> Void in
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                if(status == true){
                    self.currentPage = pages.0
                    self.numberOfPages = pages.1
                    self.moviesList.append(contentsOf: movies)
                    self.upcomingMoviesTableView.reloadData()
                }
                else{
                    self.showAlertWith(message: "Could not load the movies list. Try Again.", onComplete: {()->Void in
                        self.requestMoviePage(page: page)
                    })
                }
            }
        })
    }
    
    // MARK: - Table View Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return moviesList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "upcomingMovieCell") as! UpcomingMovieTableViewCell
        
        // Set cell information
        cell.titleLabel.text = moviesList[indexPath.row].title
        cell.informationLabel.text = moviesList[indexPath.row].release_date + " / " + moviesList[indexPath.row].genres[0]
        
        // Set cell backdrop image
        cell.backdropImageView.image = moviesList[indexPath.row].backdrop_image
        if(moviesList[indexPath.row].backdrop_path == nil){
            cell.backdropImageView.image = UIImage(named: "no_image_backdrop")
        }
        if(cell.backdropImageView.image == nil){
            cell.activityIndicator.startAnimating()
        }
        else{
            cell.activityIndicator.stopAnimating()
        }
        
        // Request next page if needed
        if(indexPath.row == moviesList.count - 1){
            if(currentPage < numberOfPages){
                requestMoviePage(page: currentPage + 1)
            }
        }
        
        return cell
    }
    
    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "showMovieDetail", sender: self)
    }
    
    // MARK: - Movie API Delegate
    func APIDownloadedImageForMovie(movie : MovieData){
        DispatchQueue.main.async {
            for m in self.moviesList{
                if(m.id == movie.id){
                    m.backdrop_image = movie.backdrop_image
                    break
                }
            }
            self.upcomingMoviesTableView.reloadData()
        }
    }
    
    // MARK: - Search Bar Delegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchQuery = searchBar.text!
        performSegue(withIdentifier: "startSearch", sender: self)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.view.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.view.removeGestureRecognizer(self.tapGestureRecognizer)
    }
    
    
    // MARK: - Auxiliary Methods
    func showAlertWith(message : String, onComplete : @escaping ()->Void){
        let alert = UIAlertController(title: "Movie App", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "Retry", style: UIAlertActionStyle.default, handler: {(UIAlertAction) -> Void in
            onComplete()
        })
        
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func dismissKeyboard(){
        self.view.endEditing(true)
    }
}
