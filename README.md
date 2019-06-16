
# Harvesting Data with the Combine Framework

While SwiftUI, ML and AR updates have earned most of the attention in the few days after WWDC 2019, Apple's release of the [Combine Framework](https://developer.apple.com/documentation/combine) may end up having the biggest impact in the near future. The framework's purpose is succinctly stated by Apple: Combine was built to be a unified, declarative framework for processing values over time. When considering the architecture of modern applications built for enterprises, we start to see that processing data over time happens nearly everywhere.

## Scouting Out Combine

The first thing you'll notice when you dig into the Combine Framework is that it is truly a general purpose framework, and is not built for one specific purpose, like networking (although your networking stack is a great place to take advantage of it). Combine makes use of two new protocols that make up the heart of the framework: `Publisher` and `Subscriber`.

#### Publishers

[`Publisher`'s](https://developer.apple.com/documentation/combine/publisher) declare a type that can deliver a sequence of values over time. A publisher must declare the output type of elements it produces, as well as the errors it may publish along the way. Most interesting are all of the operations available to `Publisher`'s. Once declared, `Publisher`'s have a wide array of modifiers to perform mapping, filtering, reducing, data merging, and error handling, with most of the heavy lifting already done by Apple. There are a number of useful default `publisher`'s too, listed below.

  * `Future` - Eventually produces one value, then finishes or fails
  * `Empty` - Never publishes any values, optionally finishes immediately
  * `Just` - Emits an output just once, then finishes
  * `Sequence` - Publishes a given sequence of elements
  * `Last` - Publishes the last value in a finished stream

Having these modifiers available declaratively means codebases can become much more maintainable, reducing the need for multi-level completion closures and non-sequential code execution. I expect that we'll see a good amount of open source modifiers as well (hope you didn't miss the talk on Swift Packages).

#### Subscribers

[`Subscriber`'s](https://developer.apple.com/documentation/combine/subscriber) act on elements as they receive them. `Subscriber`'s must be reference types, because they generally store and mutate state. Generally, a Subscriber is passed in the `Publisher`'s subscribe method, which invokes the `Subscriber`'s `receive(subscription: )` function on success. The `Subscriber` will then use this subscription to request some number of values from it's associated `Publisher`. This is called [backpressure](https://medium.com/@jayphelps/backpressure-explained-the-flow-of-data-through-software-2350b3e77ce7), an important thing to note when reasoning about the way a Combine-enabled system will behave. The Subscriber will then `receive(_ : Input)` that number of values or less, before sending a completion block if the `Publisher` is finished or fails.

#### Rx Swift?

`Publishers` and `Subscribers` may seem very similar to [RxSwift](https://github.com/ReactiveX/RxSwift)'s Reactive, `Observable`-based patterns, and you're not wrong if you thought they were. [This blog goes deep into the differences between the two](https://medium.com/q42-engineering/swift-combine-framework-a082b1e23f2a), and actually quickly outlines ways to use them together. With the Combine framework, it's now possible for applications to build reactive components entirely natively, without pulling in a 3rd party library. And because Combine is built by Apple, you can trust their attention to performance will shine through.

## Taking Combine for a Spin

Swift provides us with many types of Publishers out of the box. See Apple’s documentation for a full list of available Publishers. For this blog, we’ll be using the ```Sequence``` publisher to see Combine in action. We’ll also use a few operators to demonstrate how Combine allows you to easily modify or extract information from its Publishers. To begin, we’ll create several publishers and use operators such as ```combineLatest``` and ```zip``` to modify the outputs. Here is a snippet of the code:

```
var cityArray = ["Atlanta", "Columbus ", "DC Metro", "Philly", "Charlotte", "Denver", "Richmond"]

let allPublishers = Publishers.Sequence<[[String]], Error>(sequence: [cityArray])
let dallasPublisher = Publishers.Sequence<[[String]], Error>(sequence: [["Dallas"]])
```

We've just created 2 publishers, but now with Combine, we can combine their outputs into one. Combine makes this pretty simple. Let's start by adding the output of ```dallasPublisher``` to ```allPublishers ``` by using the ```combineLatest``` operator:

```
let allPublishers = Publishers.Sequence<[[String]], Error>(sequence: [cityArray])
    .combineLatest(dallasPublisher) { (existingPub, newCityPub) in
        return existingPub + newCityPub
    } 
```
Once we've set up our publisher, we can grab the output by subscribing to the publisher. Combine offers 4 different types of subscribers:  

  * Key Path Assignment  
  * Sinks  
  * Subjects  
  * SwiftUI  

In this demo, we'll be using ```sink```:  

```
allPublishers.sink { (cities) in  
  print(cities)
}

//Output: ["Atlanta", "Columbus ", "DC Metro", "Philly", "Charlotte", "Denver", "Richmond", "Dallas"]
```

As you can see, the output contains the city of Dallas even though our original list didn't have it. Pretty neat for a few lines of code!

Let's continue by adding the output of the publisher to ```allPublishers``` using ```.zip```:

```
 let allPublishers = Publishers.Sequence<[[String]], Error>(sequence: [cityArray])
    	.zip(dallasPublisher)

```
```combinedLatest``` gave us the ability to combine the output of both publishers, however ```zip``` provides us with a tuple containing the outputs of both publishers:

```
(["Atlanta", "Columbus ", "DC Metro", "Philly", "Charlotte", "Denver", "Richmond"], ["Dallas"])

```

Now, let's see how Combine will facilitate working with data from asynchronous calls. For purproses of this blog, we'll simulate an asynchronous call using a ```Timer``` that will run every 5 seconds for 5 rounds. After every round (or successful async call), the publisher will receive a new city and notify the subscriber. The subscriber will then pull the new data (```Publisher``` will provide the data in a tuple since we are using the ```zip``` operator) and add it to our exisiting city array. Let's see how this works in code:

```
let newCityArray = ["Honolulu", "San Diego", "New Orleans", "Seattle", "LA"]

let newCityPublisher = Publishers.Sequence<[String], Error>(sequence: [newCityArray[runCount]])
        
let allPublishers = Publishers.Sequence<[[String]], Error>(sequence: [cityArray])
    .combineLatest(dallasPublisher) { (existingPub, newCityPub) in
        return existingPub + newCityPub
    }
    .zip(newCityPublisher)
    
allPublishers.sink { (cities) in
    self.addToCityArray(city: cities.1)
    print(cities)
}
```

Output:  

```  
Round 1:  
(["Atlanta", "Columbus ", "DC Metro", "Philly", "Charlotte", "Denver", 
"Richmond", "Dallas", "Jacksonville", "Boston"], "Honolulu")

Round 2:  
(["Atlanta", "Columbus ", "DC Metro", "Philly", "Charlotte", "Denver", 
"Richmond", "Honolulu", "Dallas", "Jacksonville", "Boston"], "San Diego")

Round 3:  
(["Atlanta", "Columbus ", "DC Metro", "Philly", "Charlotte", "Denver", 
"Richmond", "Honolulu", "San Diego", "Dallas", "Jacksonville", "Boston"], "New Orleans")

Round 4:  
(["Atlanta", "Columbus ", "DC Metro", "Philly", "Charlotte", "Denver",
"Richmond", "Honolulu", "San Diego", "New Orleans", "Dallas", "Jacksonville", 
"Boston"], "Seattle")

Round 5:  
(["Atlanta", "Columbus ", "DC Metro", "Philly", "Charlotte", "Denver",
"Richmond", "Honolulu", "San Diego", "New Orleans", "Seattle", "Dallas", 
"Jacksonville", "Boston"], "LA")
```

After each round, we can see that the city array includes the city obtained in the prior "async call". Additionally, the output provides a new city in the tuple. While this example is fairly simple, it shows how Combine streamlines this process!

[Our full code for this test drive is available here](https://github.com/fgehy/Combine-iOS-Blogfest). Feel free to fork or open a PR if you're interested!

## Putting it All Together

Apple's new Combine Framework should make writing and maintaining asynchronous, data-driven code much easier going forward. Unlike similar functionality available in some open source frameworks already in existence, Apple's newest framework is designed from the ground up to be entirely performance optimized, and built to work well with existing Swift types and code. Best of all, the framework is light enough that you don't need to adopt it everywhere in your applications by tomorrow. Like Swift UI, you can build the framework into small parts of your app without forcing your development team to focus their efforts on a complete overhaul. In particular, you should consider adopting Combine for areas like: 

  * Networking operations
  * Notification Center
  * Nested Callbacks
  * Key Value Observing
  * Dispatch Groups

These should be good spots to reap some benefits without breaking the bank. [WWDC 2019 offered several sessions on Combine this year](https://developer.apple.com/videos/wwdc2019/?q=combine) and we expect to see this framework mature into a tool commonly used in most enterprise applications. Combine has not been fully integrated into the early betas of Xcode 11 and several operators and features described in the talks weren't available at the time of this writing. That said, it's definitely not too early to begin exploring what the framework will have to offer this fall and ways to integrate the new Combine framework in your applications.

## About the Authors

Fabrice Géhy is a CapTech consultant based in the Atlanta, GA area. He has a passion for mobile development, namely iOS, and strives to incorporate proven patterns and practices into his work.

Allen White is a Senior Consultant based in the Columbus, OH area. He has a passion for writing sound software and seeing projects across the finish line. In his spare time, Allen enjoys sailing, studying Bitcoin, and spending time with his daughter.




