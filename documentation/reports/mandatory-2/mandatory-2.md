# How we use Version Control

Mathias

# How are you DevOps?

Valde

# Software Quality

krelle

# Monitoring Realization 

One of the main things we found out was, that monitoring is only useful when it's actually configured properly. In the beginning we got alot of errors, which in reality were not "real" errors. For example we set up our response time to be way too low, so the requests appeared as errors, even though it was just because the server could not answer fast enough. We also had endpoints where we expected JSON, even though it actually returned HTML, which made it all look a whole lot more unstable, than it was in reality, therefore it was a bit harder to rely on at the start.

We did actually catch a very big error partly through our monitoring. We had in the past set up a cronjob in our pipeline which ran every third day. But because our pipeline setup had changed since, the cronjob now ran with the outdated setup and caused alot of server downtime. Which we did not notice under development, but the monitoring showed these unexplained downtimes and helped us realize the cronjob was at fault. We ended up remove the whole cronjob out of spite.

We also adjusted some of our tests along the way, we once had an endpoint which should monitor for error handling, but the monitor reported it as an error when it recieved a code 400. Which was the correct response and it seems obvious now, but something that slipped our mind back then, because the logic is effectively reversed compared to the other endpoints.

So to conclude this realization, we found that monitoring does not just mean testing for errors, but actualy define what the correct behaviour should be. After we adjusted our thresholds and tests, the monitoring became much more useful and gave os a greater view of our system.