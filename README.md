# CF-Jedis-Bridge

## Overview
A simple and straight-forward library to setup and manage Redis connections in Adobe ColdFusion, exposing the built-in Jedis library. 

This document provides instructions on using `JedisManager.cfc` to manage caching with Jedis in ColdFusion. Follow the steps below to initialize the Jedis settings, set configuration values, and utilize the caching methods provided.

## Step 0: Install

If you're developing on this library, run `box install` to install the local development dependencies to run tests and build documentation (coming soon)

## Step 1: Set Jedis Configuration Values

Ensure that the necessary Jedis configuration values are set in `JedisSettings.json`. This file contains configuration parameters such as host, port, and other relevant settings required for connecting to the Redis server.

## Step 2: Initialize JedisManager.cfc

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

## Step 3: Use Cache Methods

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

Follow these steps to effectively utilize `JedisManager.cfc` for caching purposes in your ColdFusion application.