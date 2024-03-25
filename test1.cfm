<cftry>
    <cfif not structKeyExists(application, "users")>
         <cfset application.users = []>
         <cfloop from="1" to="500" index="i">
            <cfset variables.userDetails = {id=i, data=createUUID()}>
            <cfset arrayAppend(application.users,variables.userDetails)>
         </cfloop>
    </cfif>

    <cfset variables.userSession =  application.users[randRange(1, 500)]>
    <cfoutput>
        <cfset variables.redisObj = new JedisManager()>
        <cfset variables.redisObj.init(reset=true)>
        
        <!--- Verify whether data exists in the cache for the specified key and set it with a duration of 30 seconds --->
        <cfif not variables.redisObj.cacheExists(cacheKey="cacheTest:#variables.userSession.data#")>
            <p> Cache does not exist, thus data is being set in the cache for the "cacheTest:#variables.userSession.data#" key</p>
            <cfset variables.redisObj.cacheinsert(cacheKey="cacheTest:#variables.userSession.data#",dataToCache="This is test string",cacheDurationInSeconds=30)>
        </cfif>
        <p>The cached data is : #redisObj.cacheget(cacheKey='cacheTest:#variables.userSession.data#')#</p>

         <!--- Delete they key and the data from cache--->
        <cfset variables.redisObj.cacheClear(cacheKey="cacheTest:#variables.userSession.data#")>
        <p>Deleted the key "cacheTest:#variables.userSession.data#" from cache</p>
    </cfoutput>
    <cfcatch type="any">
        <cfoutput>
            <p>We have error in setting or getting the data from the cache : #cfcatch.message#</p>
        </cfoutput>
    </cfcatch>
</cftry>
