# LeetCodeLytics – Claude Build Guide

## Thoughts after v1.5.4 testing
I see you just removed the banner. Do you realize my complaint was not about the banner, but about refresh not happening when pulled to refresh. Just removing the banner fixes nothing. From my testing, functionally v1.5.3 and v1.5.4 are the same minus the banner. Even DCC streak is being set to 0 when refresh fails. So in short, pull to refresh is still broken for dashboard tab.

## Thoughts after v1.5.3 testing
1. Good job, I can see the dashboard with latest information. I like that we refresh everytime we change the tab, and also when we pull to refresh. Good design. Also good job in identifying the datatype problem and fixing it. Also good job in incorporating feedbacks I have provided till now.
2. While Submissions tab's pull to refresh works flawlessly everytime, Dashboard's pull to refresh is buggy. Problem is exclusively in "Dashboard" tab. Dashboard refreshes when I switch to that tab, but not during pull to refresh. When I do pull to refresh, I see "Refresh failed: cancelled". Also the Daily Question Streak becomes 0. It should be 1 at the time of testing. I have tried refreshing multiple times with pull to refresh, but no change - the banner remains and DCC is 0. It's not the internet connection, because it immediately updates when I switch tabs to refresh.

## Thoughts after v1.5.1 testing
1. I ran once again in xcode connecting my iphone. I could see the banner "Refresh failed: Failed to decode response: The data couldn't be read because it isn't in the correct format." I also took your help to form Postman collection and test the apis manually. I could see the latest responses. I saved the collection with responses in PersonalNotes > ResponsesLeetCodeLytics.postman_collection.json. I have saved responses and all of them are saved as Success_Mar13. Only 1 query needing the csrf token and leetcode session has 3 saved responses. The ones marked Success_Before* and Success_After* clearly show the DCC streak is updated too as expected. I am giving you the session and token information, persist in the code so that we could see the DCC streak in the app too.

LEETCODE_SESSION: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfYXV0aF91c2VyX2lkIjoiMTIzNTcyMiIsIl9hdXRoX3VzZXJfYmFja2VuZCI6ImFsbGF1dGguYWNjb3VudC5hdXRoX2JhY2tlbmRzLkF1dGhlbnRpY2F0aW9uQmFja2VuZCIsIl9hdXRoX3VzZXJfaGFzaCI6ImU3MDZjOTRiODQwMGY2YjhiZDRhMjc1NTQ5YjllZTJlZmIwMTM5NTNhYWQyZjUwMmEzZmI3Zjc3MGJiODg1YmEiLCJzZXNzaW9uX3V1aWQiOiI3ZTlhYTY5MiIsImlkIjoxMjM1NzIyLCJlbWFpbCI6InNyaW5pdmFzcm9oYW4xMUBnbWFpbC5jb20iLCJ1c2VybmFtZSI6InNwYWNld2FuZGVyZXIiLCJ1c2VyX3NsdWciOiJzcGFjZXdhbmRlcmVyIiwiYXZhdGFyIjoiaHR0cHM6Ly9hc3NldHMubGVldGNvZGUuY29tL3VzZXJzL3NwYWNld2FuZGVyZXIvYXZhdGFyXzE1NTM0NzY2NTMucG5nIiwicmVmcmVzaGVkX2F0IjoxNzczMzYzOTM5LCJpcCI6IjIwMi4xNDEuMzYuOCIsImlkZW50aXR5IjoiZGY0YmYwNGY5YmY3YjZhZjA5ZTNlOTQxNzk3MzM3NzAiLCJkZXZpY2Vfd2l0aF9pcCI6WyIwZmE3Nzk3ODFmMjUxNjhkOTIwMTBhZTBiNTZhMTVhZiIsIjIwMi4xNDEuMzYuOCJdLCJfc2Vzc2lvbl9leHBpcnkiOjEyMDk2MDB9.-l6fez0TENoSdxsymS3hzc8Wne_5EZQDjpNE_2kzi6g

csrftoken : eV1JvjNCIh0MSxOL5i0tbg9mnW22xsmc

tldr: things should work. The app is malfunctioning. Giving you a chance to fix things yourself.


## Thoughts after v1.4 testing
1. I like that you added pull to refresh in all tabs without me suggesting that explicitly. I tested it in submissions tab and it works well. I can't get the dashboard to work still. Can you display the values for everything in dashboard over here in terminal (Except calendar of course)? I want to see where is the problem, the graphQL endpoint at Leetcode or in our app.
2. Currently I see "Refresh failed - Showing cached data" in a small persistent banner in "Dashboard" tab.
2. For all streaks, next to the number just say "days" instead of mentioning it in subtext. Also for "Active days" replace it with "Active for". Replace "DCC Streak" with "Daily Question Streak".
3. I haven't tested DCC Streak yet. In some other version. I also want in future version this change -  split "Solved Streak" into 2 -> "Any solved streak" and "Unique solved streak". The former just tracks successfull submissions made in the day. "Unique solved streak" ensures the problem was never solved before. Please don't do it now, it's just so that I don't forget. Maybe create backlog tasks in Claude.md and I will ask you to come to those.

## Thoughts after v1.3 testing
1. Overall I like the changes you made in the UI for most part. Good job and thank you.
2. "Last 52 weeks" is mentioned for both tiles "Max streak, Active days" and "Submission Activity". Maybe have the title as "Last 52 weeks" and combine those 2 tiles?
3. Good job of fetching latest submissions. I had to change to some other tab and come back to "Submissions" tab for it to fetch the latest successful submissions, but I am happy for now. But the dashboard is terribly stale. I can't see it getting updated at all. Why is that? Is the problem with GraphQL api by Leetcode or some different refresh mechanism between Dashboard and Submissions?
4. I haven't tested DCC Streak yet, I will in v1.5. Lets focus v1.4 in making things refresh at least when I change tabs OR as fast as web ui of leetcode does.

## Thoughts after v1.2 testing
1. Can you split the 3rd tile with streaks into 2? Now: "DCC Streak", "Current Streak", "Max Streak", "Active Days". I want : "DCC Streak", "Solved Streak" (instead of Current. just name change) in a tile. This tile has nothing to do with "last 52 weeks" right?
2. In another tile I want: "Max Streak", "Active Days". Follow that tile with "Submissions Activity". These 2 tiles are for "last 52 weeks". Please indicate that. "Acceptance Rate" tile can be moved after "Problems Solved" tile.
3. Badges. What is the problem again? I do not understand your concern? It's no longer lower priority. Investigate and suggest fixes.
4. Good job explaining about tokens. Keep it as is. For now accept this token since it expires 3/25. Keep it editable in app. "LEETCODE_SESSION" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfYXV0aF91c2VyX2lkIjoiMTIzNTcyMiIsIl9hdXRoX3VzZXJfYmFja2VuZCI6ImFsbGF1dGguYWNjb3VudC5hdXRoX2JhY2tlbmRzLkF1dGhlbnRpY2F0aW9uQmFja2VuZCIsIl9hdXRoX3VzZXJfaGFzaCI6ImU3MDZjOTRiODQwMGY2YjhiZDRhMjc1NTQ5YjllZTJlZmIwMTM5NTNhYWQyZjUwMmEzZmI3Zjc3MGJiODg1YmEiLCJzZXNzaW9uX3V1aWQiOiI3ZTlhYTY5MiIsImlkIjoxMjM1NzIyLCJlbWFpbCI6InNyaW5pdmFzcm9oYW4xMUBnbWFpbC5jb20iLCJ1c2VybmFtZSI6InNwYWNld2FuZGVyZXIiLCJ1c2VyX3NsdWciOiJzcGFjZXdhbmRlcmVyIiwiYXZhdGFyIjoiaHR0cHM6Ly9hc3NldHMubGVldGNvZGUuY29tL3VzZXJzL3NwYWNld2FuZGVyZXIvYXZhdGFyXzE1NTM0NzY2NTMucG5nIiwicmVmcmVzaGVkX2F0IjoxNzczMjMzMDcxLCJpcCI6IjIwMi4xNDEuMzYuMjU1IiwiaWRlbnRpdHkiOiJkZjRiZjA0ZjliZjdiNmFmMDllM2U5NDE3OTczMzc3MCIsImRldmljZV93aXRoX2lwIjpbIjBmYTc3OTc4MWYyNTE2OGQ5MjAxMGFlMGI1NmExNWFmIiwiMjAyLjE0MS4zNi4yNTUiXSwiX3Nlc3Npb25fZXhwaXJ5IjoxMjA5NjAwfQ.q1VKc7iAfld8q1_QvbGxryTCtmod8vDq_S6Ugv7qpCE"

## Thoughts after v1.1 testing
1. I think Calendar tab can be removed and the 2 tiles in it can be part of Dashboard.
2. Now: Calendar > Active Days = 108. No need of this stat, since it's already mentioned in 'StreakItem(value: totalActiveDays, icon: "📅", label: "Active Days")'
3. Now: Calendar > Current Streak = 10. It should be: Dashboard > Calendar > Max Streak (days) = 10. (Current streak is actually 0, you should show it too as "Current Streak (days)")
4. Now: Calendar > Submission Activity > March 2025 to Aug 2025 heatmap. It should be: Dashboard > 
5. All things in 2,3,4 are stats for "in the past 1 year", because that's what that is. Please mention that somewhere.
6. Now: Dashboard > Badges. I really like the use of right logos. But it will be helpful to see when I got them. Also I think you gave me 4 100 day annual badges but when in fact I got only 2? I got other badges which you missed. See 1.png. This 6th point is actually minor so low priority. Just tell me if you don't fix it, or struggle to.
7. What am I expected to see in the "Contest" tab? Currently I see "Failed to Load", "Failed to decode response: The data couldn't be read because it isn't in the correct format."
8. No need of "More" tab since the 5 new tabs will be "Dashboard", "Submissions", "Skills", "Settings"
9. Now: Settings > Authentication. My ask - what is the purpose of the Session Cookie and CSRF Token? What is currently blocked because of these? And how should I provide you these? Don't these tokens get expired?
10. Now: Settings > Info> Version. I currently see it as 1.0.0. Shouldn't it reflect 1.1.0? Am I supposed to save anything or it autosaves? I just pressed the "play" button in xcode after you gave 1.1.0. I didn't save anything on my end since you committed them. Please correct my understanding.