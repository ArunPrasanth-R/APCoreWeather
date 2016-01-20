 //
 //  ViewController.swift
 //  7CWeather
 //
 //  Created by ArunPrasanth R on 19/01/16.
 //  Copyright © 2016 ArunPrasanth R. All rights reserved.
 //
 
 import UIKit
 import CoreData
 import Alamofire
 
 class ViewController: UIViewController {
    
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var weatherListCollectionView: UICollectionView!
    var weather = [NSManagedObject]()
    var weatherListArray:NSMutableArray = []
    
    let appDelegate =
    UIApplication.sharedApplication().delegate as! AppDelegate
    
    var managedContext:NSManagedObjectContext!
    let fetchRequest = NSFetchRequest()
    
    var error: NSError? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let monthFormatter = NSDateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let dateString : NSString = monthFormatter.stringFromDate(NSDate())
        monthLabel.text = dateString as String
        
        getFiveDayWeatherForecast("Coimbatore")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Service Call
    /**
    Get Weather Forecast
    
    - parameter location: weather location
    */
    
    func getFiveDayWeatherForecast(location:NSString) {
        
        let urlStr = NSString(format: "https://api.worldweatheronline.com/free/v1/weather.ashx?q=%@&format=json&num_of_days=5&key=329c87ezzdxyx73v8wahx9cm", location)
        
        Alamofire.request(.GET, urlStr as String)
            .responseJSON { response in
                
                if response.result.error?.code == -1009 {
                    print("No Internet")
                    self.fetchWeatherFromCoreData("Weather")
                    
                } else {
                    if let jsonValue: AnyObject = response.result.value {
                        print(jsonValue .objectForKey("data")?.objectForKey("weather"))
                        
                        jsonValue .objectForKey("data")?.objectForKey("weather")!.enumerateObjectsUsingBlock({ obj, index, stop in
                            
                            let weatherList = Weather()
                            weatherList.parseWeatherData(obj)
                            
                            self.insertWeatherToCoreData("Weather", obj: obj)
                            
                            self.weatherListArray .addObject(weatherList)
                            
                        })
                        self.weatherListCollectionView.reloadData()
                        
                    } else {
                        
                    }
                }
        }
    }
    
    
    //MARK: - CoreData
    func insertWeatherToCoreData(entityName:String,obj:AnyObject?) {
        //insert
        managedContext = appDelegate.managedObjectContext
        
        // Create Entity Description
        let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedContext)
        
        let weather = NSManagedObject(entity: entityDescription!,
            insertIntoManagedObjectContext: managedContext)
        
        // Configure Fetch Request
        fetchRequest.entity = entityDescription
        
        fetchRequest.predicate = NSPredicate(format: "date = %@", (obj! .objectForKey("date") as? String)!)
        let recordCount = [managedContext .countForFetchRequest(fetchRequest, error:&error)]
        print(recordCount)
        
        let  results = (try! managedContext.executeFetchRequest(fetchRequest))
        
        if results.count == 0 {
            //set values
            weather.setValue(obj! .objectForKey("tempMaxC") as? String, forKey: "tempC")
            weather.setValue(obj! .objectForKey("tempMaxF") as? String, forKey: "tempF")
            weather.setValue(obj! .objectForKey("date") as? String, forKey: "date")
            
            let url = NSURL(string: (obj! .objectForKey("weatherIconUrl")![0] .objectForKey("value") as? String)!)
            if let data = NSData(contentsOfURL: url!){
                weather.setValue(data, forKey: "weathericon")
            }
            
            do {
                try managedContext.save()
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
        } else {
            //already exists
            
        }
    }
    
    func deleteWeatherFromCoreData(entityName:String)
    {
        managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.returnsObjectsAsFaults = false
        
        do
        {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            for managedObject in results
            {
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                managedContext.deleteObject(managedObjectData)
            }
        } catch let error as NSError {
            print("Detele all data in \(entityName) error : \(error) \(error.userInfo)")
        }
    }
    
    func fetchWeatherFromCoreData(entityName:String) {
        //fetch
        managedContext = appDelegate.managedObjectContext
        
        // Create Entity Description
        let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedContext)
        
        
        // Configure Fetch Request
        fetchRequest.entity = entityDescription
        
        do {
            let result = try managedContext.executeFetchRequest(fetchRequest)
            print(result)
            for i in 0..<result.count {
                let match = result[i] as! NSManagedObject
                print(match.valueForKey("date"))
                
                let weatherList = Weather()
                weatherList.tempC = match.valueForKey("tempC") as? String
                weatherList.tempF = match.valueForKey("tempF") as? String
                weatherList.date = match.valueForKey("date") as? String
                weatherList.weatherIcon = match.valueForKey("weathericon") as? NSData
                
                self.weatherListArray .addObject(weatherList)
            }
            
            self.weatherListCollectionView.reloadData()
            
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
    }
    
    //MARK: - UIcollectionview Datasource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return weatherListArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("weatherCollectionViewCell", forIndexPath: indexPath) as! WeatherCollectionViewCell
        
        let weatherList = weatherListArray[indexPath.row] as! Weather
        
        
        cell.dateLabel.text = weatherList.date![weatherList.date!.startIndex.advancedBy(8)...weatherList.date!.startIndex.advancedBy(9)]
        print(weatherList.date![weatherList.date!.startIndex.advancedBy(8)...weatherList.date!.startIndex.advancedBy(9)])
        
        let degree = "\u{00B0}"
        cell.tempLabel.text =  weatherList.tempC!+degree as String
        cell.weatherImgView!.image = UIImage(data: weatherList.weatherIcon!)
        cell.weatherImgView.contentMode = .ScaleAspectFit

        //Two lines needed if we use contraints
        cell.contentView.frame = cell.bounds
        cell.contentView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        
        return cell
        
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return CGSizeMake(80, 80)
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    
 }
