//
//  Heap.swift
//  Hearth
//
//  Created by Clifford Yin on 3/25/17.
//  Copyright © 2017 Clifford Yin. All rights reserved.
//
//
import Foundation
import UIKit


/* A heap is a specialized tree-based data structure that satisfies the heap property. This heap structure returns the ones with the smallest priorities. Frequencies are negative so that when addresses are popped, the ones with greatest "magnitude" are outputted. */
class PriorityQueue<T> {
    
    // Local variable to hold the data structure
    var heap = Array<(Int, T)>()
    
    // Method adds a value to the heap structure in the tree structure
    func push(_ priority: Int, item: T) {
        heap.append((priority, item))
        
        if heap.count == 1 {
            return
        }
        
        var current = heap.count - 1
        while current > 0 {
            let parent = (current - 1) >> 1
            if heap[parent].0 <= heap[current].0 {
                break
            }
            (heap[parent], heap[current]) = (heap[current], heap[parent])
            current = parent
        }
    }
    
    // Method to "pop" and return the value with lowest priority
    func pop() -> (Int, T) {
        (heap[0], heap[heap.count - 1]) = (heap[heap.count - 1], heap[0])
        let pop = heap.removeLast()
        heapify(0)
        return pop
    }
    
    // Method orders the heap variable into following the heap data structre every time data is popped or pushed; implementing this makes sure the heap variable conforms
    func heapify(_ index: Int) {
        let left = index * 2 + 1
        let right = index * 2 + 2
        var smallest = index
        
        if left < heap.count && heap[left].0 < heap[smallest].0 {
            smallest = left
        }
        if right < heap.count && heap[right].0 < heap[smallest].0 {
            smallest = right
        }
        if smallest != index {
            (heap[index], heap[smallest]) = (heap[smallest], heap[index])
            heapify(smallest)
        }
    }
    
    // Get total entries
    var count: Int {
        get {
            return heap.count
        }
    }
}
