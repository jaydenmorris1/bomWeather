Option Explicit

Dim wInput, fs, f, shell, wAppDir, wbomDetails
Dim ForecastCity, ObservationType, observation_url, observation_station, forecast_url, SunriseLocation, State, TimeZone, RadarLocation
Const ApplicationFolder = "Rainmeter-kanine"

set shell = WScript.CreateObject( "WScript.Shell" )
wAppDir = (shell.ExpandEnvironmentStrings("%APPDATA%")) & "\"& ApplicationFolder
Set fs = CreateObject ("Scripting.FileSystemObject")

If NOT fs.FolderExists(wAppDir) Then
 fs.CreateFolder(wAppDir)
End If

ForecastCity = ""
ObservationType = "Detail"
observation_url = ""
observation_station  = ""
forecast_url = ""
SunriseLocation = ""
State = ""
TimeZone = ""

If fs.FileExists(wAppDir & "\bomWeather-Configuration.txt") Then
  Set f = fs.OpenTextFile(wAppDir & "\bomWeather-Configuration.txt")
  wbomDetails = f.readall
  f.close
  
  ForecastCity = parse_item (wbomDetails, "ForecastCity =", "<<<")
  forecast_url = parse_item (wbomDetails, "forecast_url =", "<<<")
  observation_url = parse_item (wbomDetails, "observation_url =", "<<<")
  observation_station = parse_item (wbomDetails, "observation_station =", "<<<")
  ObservationType = parse_item (wbomDetails, "ObservationType =", "<<<")
  SunriseLocation = parse_item (wbomDetails, "SunriseLocation =", "<<<")
  State = parse_item (wbomDetails, "State =", "<<<")
  TimeZone = parse_item (wbomDetails, "TimeZone =", "<<<")
  
End If

ForecastCity = InputBox("Please enter your city forecast location" & vbCRLF & _
                     "(Melbourne, Sydney, Perth for now)", "kanine bomWeather Setup", ForecastCity)

If ForecastCity = "" Then wScript.Quit

Select Case LCase(ForecastCity)

  Case "melbourne"
    ForecastCity = "Melbourne"
    forecast_url = "http://www.bom.gov.au/vic/forecasts/melbourne.shtml"
    ObservationType = "Detail"
    observation_url = "http://www.bom.gov.au/vic/observations/melbourne.shtml"
    observation_station = "Melbourne"
    ObservationType = "Detail"
    SunriseLocation = "Melbourne"
    State = "VIC"
    TimeZone = "EST"
    RadarLocation = "IDR023"

 Case "sydney"
    ForecastCity = "Sydney"
    forecast_url = "http://www.bom.gov.au/nsw/forecasts/sydney.shtml"
    ObservationType = "Detail"
    observation_url = "http://www.bom.gov.au/nsw/observations/sydney.shtml"
    observation_station = "Sydney Airport"
    ObservationType = "Detail"
    SunriseLocation = "Sydney"
    State = "NSW"
    TimeZone = "EST"
    RadarLocation = "IDR713"

  Case "perth"
    ForecastCity = "Melbourne"
    forecast_url = "http://www.bom.gov.au/wa/forecasts/perth.shtml"
    ObservationType = "Detail"
    observation_url = "http://www.bom.gov.au/wa/observations/perth.shtml"
    observation_station = "Perth"
    ObservationType = "Detail"
    SunriseLocation = "PERTH"
    State = "WA"
    TimeZone = "EDT"
    RadarLocation = "IDR703"

End Select
                     
forecast_url = InputBox("Please review the chosen Forecast URL" & vbCRLF & _
                     "(cut and paste it to your browser)", "kanine bomWeather Setup", forecast_url)
                    
If forecast_url = "" Then wScript.Quit

observation_url = InputBox("Please review the chosen Observation URL" & vbCRLF & _
                     "(cut and paste it to your browser)", "kanine bomWeather Setup", observation_url)
                    
If observation_url = "" Then wScript.Quit


observation_station = InputBox("Please review the chosen Observation Station" & vbCRLF & _
                     "(pick one from the results of the Observation URL)", "kanine bomWeather Setup", observation_station)
                    
If observation_station = "" Then wScript.Quit

SunriseLocation = InputBox("Please review the Sunrise Location" & vbCRLF & _
                     "(can be verified at www.ga.gov.au/geodesy/astro/sunrise.jsp)", "kanine bomWeather Setup", SunriseLocation)
                    
If SunriseLocation = "" Then wScript.Quit

State = UCase(InputBox("Please review the chosen State" & vbCRLF & _
                     "(VIC, NSW, WA etc)", "kanine bomWeather Setup", State))
                    
If State = "" Then wScript.Quit

TimeZone = InputBox("Please review the chosen Timezone" & vbCRLF & _
                     "(eg EST)", "kanine bomWeather Setup", TimeZone)
                    
If TimeZone = "" Then wScript.Quit


Set f = fs.CreateTextFile(wAppDir & "\bomWeather-Configuration.txt", True)
    
f.writeline "ForecastCity = " & ForecastCity  & " <<<"
f.writeline "forecast_url = " & forecast_url & " <<<"
f.writeline "ObservationType = " & ObservationType & " <<<"
f.writeline "observation_url = " & observation_url & " <<<"
f.writeline "observation_station = " & observation_station & " <<<"
f.writeline "ObservationType = " & ObservationType & " <<<"
f.writeline "SunriseLocation = " & SunriseLocation & " <<<"
f.writeline "State = " & State & " <<<"
f.writeline "TimeZone = " & TimeZone & " <<<"
f.writeline "RadarLocation = " & RadarLocation & " <<<"
f.close

Private Function parse_item (ByRef contents, start_tag, end_tag)

  Dim position, item
	
  position = InStr (1, contents, start_tag, vbTextCompare)
  
  If position > 0 Then
  ' Trim the html information.
    contents = mid (contents, position + len (start_tag))
    position = InStr (1, contents, end_tag, vbTextCompare)
		
    If position > 0 Then
      item = mid (contents, 1, position - 1)
    Else
      Item = ""
    End If
  Else
    item = ""
  End If

  parse_item = Trim(Item)

End Function
