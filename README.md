# Daily Jobs to Html - powershell

This script uses the OpCon APIs to fetch Schedules and Jobs from the Daily plans, saves it on a static html page and display it in the default browser.


# Disclaimer
No Support and No Warranty are provided by SMA Technologies for this project and related material. The use of this project's files is on your own risk.

SMA Technologies assumes no liability for damage caused by the usage of any of the files offered here via this Github repository.

# Prerequisites

* Powershell v5.1
* OpCon +18.3


# Instructions

  * <b>OpScheduleDate</b> - Schedule Date filter -optional parameter (omitting this can result in huge amount of data to be retrieved) 
  * <b>OpJobStatus</b> - Job Status filter -optional parameter
  * <b>OpConUser</b> - OpCon User ID
  * <b>OpConPassword</b> - OpCon Password
  * <b>ServerUrl</b> - OpCon server url
  
Example:
```
.\DailyJobsToHtml.ps1 -ScheduleDate "2021-03-17" -OpJobStatus "Failed" -OpConUser ocadm -OpConPassword <password> -ServerUrl https://192.168.2.30:443
```  

<b>The HtmlTemplate file:</b>
  * Is expected in the same folder of the powershell script
  * Can be personalized for different layout. In case of personalization please take care to preserve the 'ROWS_PLACE_HOLDER', it is dynamically replaced at runtime by the actual rows data.


# License
Copyright 2019 SMA Technologies

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

# Contributing
We love contributions, please read our [Contribution Guide](CONTRIBUTING.md) to get started!

# Code of Conduct
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](code-of-conduct.md)
SMA Technologies has adopted the [Contributor Covenant](CODE_OF_CONDUCT.md) as its Code of Conduct, and we expect project participants to adhere to it. Please read the [full text](CODE_OF_CONDUCT.md) so that you can understand what actions will and will not be tolerated.
