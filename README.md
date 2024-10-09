# CF-Jedis-Bridge

## Overview
A simple and straight-forward library to setup and manage Redis connections in Adobe ColdFusion, exposing the built-in Jedis library. 

This document provides instructions on using `JedisManager.cfc` to manage caching with Jedis in ColdFusion. Follow the steps below to initialize the Jedis settings, set configuration values, and utilize the caching methods provided.

## Step 1: Install

If you're developing on this library, run `box install` to install the local development dependencies to run tests and build documentation (coming soon)

## Step 2: Set Jedis Configuration Values

Ensure that the necessary Jedis configuration values are set in `JedisSettings.json`. This file contains configuration parameters such as host, port, and other relevant settings required for connecting to the Redis server.

## Step 3: Initialize JedisManager.cfc

Create an instance of `JedisManager.cfc` and initialise

```cfml
// Instantiate JedisManager.cfc
jedisManager = new JedisManager();
```

or

```cfml
// Create and initialise JedisManager.cfc
jedisManager = createObject("component","JedisManager");
jedisManager.init();
```
or

```cfml
// Create and initialise JedisManager.cfc
jedisManager = createObject("component","JedisManager");
config = {};
config['jedisServerName'] = "localhost";
config['jedisServerPort'] = 6379;
config['jedisMaxTotalPool'] = 10;
config['jedisMaxIdlePool'] = 5;
cacheDurationInSeconds'] = 600;

jedisManager.init(config=config);
```
## Step 4: Use Cache Methods

### cacheGet
Use the `cacheGet` method to retrieve the cached value for the given cache key.

```cfml
// Retrieve cached value for the given cache key
cachedValue = jedisManager.cacheGet(cacheKey);
```

### cacheExists
Use the `cacheExists` method to check if a value exists in the cache for the given cache key.

```cfml
// Check if a value exists in the cache for the given cache key
exists = jedisManager.cacheExists(cacheKey);
```

### cacheInsert
Use the `cacheInsert` method to insert a value with the given key for a specified duration.

```cfml
// Insert a value with the given key for a specified duration
jedisManager.cacheInsert(cacheKey, cacheValue, durationInSeconds);
```

## Sample Implementation

Refer to `test.cfm` for a sample implementation demonstrating the usage of `JedisManager.cfc` and its caching methods.

Refer to `test1.cfm` for the user-specific cache key implementation utilizing `jedismanager.cfc` and its caching methods. This file generates 500 users and stores user-related IDs and data, which can serve as keys for the cache functions. Additionally, this file can be utilized for conducting load testing operations.

Follow these steps to effectively utilize `JedisManager.cfc` for caching purposes in your ColdFusion application.

## JedisManager Documentation

To access comprehensive documentation about the `JedisManager` component:

Execute the following command in CommandBox once:
```cfml
run-script build-docs
```
 Please navigate to `servername:portnumber/docs`. This directory contains detailed information to help you better understand the functionality and usage of `JedisManager`.
