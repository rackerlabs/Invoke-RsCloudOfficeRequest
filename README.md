A PowerShell client for the [Rackspace Cloud
Office](http://www.rackspace.com/en-us/cloud-office) API.  See [the API
documentation](http://api-wiki.apps.rackspace.com/api-wiki/index.php/Main_Page)
for full details on the calls you can make.

#### Syntax

Set up config values:

    Invoke-RsCloudOfficeRequest.ps1 [[-ConfgFile] <String>] -SaveConfig [[-UserKey] <String>] [[-SecretKey] <String>] [[-BaseUrl] <String>]

Making a request:

    $bodyData | Invoke-RsCloudOfficeRequest.ps1 [[-Method] <String>] [-Path] <String> [[-UnpaginateProperty] <String>] [<CommonParameters>]

### Getting Started

#### Pre-requisites

- PowerShell 3.0 or newer ([download](http://www.microsoft.com/en-us/download/details.aspx?id=40855))

(Already comes with Windows 8, Server 2008 and newer)

#### Installation

The script is self contained, so you can just [download
it](https://raw.githubusercontent.com/mkropat/Invoke-RsCloudOfficeRequest/master/Invoke-RsCloudOfficeRequest.ps1).
Depending on the [PowerShell execution
policy](https://technet.microsoft.com/en-us/library/Ee176961.aspx), you
may need to unblock the script before it will run:

    Unblock-File Invoke-RsCloudOfficeRequest.ps1 # restart your session after this

#### API Keys

In order to make any API calls, you will need API keys.  If you need to
generate new ones, log in to the Cloud Office Control Panel, then go to the
[API keys page](https://cp.rackspace.com/MyAccount/Administrators/ApiKeys).

![API Keys screenshot](https://i.imgur.com/IigeLm2.png)

*Screenshot of the API keys page*

For convenience, __you can save your API keys to a config file__ so that you
don't have to pass them every time:

    .\Invoke-RsCloudOfficeRequest.ps1 -SaveConfig -UserKey pugSoulpxYmQDQiY6f1j -SecretKey bI4+E0cV93qigYKuC+sRAJkqyMlc6CThXr9CDXjc

(Replace the example keys with your actual keys)

When you are finished interacting with the API, you may optionally delete the
config file at `%LOCALAPPDATA\RsCloudOfficeApi.config` so that your keys aren't
left on the computer.

### Example Usage

#### Admins

__Note:__ In all the example URLs, replace `jane.doe` with the name of the
admin you want to act on.

##### List All Admins

```powershell
.\Invoke-RsCloudOfficeRequest.ps1 /v1/customers/me/admins -UnpaginateProperty admins |
    Format-Table -AutoSize
```

##### Add An Admin

```powershell
$newAdmin = @{
    type = 'super';
    password = 'Password!1';
    firstName = 'Jane';
    lastName = 'Doe';
    email = 'jane.doe@example.com';
    securityQuestion = 'what is delicious';
    securityAnswer = 'candy';
}
$newAdmin | .\Invoke-RsCloudOfficeRequest.ps1 -Method Post /v1/customers/me/admins/jane.doe
```

##### Get Details On A Specific Admin

```powershell
.\Invoke-RsCloudOfficeRequest.ps1 /v1/customers/me/admins/jane.doe
```

##### Edit An Admin

```powershell
@{ firstName = 'New Name' } |
    .\Invoke-RsCloudOfficeRequest.ps1 -Method Put /v1/customers/me/admins/jane.doe
```

##### Delete An Admin

```powershell
.\Invoke-RsCloudOfficeRequest.ps1 -Method Delete /v1/customers/me/admins/jane.doe
```

----

#### Domains

##### List All Domains

```powershell
.\Invoke-RsCloudOfficeRequest.ps1 /v1/customers/me/domains -UnpaginateProperty domains |
    Format-Table -AutoSize
```

----

#### Exchange Mailboxes

__Note__: In all the example URLs, replace `example.com` with your domain and
replace `jane.doe` with the name of the mailbox to act on.

##### List All Mailboxes

```powershell
.\Invoke-RsCloudOfficeRequest.ps1 /v1/customers/me/domains/example.com/ex/mailboxes `
    -UnpaginateProperty mailboxes | Format-Table -AutoSize
```

##### Add A Mailbox

```powershell
$newMailbox = @{
    displayName = 'Jane Doe';
    password = 'Password!1';
    size = 10*1024;
}
$newMailbox | .\Invoke-RsCloudOfficeRequest.ps1 -Method Post `
    /v1/customers/me/domains/example.com/ex/mailboxes/jane.doe
```

##### Get Details Of A Specific Mailbox

```powershell
.\Invoke-RsCloudOfficeRequest.ps1 /v1/customers/me/domains/example.com/ex/mailboxes/jane.doe
```

##### Edit A Mailbox

```powershell
@{ firstName = 'New Name' } | .\Invoke-RsCloudOfficeRequest.ps1 -Method Put `
    /v1/customers/me/domains/example.com/ex/mailboxes/jane.doe
```

##### Delete A Mailbox

```powershell
.\Invoke-RsCloudOfficeRequest.ps1 -Method Delete `
    /v1/customers/me/domains/example.com/ex/mailboxes/jane.doe
```

----

#### Rackspace Mailboxes

__Note__: In all the example URLs, replace `example.com` with your domain and
replace `jane.doe` with the name of the mailbox to act on.

##### List All Mailboxes

```powershell
.\Invoke-RsCloudOfficeRequest.ps1 /v1/customers/me/domains/example.com/rs/mailboxes `
    -UnpaginateProperty rsMailboxes | Format-Table -AutoSize
```

##### Add A Mailbox

```powershell
$newMailbox = @{
    password = 'Password!1';
    size = 25*1024;
}
$newMailbox | .\Invoke-RsCloudOfficeRequest.ps1 -Method Post `
    /v1/customers/me/domains/example.com/rs/mailboxes/jane.doe
```

##### Get Details Of A Specific Mailbox

```powershell
.\Invoke-RsCloudOfficeRequest.ps1 /v1/customers/me/domains/example.com/rs/mailboxes/jane.doe
```

##### Edit A Mailbox

```powershell
@{ firstName = 'New Name' } | .\Invoke-RsCloudOfficeRequest.ps1 -Method Put `
    /v1/customers/me/domains/example.com/rs/mailboxes/jane.doe
```

##### Delete A Mailbox

```powershell
.\Invoke-RsCloudOfficeRequest.ps1 -Method Delete `
    /v1/customers/me/domains/example.com/rs/mailboxes/jane.doe
```
