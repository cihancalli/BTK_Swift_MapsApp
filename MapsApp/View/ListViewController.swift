//
//  ListViewController.swift
//  MapsApp
//
//  Created by Cihan on 26.01.2024.
//

import UIKit
import CoreData

class ListViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var nameArray = [String]()
    var idArray = [UUID]()
    
    var selectedAnnotationName = ""
    var selectedAnnotationId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addBarButtonClicked))
        
        getData()
    }
    
    @objc func addBarButtonClicked() {
        selectedAnnotationName = ""
        performSegue(withIdentifier: "toMapsVc", sender: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("CreateNewAnnotation"), object: nil)
    }
    
    @objc func getData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Annotation")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            
            if results.count > 0 {
                nameArray.removeAll(keepingCapacity: false)
                idArray.removeAll(keepingCapacity: false)
                
                for result in results as![NSManagedObject] {
                    if let name = result.value(forKey: "name") as? String {
                        nameArray.append(name)
                    }
                    
                    if let id = result.value(forKey: "id") as? UUID {
                        idArray.append(id)
                    }
                    
                }
                tableView.reloadData()
            }
            
        } catch {
            self.alertMessage(title: "LOADING ERROR", message: "An error occurred while retrieving data from the Database")
        }
    }


    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = nameArray[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedAnnotationName = nameArray[indexPath.row]
        selectedAnnotationId = idArray[indexPath.row]
        performSegue(withIdentifier: "toMapsVc", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapsVc" {
            let destinationVC = segue.destination as! MapsViewController
            destinationVC.selectedName = selectedAnnotationName
            destinationVC.selectedId = selectedAnnotationId
        }
    }
    
    func alertMessage(title:String,message:String) {
        let alertMessage = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
        
        alertMessage.addAction(okButton)
        self.present(alertMessage, animated: true, completion: nil)
    }

}
