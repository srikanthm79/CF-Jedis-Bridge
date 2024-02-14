# CF-Jedis-Bridge
# Using JedisManager.cfc

## Overview
Instructions on using `JedisManager.cfc` to manage caching with Jedis in ColdFusion. Follow the steps below to initialize the Jedis settings, set configuration values, and utilize the caching methods provided.

---

## Step 1: Set Jedis Configuration Values

Ensure that the necessary Jedis configuration values are set in `JedisSettings.json`. This file contains configuration parameters such as host, port, and other relevant settings required for connecting to the Redis server.

## Step 2: Initialize JedisManager.cfc

1. Create an instance of `JedisManager.cfc`.
2. Call the `init()` function to load settings.

```cfml
// Instantiate JedisManager.cfc
jedisManager = new JedisManager();

// Initialize Jedis settings
jedisManager.init();
```

## Step 3: Using Cache Methods

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

---

## Sample Implementation

Refer to `test.cfm` for a sample implementation demonstrating the usage of `JedisManager.cfc` and its caching methods.

---

Follow these steps to effectively utilize `JedisManager.cfc` for caching purposes in your ColdFusion application.