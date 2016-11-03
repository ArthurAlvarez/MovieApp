//
//  MovieSearchViewController.swift
//  MovieApp
//
//  Created by Arthur Alvarez on 03/11/16.
//  Copyright © 2016 Arthur Alvarez. All rights reserved.
//

import UIKit
import MBProgressHUD

class MovieSearchViewController: UIViewController, MovieAPIDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate  {
    
    // MARK: - Storyboard Outlets
    @IBOutlet weak var movieSearchBar: UISearchBar!
    @IBOutlet weak var moviesTableView: UITableView!
    
    // MARK: - Class Properties
    var searchQuery : String!
    private var moviesList : [MovieData] = []
    private var numberOfPages : Int = 1
    private var currentPage : Int = 1
    private var selectedIndex : Int = 0
    private var tapGestureRecognizer : UITapGestureRecognizer!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set properties
        MovieAPI.delegate = self
        moviesTableView.dataSource = self
        moviesTableView.delegate = self
        self.movieSearchBar.delegate = self
        
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MovieSearchViewController.dismissKeyboard))
        self.tapGestureRecognizer.cancelsTouchesInView = true
        
        // Fetch search results
        requestMoviePage(searchQuery: searchQuery, page: currentPage)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.title = "Movie Search"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.navigationItem.title = ""
        self.view.endEditing(true)

        if(segue.identifier == "showMovieDetail"){
            let controller = segue.destination as! MovieDetailViewController
            controller.movieData = self.moviesList[selectedIndex]
        }
    }
    
    /**
     Request a list of movies and display on the table view
     */
    func requestMoviePage(searchQuery: String, page : Int){
        print("requesting page \(page)")
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "Loading movies"
        MovieAPI.fetchListOfMovies(path: "search/movie", arguments: ["query": searchQuery], page: page, onComplete: {(status : Bool, pages : (Int, Int),  movies : [MovieData]) -> Void in
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                if(status == true){
                    self.currentPage = pages.0
                    self.numberOfPages = pages.1
                    self.moviesList.append(contentsOf: movies)
                    
                    if(self.currentPage == 1){
                        // Scroll to top
                        self.moviesTableView.setContentOffset(CGPoint.zero, animated: false)
                    }
                    
                    self.moviesTableView.reloadData()
                }
                else{
                    self.showAlertWith(message: "Could not load the movies list. Try Again.", onComplete: {()->Void in
                        self.requestMoviePage(searchQuery : searchQuery, page: page)
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
                requestMoviePage(searchQuery: self.searchQuery, page: currentPage + 1)
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
            self.moviesTableView.reloadData()
        }
    }
    
    // MARK: - Search Bar Delegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchQuery = searchBar.text
        self.dismissKeyboard()
        
        // Reset movies list
        self.moviesList = []
        self.currentPage = 1
        self.numberOfPages = 1
        
        requestMoviePage(searchQuery: self.searchQuery, page: self.currentPage)
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
