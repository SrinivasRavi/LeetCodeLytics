# LeetCodeLytics – Claude Build Guide

## v1.1 After testing thoughts
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
