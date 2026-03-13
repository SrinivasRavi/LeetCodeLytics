


# LeetCodeLytics – Claude Build Guide


# After testing 2.2
1. Still getting that "Please adopt containerBackground API". It's what I see on the widget already placed on my homescreen and when I try to add widgets. I can add the widget to screen, sure. But I just see black background and that text. What have you done till now to address this error? I am complaining to you since v2.0.0 about this.
2. I also saw these warnings in Xcode. Not sure if relevant. Check 5.png for details.
3. Also app version still reads 1.0. What is up here? Am I even deploying the app along with widget every time? I want to. 
4. I also got the below error in Xcode once again after running v2.2.0. I got the same after v2.0 hence I asked you to do memory leaks check.
"The app “com.leetcodelytics.app.widget” has been killed by the operating system because it is using too much memory.
Domain: IDEDebugSessionErrorDomain
Code: 11
Recovery Suggestion: Use a memory profiling tool to track the process memory usage.
User Info: {
    DVTErrorCreationDateKey = "2026-03-13 17:40:30 +0000";
    IDERunOperationFailingWorker = DBGLLDBLauncher;
}
--

Event Metadata: com.apple.dt.IDERunOperationWorkerFinished : {
    "device_identifier" = "00008110-0014259211F2801E";
    "device_isCoreDevice" = 1;
    "device_isWireless" = 1;
    "device_model" = "iPhone14,2";
    "device_osBuild" = "26.3 (23D127)";
    "device_platform" = "com.apple.platform.iphoneos";
    "device_thinningType" = "iPhone14,2";
    "dvt_coredevice_version" = "443.24";
    "dvt_coresimulator_version" = "1010.15";
    "dvt_mobiledevice_version" = "1818.13.1";
    "launchSession_schemeCommand" = Run;
    "launchSession_state" = 2;
    "launchSession_targetArch" = arm64;
    "operation_duration_ms" = 495908;
    "operation_errorCode" = 11;
    "operation_errorDomain" = IDEDebugSessionErrorDomain;
    "operation_errorWorker" = DBGLLDBLauncher;
    "operation_name" = IDERunOperationWorkerGroup;
    "param_debugger_attachToExtensions" = 0;
    "param_debugger_attachToXPC" = 1;
    "param_debugger_type" = 3;
    "param_destination_isProxy" = 0;
    "param_destination_platform" = "com.apple.platform.iphoneos";
    "param_diag_113575882_enable" = 0;
    "param_diag_MainThreadChecker_stopOnIssue" = 0;
    "param_diag_MallocStackLogging_enableDuringAttach" = 0;
    "param_diag_MallocStackLogging_enableForXPC" = 0;
    "param_diag_allowLocationSimulation" = 0;
    "param_diag_checker_tpc_enable" = 0;
    "param_diag_gpu_frameCapture_enable" = 0;
    "param_diag_gpu_shaderValidation_enable" = 0;
    "param_diag_gpu_validation_enable" = 1;
    "param_diag_guardMalloc_enable" = 0;
    "param_diag_memoryGraphOnResourceException" = 0;
    "param_diag_mtc_enable" = 0;
    "param_diag_queueDebugging_enable" = 1;
    "param_diag_runtimeProfile_generate" = 0;
    "param_diag_sanitizer_asan_enable" = 0;
    "param_diag_sanitizer_tsan_enable" = 0;
    "param_diag_sanitizer_tsan_stopOnIssue" = 0;
    "param_diag_sanitizer_ubsan_enable" = 0;
    "param_diag_sanitizer_ubsan_stopOnIssue" = 0;
    "param_diag_showNonLocalizedStrings" = 0;
    "param_diag_viewDebugging_enabled" = 0;
    "param_diag_viewDebugging_insertDylibOnLaunch" = 1;
    "param_install_style" = 2;
    "param_launcher_UID" = 2;
    "param_launcher_allowDeviceSensorReplayData" = 0;
    "param_launcher_kind" = 0;
    "param_launcher_style" = 99;
    "param_launcher_substyle" = 0;
    "param_runnable_appExtensionHostRunMode" = 0;
    "param_runnable_productType" = "com.apple.product-type.app-extension";
    "param_structuredConsoleMode" = 0;
    "param_testing_launchedForTesting" = 0;
    "param_testing_suppressSimulatorApp" = 0;
    "param_testing_usingCLI" = 0;
    "sdk_canonicalName" = "iphoneos18.5";
    "sdk_osVersion" = "18.5";
    "sdk_variant" = iphoneos;
}
--


System Information

macOS Version 15.7.3 (Build 24G419)
Xcode 16.4 (23792) (Build 16F6)
Timestamp: 2026-03-13T23:10:30+05:30
"

# After testing 2.0
1. I got this in xcode as soon as I deployed 
"SendProcessControlEvent:toPid: encountered an error: Error Domain=com.apple.dt.deviceprocesscontrolservice Code=8 "Failed to show Widget 'com.leetcodelytics.app.widget' error: Error Domain=FBSOpenApplicationServiceErrorDomain Code=1 "The request to open "com.apple.springboard" failed." UserInfo={NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace)., BSErrorCodeDescription=RequestDenied, NSUnderlyingError=0x106a6df80 {Error Domain=SBAvocadoDebuggingControllerErrorDomain Code=2 "Please specify the widget kind in the scheme's Environment Variables using the key '_XCWidgetKind' to be one of: 'DCCStreak','LeetCodeLarge','LeetCodeMedium','SolvedStreak'" UserInfo={NSLocalizedDescription=Please specify the widget kind in the scheme's Environment Variables using the key '_XCWidgetKind' to be one of: 'DCCStreak','LeetCodeLarge','LeetCodeMedium','SolvedStreak'}}, FBSOpenApplicationRequestID=0xbaf7, NSLocalizedDescription=The request to open "com.apple.springboard" failed.}." UserInfo={NSLocalizedDescription=Failed to show Widget 'com.leetcodelytics.app.widget' error: Error Domain=FBSOpenApplicationServiceErrorDomain Code=1 "The request to open "com.apple.springboard" failed." UserInfo={NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace)., BSErrorCodeDescription=RequestDenied, NSUnderlyingError=0x106a6df80 {Error Domain=SBAvocadoDebuggingControllerErrorDomain Code=2 "Please specify the widget kind in the scheme's Environment Variables using the key '_XCWidgetKind' to be one of: 'DCCStreak','LeetCodeLarge','LeetCodeMedium','SolvedStreak'" UserInfo={NSLocalizedDescription=Please specify the widget kind in the scheme's Environment Variables using the key '_XCWidgetKind' to be one of: 'DCCStreak','LeetCodeLarge','LeetCodeMedium','SolvedStreak'}}, FBSOpenApplicationRequestID=0xbaf7, NSLocalizedDescription=The request to open "com.apple.springboard" failed.}., NSUnderlyingError=0x106a6dec0 {Error Domain=FBSOpenApplicationServiceErrorDomain Code=1 "The request to open "com.apple.springboard" failed." UserInfo={NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace)., BSErrorCodeDescription=RequestDenied, NSUnderlyingError=0x106a6df80 {Error Domain=SBAvocadoDebuggingControllerErrorDomain Code=2 "Please specify the widget kind in the scheme's Environment Variables using the key '_XCWidgetKind' to be one of: 'DCCStreak','LeetCodeLarge','LeetCodeMedium','SolvedStreak'" UserInfo={NSLocalizedDescription=Please specify the widget kind in the scheme's Environment Variables using the key '_XCWidgetKind' to be one of: 'DCCStreak','LeetCodeLarge','LeetCodeMedium','SolvedStreak'}}, FBSOpenApplicationRequestID=0xbaf7, NSLocalizedDescription=The request to open "com.apple.springboard" failed.}}}
Domain: DTXMessage
Code: 1
User Info: {
    DVTErrorCreationDateKey = "2026-03-13 16:59:01 +0000";
}
--
SendProcessControlEvent:toPid: encountered an error: Error Domain=com.apple.dt.deviceprocesscontrolservice Code=8 "Failed to show Widget 'com.leetcodelytics.app.widget' error: Error Domain=FBSOpenApplicationServiceErrorDomain Code=1 "The request to open "com.apple.springboard" failed." UserInfo={NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace)., BSErrorCodeDescription=RequestDenied, NSUnderlyingError=0x106a6df80 {Error Domain=SBAvocadoDebuggingControllerErrorDomain Code=2 "Please specify the widget kind in the scheme's Environment Variables using the key '_XCWidgetKind' to be one of: 'DCCStreak','LeetCodeLarge','LeetCodeMedium','SolvedStreak'" UserInfo={NSLocalizedDescription=Please specify the widget kind in the scheme's Environment Variables using the key '_XCWidgetKind' to be one of: 'DCCStreak','LeetCodeLarge','LeetCodeMedium','SolvedStreak'}}, FBSOpenApplicationRequestID=0xbaf7, NSLocalizedDescription=The request to open "com.apple.springboard" failed.}." UserInfo={NSLocalizedDescription=Failed to show Widget 'com.leetcodelytics.app.widget' error: Error Domain=FBSOpenApplicationServiceErrorDomain Code=1 "The request to open "com.apple.springboard" failed." UserInfo={NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace)., BSErrorCodeDescription=RequestDenied, NSUnderlyingError=0x106a6df80 {Error Domain=SBAvocadoDebuggingControllerErrorDomain Code=2 "Please specify the widget kind in the scheme's Environment Variables using the key '_XCWidgetKind' to be one of: 'DCCStreak','LeetCodeLarge','LeetCodeMedium','SolvedStreak'" UserInfo={NSLocalizedDescription=Please specify the widget kind in the scheme's Environment Variables using the key '_XCWidgetKind' to be one of: 'DCCStreak','LeetCodeLarge','LeetCodeMedium','SolvedStreak'}}, FBSOpenApplicationRequestID=0xbaf7, NSLocalizedDescription=The request to open "com.apple.springboard" failed.}., NSUnderlyingError=0x106a6dec0 {Error Domain=FBSOpenApplicationServiceErrorDomain Code=1 "The request to open "com.apple.springboard" failed." UserInfo={NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace)., BSErrorCodeDescription=RequestDenied, NSUnderlyingError=0x106a6df80 {Error Domain=SBAvocadoDebuggingControllerErrorDomain Code=2 "Please specify the widget kind in the scheme's Environment Variables using the key '_XCWidgetKind' to be one of: 'DCCStreak','LeetCodeLarge','LeetCodeMedium','SolvedStreak'" UserInfo={NSLocalizedDescription=Please specify the widget kind in the scheme's Environment Variables using the key '_XCWidgetKind' to be one of: 'DCCStreak','LeetCodeLarge','LeetCodeMedium','SolvedStreak'}}, FBSOpenApplicationRequestID=0xbaf7, NSLocalizedDescription=The request to open "com.apple.springboard" failed.}}}
Domain: DTXMessage
Code: 1
--


System Information

macOS Version 15.7.3 (Build 24G419)
Xcode 16.4 (23792) (Build 16F6)
Timestamp: 2026-03-13T22:29:01+05:30"

2. While trying to add widget I saw a banner on all widgets "Please adopt containerBackground API". See PersonalNotes > 4.png
3. I see Version is 1.0 but wasn't it supposed to be 2.0? 
4. App seems to be same as v1.6.1. And Dashboard is working when I pull to refresh.
5. I am disappointed at these issues, could this have been caught in some tests? If yes, can you atleast add the tests now? Audit yourself thoroughly.



## Response to your clarification
No No No! I don't want my widgets to be stale. Is there absolute no way for the widgets to autorefresh every 15 mins or even every 60 mins? My inspiration for all this widgets is duolingo where I need to access app to change my streak. Here the streak change happens in the 3rd party website - Leetcode. If you think my ask is out of ordinary, maybe we can punt this feature to future versions. We can then just focus on existing plan you have.

## Response to your questions
1. What's the difference between fetching it from URL at render time vs caching it? Also what's the significance of this profile pic right now in v2.0? If it's for widget, I have given you the png in PersonalNotes > astroLeet.png. Now forget about my profile pic. Ofcourse load my pfp in dashboard just like how you do in v1.6.1. The pic is just to make widget lively. In fact use this same pic for the app logo. (In future, I will be giving more versions of the same pic. For different urgency of streak being at the risk of being lost AND maybe the astronaut in the pic can become conquerer of more worlds as the streak length increases. I don't know, this is a WIP and definitely out of scope for v2.0. Right now think of the logo as a placeholder for such different logos)
2. However many weeks fit the widget height. It's okay to butcher initially, we can refine it once I see some output.
3. Widget and app are supposed to update at the same time right? If yes, then you can  skip showing when it was last updated in widget, I can always open app and check. If not, why are widget and app not in sync?
4. Try including it, lets see how you manage to fit.


## Thoughts on v1.6.0
I have a final ask for UI in Dashboard tab. I like how these things are bold "Problems Solved", "Acceptance Rate", "Badges". I would like the same for streaks called "Streaks". Also make "Last 52 weeks" in the same style.

In streaks, make "Daily Question Streak" -> "Daily Question", "Solved Streak" -> "Solved (any question)"

## Thoughts on v2.0 design.

I see you jumped straight to implementation when I asked you to plan. I am not sure we have even ironed out what the widgets should actually be. I saw in the design you made these things:
 SmallWidgetView: username + total solved + "🔥N ⚡N"
 MediumWidgetView: username, E/M/H counts with color dots, both streaks
 LargeWidgetView: MediumWidgetView content + 10-week heatmap grid using WidgetData.recentCalendar

 I don't understand what "🔥N ⚡N" is. I don't see the point of my username being visible to me. It's not useful at all. Here are the things I want:
 SmallWidgetView 1: Logo(this will be my profile pic in leetcode for now), Solved Streak (eg. 10 days)
  SmallWidgetView 2: Logo(this will be my profile pic in leetcode for now), Daily Question Streak (eg. 10 days)
 MediumWidgetView: Logo(this will be my profile pic in leetcode for now), Solved Streak (eg. 10 days), Daily Question Streak (eg. 8 days). Optional if space permits: E/M/H counts with color dots.
 LargeWidgetView: MediumWidgetView content (including optional) + 10-week heatmap grid using WidgetData.recentCalendar 

 In the future versions (please don't attempt it now, put it in backlogs), I want to make the widget background and the logo to be dynamic. In duolingo, if you miss streak, the duo bird is dead, and as day proceeds if today's streak is not completed, the duo bird gets restless (in logo) and background changes. I want that but for the astronaut logo I got. I will design those independently later, hence the placeholder standard logo of my leetcode profile pic for now. Telling you this so you understand my ultimate ask and work towards it in v2.0. 

 I also added 2 SmallWidgetView because I want 2 different small widgets to try. But remember I am mainly eyeing Medium widget for my motivation to do leetcode daily. In fact, I will go out on a limb and say, the Medium Widget in Duolingo is my reason to be motivated for Leetcode for past 570 days. hence I started building this app. Just for this Medium Widget. 

 And ofcourse, pressing on a widget should open the app and in Dashboard tab as default of course.

Talk about this higher level design I talked about, once I confirm we can think about lower level details.

## I got this XCode error. Help! Is it a problem in the project or the deployed app? In any case using too much memory seems bad. Is there a memory leak in the app or the project? 

The app “LeetCodeLytics” has been killed by the operating system because it is using too much memory.
Domain: IDEDebugSessionErrorDomain
Code: 11
Recovery Suggestion: Use a memory profiling tool to track the process memory usage.
User Info: {
    DVTErrorCreationDateKey = "2026-03-13 10:27:57 +0000";
    IDERunOperationFailingWorker = DBGLLDBLauncher;
}
--

Event Metadata: com.apple.dt.IDERunOperationWorkerFinished : {
    "device_identifier" = "00008110-0014259211F2801E";
    "device_isCoreDevice" = 1;
    "device_model" = "iPhone14,2";
    "device_osBuild" = "26.3 (23D127)";
    "device_platform" = "com.apple.platform.iphoneos";
    "device_thinningType" = "iPhone14,2";
    "dvt_coredevice_version" = "443.24";
    "dvt_coresimulator_version" = "1010.15";
    "dvt_mobiledevice_version" = "1818.13.1";
    "launchSession_schemeCommand" = Run;
    "launchSession_state" = 2;
    "launchSession_targetArch" = arm64;
    "operation_duration_ms" = 2199827;
    "operation_errorCode" = 11;
    "operation_errorDomain" = IDEDebugSessionErrorDomain;
    "operation_errorWorker" = DBGLLDBLauncher;
    "operation_name" = IDERunOperationWorkerGroup;
    "param_debugger_attachToExtensions" = 0;
    "param_debugger_attachToXPC" = 1;
    "param_debugger_type" = 3;
    "param_destination_isProxy" = 0;
    "param_destination_platform" = "com.apple.platform.iphoneos";
    "param_diag_113575882_enable" = 0;
    "param_diag_MainThreadChecker_stopOnIssue" = 0;
    "param_diag_MallocStackLogging_enableDuringAttach" = 0;
    "param_diag_MallocStackLogging_enableForXPC" = 1;
    "param_diag_allowLocationSimulation" = 1;
    "param_diag_checker_tpc_enable" = 1;
    "param_diag_gpu_frameCapture_enable" = 0;
    "param_diag_gpu_shaderValidation_enable" = 0;
    "param_diag_gpu_validation_enable" = 0;
    "param_diag_guardMalloc_enable" = 0;
    "param_diag_memoryGraphOnResourceException" = 0;
    "param_diag_mtc_enable" = 1;
    "param_diag_queueDebugging_enable" = 1;
    "param_diag_runtimeProfile_generate" = 0;
    "param_diag_sanitizer_asan_enable" = 0;
    "param_diag_sanitizer_tsan_enable" = 0;
    "param_diag_sanitizer_tsan_stopOnIssue" = 0;
    "param_diag_sanitizer_ubsan_enable" = 0;
    "param_diag_sanitizer_ubsan_stopOnIssue" = 0;
    "param_diag_showNonLocalizedStrings" = 0;
    "param_diag_viewDebugging_enabled" = 1;
    "param_diag_viewDebugging_insertDylibOnLaunch" = 1;
    "param_install_style" = 2;
    "param_launcher_UID" = 2;
    "param_launcher_allowDeviceSensorReplayData" = 0;
    "param_launcher_kind" = 0;
    "param_launcher_style" = 99;
    "param_launcher_substyle" = 0;
    "param_runnable_appExtensionHostRunMode" = 0;
    "param_runnable_productType" = "com.apple.product-type.application";
    "param_structuredConsoleMode" = 1;
    "param_testing_launchedForTesting" = 0;
    "param_testing_suppressSimulatorApp" = 0;
    "param_testing_usingCLI" = 0;
    "sdk_canonicalName" = "iphoneos18.5";
    "sdk_osVersion" = "18.5";
    "sdk_variant" = iphoneos;
}
--


System Information

macOS Version 15.7.3 (Build 24G419)
Xcode 16.4 (23792) (Build 16F6)
Timestamp: 2026-03-13T15:57:57+05:30

## -------------

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