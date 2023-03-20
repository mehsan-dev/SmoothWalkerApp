//
//  WalkingSpeedViewController.swift
//  SmoothWalker
//
//  Created by Ehsan on 3/17/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit
import HealthKit
import CareKitUI

class WalkingSpeedViewController: UIViewController {
    
    let healthStore = HKHealthStore()
    
    lazy var dailyChartView: OCKCartesianChartView = {
        let chartView = OCKCartesianChartView(type: .bar)
        chartView.headerView.titleLabel.text = "Daily"
        chartView.graphView.yMinimum = 0
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    lazy var weeklyChartView: OCKCartesianChartView = {
        let chartView = OCKCartesianChartView(type: .bar)
        chartView.headerView.titleLabel.text = "Weekly"
        chartView.graphView.yMinimum = 0
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    lazy var monthlyChartView: OCKCartesianChartView = {
        let chartView = OCKCartesianChartView(type: .bar)
        chartView.headerView.titleLabel.text = "Monthly"
        chartView.graphView.yMinimum = 0
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .white
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 10.0
        return stackView
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.title = "Average Speed"
        self.setUpViews()
        
        self.requestAuthorization()
        self.fetchDailyData()
        self.fetchWeeklyData()
        self.fetchMonthlyData()
    }
    
    func setUpViews() {
        stackView.addArrangedSubview(dailyChartView)
        stackView.addArrangedSubview(weeklyChartView)
        stackView.addArrangedSubview(monthlyChartView)
        
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            dailyChartView.heightAnchor.constraint(equalToConstant: 300),
            weeklyChartView.heightAnchor.constraint(equalToConstant: 300),
            monthlyChartView.heightAnchor.constraint(equalToConstant: 300)
        ])
        
    }
    
    func requestAuthorization() {
        let typesToRead: Set<HKObjectType> = [HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!]
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { _, error in
            if error != nil {
                print("Error requestingauthorization: (error.localizedDescription)")
            }
        }
    }
    
    func fetchDailyData() {
        let startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
        let endDate = Date()
        let interval = DateComponents(day: 1)
        let dateLabels: [String] = ["Sun", "Mon", "Tue", "Wed","Thu","Fri","Sat"]
        createQuery(for: interval, chartView: dailyChartView, startDate: startDate, endDate: endDate, dateLabels: dateLabels)
    }
    
    func fetchWeeklyData() {
        let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -3, to: Date())!
        let endDate = Date()
        let interval = DateComponents(weekOfYear: 1)
        let dateLabels: [String] = ["Week1", "Week2", "Week3", "Week4"]
        createQuery(for: interval, chartView: weeklyChartView, startDate: startDate, endDate: endDate, dateLabels: dateLabels)
    }
    
    func fetchMonthlyData() {
        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        let endDate = Date()
        let interval = DateComponents(month: 1)
        let dateLabels: [String] = ["1", "2", "3", "4","5","6","7","8","9","10","11","12"]
        createQuery(for: interval, chartView: monthlyChartView, startDate: startDate, endDate: endDate, dateLabels: dateLabels)
    }
    
    func createQuery(for interval: DateComponents,chartView: OCKCartesianChartView,startDate: Date,endDate: Date,dateLabels: [String]) {
        let quantityType = HKQuantityType.quantityType(forIdentifier: .walkingSpeed)!
        let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: nil, options: [.discreteAverage], anchorDate: startDate, intervalComponents: interval)
        var dailyAverages: [Double] = []
        query.initialResultsHandler = {statisticsCollectionQuery, statisticsCollection, error in
            if let error = error {
                // Handle error
                print("Error fetching statistics: \(error.localizedDescription)")
                return
            }
            
            statisticsCollection?.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                
                let daySpeed = statistics.averageQuantity()?.doubleValue(for: HKUnit.meter().unitDivided(by: HKUnit.second())) ?? 0
                dailyAverages.append(daySpeed)
            }
            DispatchQueue.main.async {
                let walkingSpeedDataSeries = OCKDataSeries(values: dailyAverages.map { CGFloat($0) }, title: "m/s", size: 10, color: chartView.tintColor)
                chartView.graphView.dataSeries = [walkingSpeedDataSeries]
                chartView.graphView.horizontalAxisMarkers = dateLabels
                chartView.graphView.dataSeries = [walkingSpeedDataSeries]
                
            }
        }
        healthStore.execute(query)
    }
}
