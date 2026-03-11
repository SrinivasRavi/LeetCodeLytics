# LeetCodeLytics – Claude Build Guide

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


## v1.2 Thoughts after v1.2 testing
1. Can you split the 3rd tile with streaks into 2? Now: "DCC Streak", "Current Streak", "Max Streak", "Active Days". I want : "DCC Streak", "Solved Streak" (instead of Current. just name change) in a tile. This tile has nothing to do with "last 52 weeks" right?
2. In another tile I want: "Max Streak", "Active Days". Follow that tile with "Submissions Activity". These 2 tiles are for "last 52 weeks". Please indicate that. "Acceptance Rate" tile can be moved after "Problems Solved" tile.
3. Badges. What is the problem again? I do not understand your concern? It's no longer lower priority. Investigate and suggest fixes.
4. Good job explaining about tokens. Keep it as is. For now accept this token since it expires 3/25. Keep it editable in app. "LEETCODE_SESSION" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfYXV0aF91c2VyX2lkIjoiMTIzNTcyMiIsIl9hdXRoX3VzZXJfYmFja2VuZCI6ImFsbGF1dGguYWNjb3VudC5hdXRoX2JhY2tlbmRzLkF1dGhlbnRpY2F0aW9uQmFja2VuZCIsIl9hdXRoX3VzZXJfaGFzaCI6ImU3MDZjOTRiODQwMGY2YjhiZDRhMjc1NTQ5YjllZTJlZmIwMTM5NTNhYWQyZjUwMmEzZmI3Zjc3MGJiODg1YmEiLCJzZXNzaW9uX3V1aWQiOiI3ZTlhYTY5MiIsImlkIjoxMjM1NzIyLCJlbWFpbCI6InNyaW5pdmFzcm9oYW4xMUBnbWFpbC5jb20iLCJ1c2VybmFtZSI6InNwYWNld2FuZGVyZXIiLCJ1c2VyX3NsdWciOiJzcGFjZXdhbmRlcmVyIiwiYXZhdGFyIjoiaHR0cHM6Ly9hc3NldHMubGVldGNvZGUuY29tL3VzZXJzL3NwYWNld2FuZGVyZXIvYXZhdGFyXzE1NTM0NzY2NTMucG5nIiwicmVmcmVzaGVkX2F0IjoxNzczMjMzMDcxLCJpcCI6IjIwMi4xNDEuMzYuMjU1IiwiaWRlbnRpdHkiOiJkZjRiZjA0ZjliZjdiNmFmMDllM2U5NDE3OTczMzc3MCIsImRldmljZV93aXRoX2lwIjpbIjBmYTc3OTc4MWYyNTE2OGQ5MjAxMGFlMGI1NmExNWFmIiwiMjAyLjE0MS4zNi4yNTUiXSwiX3Nlc3Npb25fZXhwaXJ5IjoxMjA5NjAwfQ.q1VKc7iAfld8q1_QvbGxryTCtmod8vDq_S6Ugv7qpCE"