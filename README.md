### Getting Started

#### Installation

The script is self contained, so you can just [download
it](https://raw.githubusercontent.com/mkropat/Invoke-RsCloudOfficeRequest/master/Invoke-RsCloudOfficeRequest.ps1).

If you are already in PowerShell, simply download it to your working directory:

    Invoke-WebRequest https://raw.githubusercontent.com/mkropat/Invoke-RsCloudOfficeRequest/master/Invoke-RsCloudOfficeRequest.ps1 -OutFile Invoke-RsCloudOfficeRequest.ps1

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
left on your computer.

### Example Usage

#### Admins

__Note:__ In all the example URLs, replace `jane.doe` with the name of the
admin you want to act on.

##### List All Admins

```powershell
.\Invoke-RsCloudOfficeRequest.ps1 /v1/customers/me/admins -UnpaginateProperty admins |
    Format-Table
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
    Format-Table
```

----

#### Exchange Mailboxes

__Note__: In all the example URLs, replace `example.com` with your domain and
replace `jane.doe` with the name of the mailbox to act on.

##### List All Mailboxes

```powershell
.\Invoke-RsCloudOfficeRequest.ps1 /v1/customers/me/domains/example.com/ex/mailboxes `
    -UnpaginateProperty mailboxes | Format-Table
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
    -UnpaginateProperty rsMailboxes | Format-Table
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
