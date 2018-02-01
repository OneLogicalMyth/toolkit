Function Get-KBDetails {
param([int]$KBNumber)

   $Data = Invoke-WebRequest "https://support.microsoft.com/app/content/api/content/help/en-us/$KBNumber"
   $Data = $(ConvertFrom-Json $Data.Content).Details`


   $Out = '' | Select-Object Title, Description, URL
   $Out.Title = $Data.title
   $Out.Description = $Data.description
   $Out.URL = "https://support.microsoft.com/en-gb/kb/$($Data.id)"
   $Out
   
}
