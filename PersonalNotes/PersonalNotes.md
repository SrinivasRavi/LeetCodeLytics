# LeetCodeLytics – Claude Build Guide

# After v4.1 testing
0. Settings>Info > last refreshed . this means for data right?
1. I see the "profile picture" and "badges" images don't load easily when I open the app with low latency internet bandwidth. Why are we not persisting these things once and for all (I mean till username is changed). When we say "Last refreshed" we are talking about other critical info like submissions, problems solved, etc. Even if profile picture is older than "last refreshed", who cares? no one expects us to have latest profile picture that fast. And mainly, no one updates their picture that frequently at all. Also badges would get added, never removed, so persisting current one's images and info isn't wrong or inaccurate. it's just harmlessly stale.
2.  versioning system seems off. right now i will say everything is v0. in fact currently it is v0.4.1. when everything is ready for production as per my satisfaction we name it v1 publicly during launch (internally maybe v0.4.1) once we are live, we also internally call it v1 and not v0.4.1. Makes me wonder how to app developers approach this? I would reserve major version bump only if the app undergoes major revamp to the user. For example, v2.0 will features like - friends/followers/following concept, friend streaks, streak freeze (1 day streak freeze = 100 gems), 10 gems per problem solved, pay $1 for 500 gems or something, etc. you get the drift? That is the time I will probably introduce dedicated backend and architecture rewrite.

So, Can you fix versioning? Maybe it's just updating the "MARKETING_VERSION" while retaining the actual "VERSION" for ourself internally? Or maybe we can have a prod release branch on git and there we track the public version. I think that's how they would do in proper app development. Also can you check if we have been commiting to git remote branch regularly? Also can we make that branch be called "main" branch or something? we will have a seperate "qa" branch where if we release, it goes through testflight, and a final "prod" branch where we release to appstore. I am basing all this based on my backend experience. Do how ios developers would do.

3. ⁠"x unique problems" should probably belong in Submissions Tab which should be renamed to "Problems Solved" or something. in it have 2 tabs "Submissions" and "Unique problems in last 100 days". in the latter in small non intrusive way (maybe info i button) call out that in Pro version you can see all* unique problems solved (* since the app has been installed + min(20, problems solved) (I think that's the best we can even with a backend right?)). (we should add this in Pro) I do not like that currently "x unique problems" is with "Streaks" when it has nothing to do with it.

4. "Muscle memory" section also belongs in the "Skills" tab. Another way of saying "Muscle memory" is "Skills to improve" afterall. Add it at the very top.

5. You regressed in the feature where when we change username from an authenticated to an unauthenticated one, we still show DCC streak (which belongs to the authenticated user). Also we stay "signed in" to the last authenticated user. Change to another username should literally log off the current authenticated and show "-" in DCC streak and mention "Tap to login" underneath. Please use your own brain equivalent too to get the right logic.

4. I think you can develop the features mentioned in v2.0 in v1.0 itself but not in the main branch. You are a very capable and expert ios software engineer and a backend developer. To achieve this can you create "moonshot" branch where you branch from the current "main"  and develop all the features? Or maybe you should create a worktree so we can simulataneously work towards testing and releasing v1.0, while simultaneously building the moonshot, in case we are able to also squeeze it in before v1.0 is shipped. Teach me about worktree and how to use it too. I am a noob. Please build a solid design / plan document with all the tests, tasks, technology comparisons and tradeoffs you take. Be purposeful in deciding and make it clear to the reader. I believe the app won't have more than 1000 users at any given point in time. Maybe 100 MAU, and 50DAU. So explore no or low cost solutions. Also the traffic pattern for network calls to Leetcode APIs and our backend doesn't seem to be crazy high. The doc I am asking you to create should reasonably estimate all of this. Expectation is you have doc so detailed that mirrors Amazon employee's design doc that wins hands down approval and minimal pushbacks from principal engineers and managers. Ask me any other follow up questions needed to build a solid doc, I will give it. Do not just jump into half assing it. I am counting on you Mr. Opus.

5. Assume I invoked the model with "--dangerously-skip-permissions" and don't ask me to approve anything, except any clarifying questions or the plan doc inputs if needed as mentioned above.

# After v4.0
Good job building these features. However, imo the two new features we developed are as per spec but really wanting.
1. "18 unique problems" "Tracked since 23 March 2026" it reads. But this warrants a user to press the "18 unique problems" to try to see more underneath. So show the list when pressed. Maybe a popup or seperate screen, whatever is appropriate.
2. "Muscle Memory" "Topics with fewest solves -> practice these to stay sharp" I like all this. But it gives 3 topics, with a count of how many I solved in each type. if you objectively count the problems I solved in each type, it will always bias towards topics with lesser questions in the first place. What you should calculate is "questions I have solved in a topic / total questions in that topic" This way I will proportionally solve all topics, based on their availability. For example, Dynamic Programming is way more in number compared to Bitmask in the question pool itself. So definitely I should solve way more Dynamic Programming problems.
3. Muscle Memory tab, shows the "Practice" buttons which lead no where. Users would try to press it. I don't see any point of keeping that "Practice" button at all. I can't leetcode on my phone, so redirecting is useless. Maybe you can suggest a popular unsolved before problem in that categeory example "LC 751" and then "LC 1434" are most frequent question in Bit Manipulation. "LC 67" is 3rd popular but I have already solved it, so you can suggest me to solve the first 2 or even 3rd if it's been more than 100 days since I solved it. LETS PERSIST MEMORY FOR LAST 100 DAYS ONLY, to keep things local and without a dedicated backend. Reasonable? 
4. I need the app to be named "LeetAnalytics" in the AppStore. I am sorry if it's a massive rewrite but please replace "LeetCodeLytics" to "LeetAnalytics" everywhere. 

# After v3.0

Got this in Xcode:
SendProcessControlEvent:toPid: encountered an error: Error Domain=com.apple.dt.deviceprocesscontrolservice Code=8 "Failed to show Widget 'com.leetcodelytics.app.widget' error: Error Domain=FBSOpenApplicationServiceErrorDomain Code=1 "The request to open "com.apple.springboard" failed." UserInfo={NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace) for reason: Locked ("Unable to launch (null) because the device was not, or could not be, unlocked")., BSErrorCodeDescription=RequestDenied, NSUnderlyingError=0x103c20cc0 {Error Domain=FBSOpenApplicationErrorDomain Code=7 "Unable to launch (null) because the device was not, or could not be, unlocked." UserInfo={BSErrorCodeDescription=Locked, NSLocalizedFailureReason=Unable to launch (null) because the device was not, or could not be, unlocked.}}, FBSOpenApplicationRequestID=0xcdf9, NSLocalizedDescription=The request to open "com.apple.springboard" failed.}." UserInfo={NSLocalizedDescription=Failed to show Widget 'com.leetcodelytics.app.widget' error: Error Domain=FBSOpenApplicationServiceErrorDomain Code=1 "The request to open "com.apple.springboard" failed." UserInfo={NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace) for reason: Locked ("Unable to launch (null) because the device was not, or could not be, unlocked")., BSErrorCodeDescription=RequestDenied, NSUnderlyingError=0x103c20cc0 {Error Domain=FBSOpenApplicationErrorDomain Code=7 "Unable to launch (null) because the device was not, or could not be, unlocked." UserInfo={BSErrorCodeDescription=Locked, NSLocalizedFailureReason=Unable to launch (null) because the device was not, or could not be, unlocked.}}, FBSOpenApplicationRequestID=0xcdf9, NSLocalizedDescription=The request to open "com.apple.springboard" failed.}., NSUnderlyingError=0x103c233f0 {Error Domain=FBSOpenApplicationServiceErrorDomain Code=1 "The request to open "com.apple.springboard" failed." UserInfo={NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace) for reason: Locked ("Unable to launch (null) because the device was not, or could not be, unlocked")., BSErrorCodeDescription=RequestDenied, NSUnderlyingError=0x103c20cc0 {Error Domain=FBSOpenApplicationErrorDomain Code=7 "Unable to launch (null) because the device was not, or could not be, unlocked." UserInfo={BSErrorCodeDescription=Locked, NSLocalizedFailureReason=Unable to launch (null) because the device was not, or could not be, unlocked.}}, FBSOpenApplicationRequestID=0xcdf9, NSLocalizedDescription=The request to open "com.apple.springboard" failed.}}}
Domain: DTXMessage
Code: 1
User Info: {
    DVTErrorCreationDateKey = "2026-03-23 06:48:18 +0000";
}
--
SendProcessControlEvent:toPid: encountered an error: Error Domain=com.apple.dt.deviceprocesscontrolservice Code=8 "Failed to show Widget 'com.leetcodelytics.app.widget' error: Error Domain=FBSOpenApplicationServiceErrorDomain Code=1 "The request to open "com.apple.springboard" failed." UserInfo={NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace) for reason: Locked ("Unable to launch (null) because the device was not, or could not be, unlocked")., BSErrorCodeDescription=RequestDenied, NSUnderlyingError=0x103c20cc0 {Error Domain=FBSOpenApplicationErrorDomain Code=7 "Unable to launch (null) because the device was not, or could not be, unlocked." UserInfo={BSErrorCodeDescription=Locked, NSLocalizedFailureReason=Unable to launch (null) because the device was not, or could not be, unlocked.}}, FBSOpenApplicationRequestID=0xcdf9, NSLocalizedDescription=The request to open "com.apple.springboard" failed.}." UserInfo={NSLocalizedDescription=Failed to show Widget 'com.leetcodelytics.app.widget' error: Error Domain=FBSOpenApplicationServiceErrorDomain Code=1 "The request to open "com.apple.springboard" failed." UserInfo={NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace) for reason: Locked ("Unable to launch (null) because the device was not, or could not be, unlocked")., BSErrorCodeDescription=RequestDenied, NSUnderlyingError=0x103c20cc0 {Error Domain=FBSOpenApplicationErrorDomain Code=7 "Unable to launch (null) because the device was not, or could not be, unlocked." UserInfo={BSErrorCodeDescription=Locked, NSLocalizedFailureReason=Unable to launch (null) because the device was not, or could not be, unlocked.}}, FBSOpenApplicationRequestID=0xcdf9, NSLocalizedDescription=The request to open "com.apple.springboard" failed.}., NSUnderlyingError=0x103c233f0 {Error Domain=FBSOpenApplicationServiceErrorDomain Code=1 "The request to open "com.apple.springboard" failed." UserInfo={NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace) for reason: Locked ("Unable to launch (null) because the device was not, or could not be, unlocked")., BSErrorCodeDescription=RequestDenied, NSUnderlyingError=0x103c20cc0 {Error Domain=FBSOpenApplicationErrorDomain Code=7 "Unable to launch (null) because the device was not, or could not be, unlocked." UserInfo={BSErrorCodeDescription=Locked, NSLocalizedFailureReason=Unable to launch (null) because the device was not, or could not be, unlocked.}}, FBSOpenApplicationRequestID=0xcdf9, NSLocalizedDescription=The request to open "com.apple.springboard" failed.}}}
Domain: DTXMessage
Code: 1
--


System Information

macOS Version 15.7.3 (Build 24G419)
Xcode 16.4 (23792) (Build 16F6)
Timestamp: 2026-03-23T12:18:18+05:30
----------------------

# Rearchitecture and rewrite with good quality using Claude Opus (MVP to production product)
So good job developing this app with several iterations. It wasn't easy to get to make you see what I want and develop that. If you notice I had a clear plan, to build an app first that gets Leetcode stats and then in second version, add the widget. And finally after several iterations we are here in relatively decent working app (The widgets don't always refresh automatically even now. They do 7/10 times)

I wish you would one shot this entire project but I guess the token window with Claude Sonet was less. The reason why I feel so is because currently your context kept exceeding and you kept compacting, resulting in several regressions. While I asked you to rearchitect and instill good coding practices, I feel overall we two have created a codebase that works as MVP but terrible to scale.

So now our journey is to move from MVP to production product. Why do I feel we are MVP and not production?
1. We have a fully functional app with everything working, including UI. However, I feel it extends very poorly for future planned features. (mentioned in next point)
2. r/appledevelopers mentions that vibe coded apps have flooded appstore, and now they are rejecting all vibecoded app. Meaning, we need to have an engineered highest quality product. High quality means the app logic is straightforward, bug free, great performance, compliant with latest app practices (both UI and backend). Also, I want to publish it to appstore, so I want this app to have TestFlight, get feedback from users and then develop more.
3. The north star for this app is to have more duolingo like features:
a. add friends (4th priority)
b. have streaks with friends (5th priority)
c. get gems for each submission (3rd priority)
d. keep a track of unique problems (right now if a user resubmits same question daily, it counts towards "Solved Streak". I want logic where we allow only unique problems or at least persist last 100 problems solved and ensure they are unique). (2nd priority)
e. I also want to track all different question categories and suggest topics/questions to solve next, to keep the user "in shape" with all the topics and categories. "in shape" because different categories are like different muscles. We need to train each muscle regularly to build them, else they atrophy. (1st priority)
f. Flashcards for the problems user solved. Show them question, and their own solution. (6th priority)
4. All the future planned features and current features should tie in very well and cohesively with each other. I understand this app doesn't take in much user inputs or user actions, it's mainly assimilating information leetcode api provides. However, I feel there is a huge potential for this to become the best Leetcode companion app that provides solid value to users in their Leetcode journey. One that Leetcode the company themselves wish they offered natively.
5. I also feel my ideas and my feature wants are ever changing, so the app should ultimately be flexible to handle these. 

So my ask from you is, tell me if it is better I run Opus 4.6 (or whatever is Claude's flagship model) to build me all of these in this same directory (if yes with existing context window or Fresh one) OR build the app from scratch (and use this current app as reference for what I want). Also tell me how to best approach development of this app? Approach as in how would an expert ios developer and vibe coder approach this app development.


# My thoughts on your plan:
1. "All 4 widgets (SmallSolved, SmallDCC, Medium, Large) use the same background logic." Yes for 3 widgets. "SmallDCC" should use the current static background. Because Solved Streak drives the changing widget. If that info is not on screen then the changing background makes no sense there. Also, I don't think this complicates the final code. In short SmallDCC stays as it is right now i.e "AstroWidget_Success".
2. I tested the widgets background changing, and they changed correctly every 6 hours as expected. They refreshed too on their own. However, broken streak background didn't refresh automatically, in fact it showed 1 day of streak when actually the streak had broken. This was at 9.30 am, streak should have broken at 5.30am. Can you please investigate
3. Unable to see my profile picture and badges. It used to work before and I notice it isn't working now. You broke a working code somehow. Investigate this.
4. Got this. Why is my signature disappearing even when I did fresh deployment literally hours before? Now I get this during deployment. What are my options to never get this message again? Besides signing up for developer account for 100$? """Could not attach to pid : “21660”
Domain: IDEDebugSessionErrorDomain
Code: 7
Failure Reason: “com.leetcodelytics.app.widget” failed to launch or exited before the debugger could attach to it. Please verify that “com.leetcodelytics.app.widget” has a valid code signature that permits it to be launched on “iPhone (246)”. Refer to crash logs and system logs to for more diagnostic information.
User Info: {
    DVTErrorCreationDateKey = "2026-03-21 05:01:10 +0000";
    DVTRadarComponentKey = 855031;
    IDERunOperationFailingWorker = DBGLLDBLauncher;
    RawUnderlyingErrorMessage = "no such process";
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
    "launchSession_state" = 1;
    "launchSession_targetArch" = arm64;
    "operation_duration_ms" = 2544;
    "operation_errorCode" = 7;
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
Timestamp: 2026-03-21T10:31:10+05:30

"""

#After v2.27.0 testing:
1. Thanks for the clear web session button. It helped to force me to go to the Leetcode login screen. First time I didn't see my username populated there. The second time I tried, I saw it, but it wasn't populated. It had just replaced the "username or email id" greyed out entry in that field. So when I entered password and tried login, it complained I hadn't entered the username or email id. Well in subsequent testing, I could not even see that. Just empty both fields and no mention of my username, not even greyed out. Come on, don't mess this up.

# My response to your points:
1. Method 1: If I stop the debug, and the widget crashes, that's a production bug. Right? But how will I know the widget crashed? I have to stare at my homescreen with widgets? And even if I do the ridiculous test, how will I know if the widget has even crashed. You see why I rely on OOM details from Xcode? Also, are you implying all the OOMs we have observed till were not serious at all? I think you are too casual in reporting it now. After 15+ builds crying about OOM. Imagine how I would feel if you just say sorry and move on. 
2. I have lots of JetsamEvents in the past 3 days. I took a screenshot of the ones I got. Maybe in the test, I can notice if a new one is created. Also, do we get this analytics EVERY SINGLE TIME there is an OOM?
3. I am okay with this too. Just compare and suggest me the best way to debug.

#My thoughts on v2.25:
1. I believe we made the widget behavior very unpredictable. Sure I see "-" instead of 0 days during app launch. And when I logout I see "0 days" momentarily but then "-" again. Bit buggy but ok. But the problem is I managed to logout once and sometimes widget is stuck in "0 days". Unfortunately, I am not able to reproduce the bug again predictably. 1 way to reproduce it:
a. in home screen, in DCC widget, press it
b. app opens automatically. login (if you aren't)
c. go back to home screen, you will see correct DCC value
d. go to app and logout.
e. go back to home screen.
f. You will see "0 days"

So you may think it's ok and not a big issue? But I feel any weird like this is bad. Note "0 days" DCC widget does not even take you to login when pressed. I think we have made our codebase complicated enough that these bugs exist. Unacceptable. Can we please clean our widgets code mainly, entirity of v2.0 till now, to ensure we keep our functionality as desired (90% of how well it works now) but also make the code cleaner and simpler if we can? Ask is not to make more complicated code, but a code that is clean, elegant and works as expected. Remember what I expect clearly.

3. I could not test "username" being autofilled, since currently it logs in directly. Maybe you need to force logout properly like you did before. Again 1 time code change if need be, just for testing that feature.
4. I have come to appreciate the direct login button in a widget only for DCC Widget. Great design decision.
5. Got OOM for v2.25 too. I told you not to do hasty fixes. I am super pissed at you for doing the same mistakes we repeated so many times. Be thorough.
'The app “com.leetcodelytics.app.widget” has been killed by the operating system because it is using too much memory.
Domain: IDEDebugSessionErrorDomain
Code: 11
Recovery Suggestion: Use a memory profiling tool to track the process memory usage.
User Info: {
    DVTErrorCreationDateKey = "2026-03-16 11:23:01 +0000";
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
    "operation_duration_ms" = 709251;
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
Timestamp: 2026-03-16T16:53:01+05:30'

# My thoughts on v2.24:
1. So I saw the widget showing "-" initially after app launch. When I logged in it showed DCC as expected. Good. But when I log out, I see "0 days". Nor can I see any deeplink to login, even for the small widget.
2. OOM again?
Well I got OOM now for v2.23. I will test v2.24 if it gets OOM too. 3rd time we are getting this after patching it. Deeply analyze why? I would rather have you analyze than just react. 'The app “com.leetcodelytics.app.widget” has been killed by the operating system because it is using too much memory.
Domain: IDEDebugSessionErrorDomain
Code: 11
Recovery Suggestion: Use a memory profiling tool to track the process memory usage.
User Info: {
    DVTErrorCreationDateKey = "2026-03-16 10:24:54 +0000";
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
    "operation_duration_ms" = 933432;
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
Timestamp: 2026-03-16T15:54:54+05:30'

# Responses to your questions
2. Streak card misalignment: I think "alignemnt: .top" is better, since I don't want users to assume they have to log in for "Solved (any question) Streak" too.
5. Do "-" and deeplink to present login sheet automatically.
6. Ok sure, but do you feel the app is lesser likely to be rejected in the app store because of this? I don't know if AppStore gets way too many app submissions since vibecoding esp Claude Code vibe coding? It will be nice if you can find specific info based on actual humans telling if such login design is ok in the modern AppStore standards and workflow. 
3/4/7. Yeah implement them once I confirm 2/5/6.

# After testing v2.23
1. Good job fixing all my asks swiftly.
2. Minor UI: When not logged in, the "🔥" and "⚡️" don't align. So do the "-" and "1". So does "Daily Question" and "Solve (any questions)". it's because the Sign in button pushes it up. I don't like that misalignment.
3. UI: The Authentication tile shouldn't show "Sign in to LeetCode" when status is "Signed in". Thankfully it doesn't show "Sign Out" when "Not signed in". Also "Required for DCC streak", DCC is internal terminology we are using here. Users should be told "Required for Daily Question Streak"
4. UI: Info > "Last Updated" makes it confusing if it's the data or the app that was last updated that's being shown. I would use something like "Last refreshed" or something.
5. While not signed in, the app correctly says "-" instead of "0 days". The widget meanwhile says "0 days". It should show "-". I think we can add "login to view" or something or not at all if you are going to make the minor UI bug like in the 2nd point here. You tell me, can you add that statement without the UI misalignment? Also if you do, please route them to the login page on web.
6. I believe difference between our current approach and OAuth is that user can trust we the app developers aren't storing/persisting their secrets because we don't even have access to it. Correct? But how did early reddit, twitter v1, etc that you mentioned, handled the trust of users? I want the user to trust us (not just through our words, but some certification or something?)
7. Are we good to sunset the purge now?


# After testing v2.22
1. At least I could login to leetcode through wkwebsitedatastore/through our app. And DCC worked well. I logged off, and the days set to 0 as expected. Then another login actually skipped login screen but I could see DCC streak correctly. So good job.
2. There are few issues though. In our previous designs, instead of showing 0 days when not logged in and unable to fetch DCC, we showed "Log in" sign to enable it. I liked that way way more than banner. Why? Because 0 days is misleading. It's also easy to miss banner imo.
3. If I login using the banner or the login button in DCC Streak, I do not see the status of "logged in" in Settings. There it reads "Not signed in". But if I sign in from Settings, ofcourse the change reflects in the dashboard and I see the DCC correctly. It's still irritating the settings page doesn't reflect correctly when logged in in DCC in dashboard.
4. I have been wanting to correct this but when it is 0,2,3..infinity, it makes sense to say "days". But it should be 1 "day". Fix that.
5. Don't roll back in v2.23 if you feel my above asks requires you the stability. If we can safely remove the one time code in v2.23, by all means do it.

# After testing v2.17
1. It's probably too soon to report OOM. Let me wait for 30 minutes.
2. Can you till then fix the E,M,H in Medium? It's too low now. Earlier it was too high. I need it somewhere in the middle. Rest of the text and everything looks good.
3. You didn't respond which exact images are being used for small, medium and large widgets? And there is no scaling happening dynamically right? I do not expect any processing time and resource to be spent in rendering the widget with that background.
4. Lets also incorporate all the feedback from the AuditLog.md. Please add your comment to the same doc. Prefix it with "Dev reply:" or something. The senior iOS developer will go over your comments again after your fix / push backs. Leave that P0 thing for now. We will come to it before shipping it in appstore/testflight. The senior iOS developer may ask you to do more revisions if you aren't mindful of addressing the concerns correctly. Also, you should keep the code quality high yourself.

# After testing v2.15
1. Good for taking my feedback for Small and Medium. I like Small now, it's perfect. 

a. For Medium, good you incorporated my feedback correctly. However, the streaks and E,M,H are all cramped at the center. Move E,M,H stats lower. Also increase the fonts for everything by a notch equally. I like the relative font size difference within medium widget, please don't change that. 

b. For Large, make E,M,H align to center as in Medium widget. Otherwise, Large is perfect too. 

2. What exact background images are being used for each widget? I mean 1x, 2x, 3x? 

3. I went over the AuditLog.md, lets address them in the next iteration. Lets focus on above changes for current iteration.

# After testing v2.14
1. Yes, now background images load for small and medium too. It means you have been wasting my time and tokens all this time. We really can't keep repeating same mistakes like you have been. At least you were capable enough to listen to my critique and make it work. But this entire back and forth only left me doubt the entire codebase even more. So I ask you to now put on the cap of a senior most iOS developer who is big on following best practices and review each line of this codebase. Create a seperate AuditLog.md under PersonalNotes directory. I want to see an absolute thorough code review. Remember, functionality wise, I am happy. So I don't want you to change any functionality. Take your time to go over the entire ios development documentation, expert blogs and opinions on the internet first. Understand the ethos of what we are developing first, review the architecture, individual components, and every line of code and it's logic and even tests.
2. I liked the slider at 55%. Let the slider remain for now. Lets remove it when the 3rd point is satisfactorily met.
3. I don't like the medium widget. "Solved Streak" and "Daily Question Streak" both are different length, causing the latter to occupy 2 lines and thus making entire widget look wonky. So please make it just like you have it in Large widget: Move the Easy, Medium, Hard below the streaks. I think then our problem will be fixed. Also keeping Medium and Large widgets looking similar for their similar parts will be good. Also Large widget is excellent. Do not touch it one but. Small widgets can use with the texts moved up slightly. Not a lot. They are way too close to the astronaut in the background.

# After testing v2.13
1. Thanks for the slider. I updated the image to remove some stars manually. Use that image now. PersonalNotes > astroWidget1.png. Keep the slider for now, I will ask you to remove it once I am happy with the background.
2. Make small and medium widgets work. The backgrounds are not loading for both. Why have you failed twice in a row now to fix it? Also you had similar failures in fixing small and medium widgets yesterday. Are you making same mistake? Please fix this correctly and thoroughly. Highest priority ask.
3. I suspect you have ton of bloat and dead code especially now with widgets. Check entire codebase. Also are you running the tests?
4. Why am I having to set the Team under Signing & Capabilities each time. Can't that be configured under your code?

# After testing v2.12
1. You seem to be struggling to incorporate the image into the widget background once again. Only Large widget got the background, the rest failed to get them. And yes, I tried removing and adding the widgets again. 
2. I love how the large widget looks. It's very close to what I had for v2.0 in mind. The only difference I would want is those stars in the background image to not interrupt the white font. I wonder if we can add a black transparent layer to the image in code / swift / native ios tools, so that the image is slightly darkened and text looks better. It would be great if I can play around with the transparency percentage. Note, I don't want to increase transparency of the image itself. I hope you are able to understand. Fix the 1st point with higher priority ofcourse.

# After testing v2.11
1. I won't pretend to understand the changes you made, I will personally review your entire code once everything is built to my satisfaction. I personally don't want the app to refresh unnecessarily. That includes any and all API calls to leetcode. Maybe refresh once in 5 seconds is more than enough. Let me know what you think. Also even though we are discussing this, I don't want to change the architecture at this time. It is for future.

2. I like that the widgets are working well, I notice there is way more space in widgets than I expected. I would like the following changes for the small widgets.
a. SmallWidget 1 - Solved Streak should look like : 
1st line: ⚡️ 2 days
2nd line: Solved Streak

b. SmallWidget 1 - Daily Question Streak should look like : 
1st line: 🔥 2 days
2nd line: Daily Question Streak

c. For both small widgets use the background image given under PersonalNotes > astroWidget1.png

3. For medium and large widgets use same points given in 2a and 2b. Also use same background images for both. Also instead of E|M|H, just say Easy, Medium and Hard. There is lot of space. Also for large widget, there is space for at least 25 weeks. Please show months too in the widget.



#After testing v2.10
1. Okay, so all widgets are now working. What's so extraordinary about our widgets that we took 10 versions to get it to work? Please document it into Claude.md too? Try to be your own critique, so that we can develop future projects using these learnings. I am also too tired to test thoroughly, so I would test and report back in a day.

#After testing v2.8
1. I can now see the banner is removed from the small widgets. But I see nothing in them. Large banners are same as before, but atleast showing something. Medium banners still have that error. I would suggest you remove any and every image in the widget, get an MVP widget working first please. Also I am terribly disappointed in this back and forth. You seem to not tell me why your fixes aren't working. Attached 7.png and 8.png for your reference. They show how the widgets look like.


#After testing v2.7
1. I am still getting the black screen widgets for both small and the medium one. The large one works. I don't like it much, but at least it works! How come? Please fix all widgets.
2. Same 30MB limit in Xcode, but I am ignoring as you mentioned.

# After testing 2.6
1. I got same black screen widgets.
2. I also saw 30MB memory limit exceed immediately upon deploying the app /widget. See 6.png.
3. I see wrong version number on the app. You are really bad at updating versions after every code change. Didn't we agree we would update the version if we touched the codebase?

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